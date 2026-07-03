#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: harvest.pl,v 1.32 2005/10/10 16:00:09 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: harvest.pl,v 1.32 2005/10/10 16:00:09 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: harvest.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Front end data preparation for Penryn process migration flow.
Input: 1264 netlist/schematics
Output: 1264 SN and CIF file, 1265 CIF file

This script performs the following tasks on the input fub/cell:

- Search for clean netlist/LNF model from list of UE models:
  - Sets up Merom environment
  - Prep DMS path
  - Netlist (SN from SCH)
  - ISS TRCSTD (LNF)
- Remove bonus/fib/megacontainer from clean LNF and re-verify
- Genesys pre-processing
  - Removal of data not required for migration
  - LNF via marker addition
  - LNF->GDSII Using Genesys
  - Save LNF snapshot
  - ISS TRCSTD (Genesys STM)
- GDSII->CIF
- Layer stripping, via enclosure marking, and text stripping of CIF
- CIF verification
  - Regeneration of text from properties
  - CIF->GDSII
  - ISS TRCSTD (Genesys STM)
- PDSXOR run on Texted GDSII vs original LNF
- Preparation of migration environment/directories
- 1264 CIF -> 1265 CIF/STM conversion
- ISSTRCSTD (1265 STM)

=cut


# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
    if (defined $ENV{'DA_OVR'}) {
    push @INC, $ENV{'DA_OVR'};
  } else {
    push @INC, '/nfs/iil/disks/home10/mroha/pnr/mig', '/usr/users/home2/mroha/pnr/mig';
  }  
}

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';
use DAStdLib;
use MigStdLib;
use PdsStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
                  [-env 'VAR=VALUE'] [-nofub]
                  [-dbb <dbb name>] [-uemodel <model name>]
                  [-only1264] [-skipnetlist] [-ignorecmp]
                  [-textflow] [-nocmpdiodes] [-schonly]
                  [-skipcellfile <skipcell file>]
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input cell name

-env              Set env var at start of execution. Can have more than one -env
                  flag.

-nofub            Skips fub authentication routine and best data search

-skipnetlist      Used only with -nofub. Skips netlisting stage and assumes SN is in
                  \$PDSSN

-skipcellfile     Cell names in this file are added to the default skipcell list

-only1264         Only run 1264 harvest portion of flow

-ignorecmp        Run CMP but do not stop flow on an error. If NOT using -nofub, then
                  first UE model in the model search list with a non-latest cfg will
                  be taken. Latest will be taken if none are found.

-dbb              Override for DBB name. In regular mode, the DBB is the -cell value.
                  With -nofub, the default is 'none'

-uemodel          MODEL to use when running with -nofub switch. Default is 'latest'

-sch              Run the nike netlister to generate sn from sch instead of from cdba
                  (required for ROM fubs).

-nocmpdiodes      Do not compare diodes during cmp runs. (Required for the clfuse* fubs)

-textflow         Run new flow that removes all port layers and keeps only text in its
                  place as a marker

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend
         $EXE_NAME -cell tm0bin00i0 -nofub -only1264 -debug
         $EXE_NAME -cell raramc_subcell -nofub -dbb raramc -uemodel lor2 -verbose
         $EXE_NAME -cell rowbac -nofub -skipnetlist
         $EXE_NAME -cell paaddrreps -dbb pad -skipcellfile $WORK/pad_decaps.list
         $EXE_NAME -cell bbcrd -env 'M3PWR_WIDTH=0.16'

Files that result from this run:

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_cell, $opt_nofub, $opt_debug, $opt_verbose, $opt_help);
our ($opt_dbb, $opt_uemodel, $opt_only1264, $opt_skipnetlist, $opt_ignorecmp, $opt_sch);
our ($opt_nocmpdiodes, $opt_textflow, $opt_skipcellfile, @opt_env);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "env=s@",
			     "nofub",
			     "dbb=s",
			     "uemodel=s",
			     "skipnetlist",
			     "only1264",
			     "sch",
			     "textflow",
			     "nocmpdiodes",
			     "ignorecmp",
			     "skipcellfile=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####


# Capture initial environment variables
our ($HOME, $WORK_AREA_ROOT_DIR, $OVERRIDE_WORK_DIR, $AREA_NAME, $PROCESS_NAME, $LM_LICENSE_FILE);
my @env_list = ('WORK_AREA_ROOT_DIR', 'OVERRIDE_WORK_DIR', 'AREA_NAME', 'PROCESS_NAME', 'LM_LICENSE_FILE');
@env_list = (@env_list, 'HOME');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}

unless ($PROCESS_NAME eq $mig_output_process) {
  die "-F- $EXE_NAME: You must start $EXE_NAME in a 1266 environment\n";
}

if ($opt_uemodel and !$opt_nofub) {
  die "-F- $EXE_NAME: -model must be used with -nofub option.\n";
}

if ($opt_skipnetlist and !$opt_nofub) {
  die "-F- $EXE_NAME: -skipnetlist must be used with -nofub option.\n";
} 

my $opt_skipcellfile_resolved;
if (defined $opt_skipcellfile) {
  if (-e $opt_skipcellfile) {
    my ($name,$path,$suffix) = fileparse($opt_skipcellfile);
    my $resolved_path = abs_path($path);
    $opt_skipcellfile_resolved = "${resolved_path}/${name}";
  } else {
    die "-F- $EXE_NAME: -skipcellfile file does not exist.\n";
  }
}

# Will be set for Merom and PNR
if ($opt_nocmpdiodes) {
  $ENV{'PDS_DONTCMPDIODES'} = 'YES';
}


# Getting tired of all of the licences in the path. Really slows the jobs down
if ($SITE eq 'iil') {
  $LM_LICENSE_FILE = '1704@ilics04.iil.intel.com:1704@ilics05.iil.intel.com:1704@ilics06.iil.intel.com:1700@ilics04.iil.intel.com:1700@ilics05.iil.intel.com:1700@ilics06.iil.intel.com:7185@ilics04.iil.intel.com:7185@ilics05.iil.intel.com:7185@ilics06.iil.intel.com:26585@ilics05.iil.intel.com:26585@ilics06.iil.intel.com:26585@ilics04.iil.intel.com:5280@ilics04.iil.intel.com:5280@ilics05.iil.intel.com:5280@ilics06.iil.intel.com';
}


# Variables to start log file
my $cell_lc = lc($opt_cell);

our ($BASEFILE, $MAINLOG, $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${EXE_PREFIX}";
$MAINLOG = LogFile->new("${WARD}/${BASEFILE}.log");
$MAINLOG->flowname($EXE_NAME);
$MAINLOG->verbose($opt_verbose);

my $machine_info = `uname -a`;
chomp $machine_info;
$MAINLOG->info("Script command: $EXE_NAME $COMMAND_LINE");
$MAINLOG->info("Script start date: $start_date");
$MAINLOG->info("Machine Type: $machine_info");

# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @TMPFILES = ();

if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $MAINLOG->infoq("-env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $MAINLOG->fatalq("Invalid value for switch -env: $setting");
    }
  }
}


my $stage = 1;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Start Merom UE and search for clean netlist/LNF *****");

if ($opt_dbb) {
  $MAINLOG->info("-dbb switch detected. Will be using following option for Merom UE: (-b $opt_dbb)");
}

if ($opt_uemodel) {
  $MAINLOG->info("-uemodel switch detected. Will be using following option for Merom UE: (-m $opt_uemodel)");
}


# Capture current UE environment
my %env_snapshot;
&CaptureEnvironment($MAINLOG, \%env_snapshot);

$MAINLOG->infoq("Setting environment to Merom UE context...");
# Switch context to Merom UE.
my @ue_options = ("-p mrm", "-hp mrm", "-pr $mig_input_process", "-ot /nfs/site/proj/mpg/proc/common/proj_tools/genesys/genesys.tools.versions_5.1.2", "-d", "-b none");

if ($opt_uemodel) {
  push (@ue_options, "-m $opt_uemodel");
} else {
  push (@ue_options, "-m latest");
}

# Remember, these are tied vars to the ENV table.
if ($OVERRIDE_WORK_DIR) {
  push (@ue_options, "-ov $OVERRIDE_WORK_DIR");
}
if ($AREA_NAME) {
  push (@ue_options, "-n $AREA_NAME");
} else {
  push (@ue_options, "-n none");
}

my $output_env_file = "${WARD}/${BASEFILE}.mrm.env";
push (@ue_options, "-cmd \'/usr/bin/env > $output_env_file\'");
push (@TMPFILES, $output_env_file);

my $ue_option_line = join(' ', @ue_options);
my $ue_log_file = "${WARD}/${BASEFILE}.mrm.ue";
push (@TMPFILES, $ue_log_file);

my $ue_env_file = "$mig_utils{$SITE}/mrm_only.printenv";

my %ue_env_to_unset;
&ReadEnvironmentFile($MAINLOG, $ue_env_file, \%ue_env_to_unset);
&ClearEnvironment($MAINLOG, \%ue_env_to_unset);
unless (&Tcsh($MAINLOG, "/nfs/site/proj/mpg/proc/cad/i386_linux22/uesetup/uesetup44 $ue_option_line >& $ue_log_file")) {
  die $MAINLOG->fatalq("Merom UE setup call returned non-zero exit status");
}
my %ue_env;
&ReadEnvironmentFile($MAINLOG, $output_env_file, \%ue_env);
my $force_set_env = 1;
&SetEnvironment($MAINLOG, \%ue_env, $force_set_env, $opt_debug);
$ENV{'LM_LICENSE_FILE'} = '1704@ilics04.iil.intel.com:1704@ilics05.iil.intel.com:1704@ilics06.iil.intel.com:1700@ilics04.iil.intel.com:1700@ilics05.iil.intel.com:1700@ilics06.iil.intel.com:'.$ENV{'LM_LICENSE_FILE'};

# Tie the following perl variables to their environment counterparts 
our ($DB_ROOT, $PROJECT, $NIKE_NETLISTER, $PROJ_SKILL, $DMSPATH, $GENESYS_DIR);
our ($MODEL, $DBB, $GLOBALS, $CDSLIB, $CAD_ROOT, $GENESYS, $GENESYSSCRIPTS, $GENESYS_VER);
@env_list = ('DB_ROOT', 'PROJECT', 'NIKE_NETLISTER', 'PROJ_SKILL', 'DMSPATH', 'GENESYS_DIR');
@env_list = (@env_list, 'MODEL', 'DBB', 'GLOBALS', 'CDSLIB', 'CAD_ROOT', 'GENESYS');
@env_list = (@env_list, 'GENESYSSCRIPTS', 'GENESYS_VER');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


unless ($GENESYS_DIR =~ /5\.1/) {
  die $MAINLOG->fatalq("You must be running Genesys version 5.1 or later to run this flow");
}

# Set the working directory to WARD
chdir ($WARD) or die "-E- $EXE_NAME: Could not change script working dir to $WARD\n";

# Make sure we can't mess with the ATF database
$ENV{'ATF_LOCKED'} = 'YES';

$MAINLOG->newline;
if  ($opt_nofub) {
  $MAINLOG->info("-nofub option detected. Input cell will not be validated as FUB");
} else {
  # Validate that the fub entry is indeed a fub
  $MAINLOG->infoq("Checking fub=${cell_lc} is a valid fub in MRM...");
  &ValidateFubExists($cell_lc);
}

# Search for CMP clean LNF model in database
my @uemodel_list;
if ($opt_nofub) {
  @uemodel_list = ($MODEL);
} else {
  #@uemodel_list = ('silver', 'lorf', '1266_migration', 'lor2', 'lay_model', 'latest');
  @uemodel_list = ('silver', 'a0');
}

my $models = join(' ', @uemodel_list);
$MAINLOG->info("The following UE models will be searched for CMP clean data: $models");

my $rundirty;
my $gdsintp;
my $pds_sum_or_abort;
my $good_model;
my $sch_cfg;
my $lay_cfg;


my $cell_netlist_dir = "${PDSSN}/${cell_lc}_harvest_sn_${mig_input_process}";
my $cell_netlist_sn = "${cell_netlist_dir}/${cell_lc}.sn";
push(@TMPFILES, $cell_netlist_sn);
my $cvssch_sn = "${PDSSN}/${cell_lc}.sn";
push(@TMPFILES, $cvssch_sn);    # In the flow, it is just a link.


my $orig_dmspath = $DMSPATH;
my $orig_cdslib = $CDSLIB;
# Search for clean layout model in the Merom database
MODELSEARCH: foreach my $model (@uemodel_list) {
  $MAINLOG->info("Starting search for CMP clean data on model: ($model)");
  $good_model = $model;
  
  # If a fub cfg file exists for the given uemodel, use it
  my $cfgfile = "${DA_PROJECTS}/${PROJECT}/${PROJECT}.${model}.cfg";
  my $fubcfg_file = "/nfs/site/proj/yonah/yonah002/lorf_models/mrm.${cell_lc}_${model}.cfg";
  my $fub_stdcell_cfg = "${WARD}/${BASEFILE}.${model}.cfg";
  if (-f $fubcfg_file) {
    &ManipFile($MAINLOG, 'copy', '', $fubcfg_file, $fub_stdcell_cfg);
  } else {
    $fub_stdcell_cfg = '';
  }

  my $dbb;
  if ($opt_dbb) {
    $dbb = $opt_dbb;
  }
  elsif ($opt_nofub) {
    $dbb = 'none';
  } else {
    $dbb = $cell_lc;
  }
  
  
  # Extract exact config used for a UE model from .cfg file
  my @cfg_list;
  if ($opt_nofub) {
    $sch_cfg = 'NOFUB';
    $lay_cfg = 'NOFUB';
  } else {
    @cfg_list = &GetConfigsFromModel($MAINLOG, $dbb, $cfgfile);
    if (scalar @cfg_list) {
      if ($model !~ /latest/) {
	my $skip_to_next_model = 1;
	foreach my $cfgstring (@cfg_list) {
	  my ($lib, $cfg) = split(/\s+/, $cfgstring);
	  $MAINLOG->infoq("Model: ($model)  Lib: ($lib)  Cfg: ($cfg)");
	  if ($lib =~ /_lay$/) {
	    if (($lib =~ /${cell_lc}_\S+_lay/) and ($cfg =~ /^latest$/i)) {
	      $MAINLOG->info("Model: $model has cfg $cfg for its primary lay library. Skipping to next model.");
	      next MODELSEARCH;
	    }
	    unless ($cfg =~ /^latest$/i) {
	      $skip_to_next_model = 0;
	    }
	  }
	}
	if ($skip_to_next_model) {
	  $MAINLOG->info("All cfg values were latest for this model. Skipping to next model.");
	  next MODELSEARCH;
	}
      }
      
    } else {
      $MAINLOG->info("dbb $dbb does not have an _lay entry in the cfg file. Skipping to next model.");
      next MODELSEARCH;
    }
  }
  
  # Hack DMSPATH for specific fub
  $MAINLOG->infoq("Compiling dmspath for UE model: $model...");
  my $newdmspath = "${WARD}/${BASEFILE}.dms.pth";
  push(@TMPFILES, $newdmspath);
  my $newcdslib = "${WARD}/${BASEFILE}.cds.lib";
  push(@TMPFILES, $newcdslib);
  
  $DMSPATH = $orig_dmspath;  # Reset so compiler can read original modes file
  my $usercfg;
  if (-f $fub_stdcell_cfg) {
    $MAINLOG->infoq("Fub config file found. Passing cfg to dmscomp: $fub_stdcell_cfg");
    $usercfg = "-usercfgfile $fub_stdcell_cfg";
  } else {
    $usercfg = '';
  }
  &RecompileDmspath($MAINLOG, $dbb, $model, $newdmspath, $newcdslib, $usercfg);
  $DMSPATH = $newdmspath;
  $CDSLIB = $newcdslib;


  # Run nike netlister on cell to generate SN file
  if ($opt_skipnetlist) {
    # Simulate generation of SN. Original 
    $MAINLOG->info("-skipnetlist option detected. Existing .sn in \$PDSSN will be used as input");
    &CreateDirTrees($cell_netlist_dir);
    &ManipFile($MAINLOG, 'copy', $cell_netlist_dir, $cvssch_sn, basename($cvssch_sn) . ".skipnetlist_sn");
    &ManipFile($MAINLOG, 'copy', '', $cvssch_sn, $cell_netlist_sn);
  } else {
    $MAINLOG->infoq("Running nike_netlister to generate SN...");
    my $input_netlist_format;
    my $output_netlist_format;
    if ($opt_sch) {
      $input_netlist_format = 'sch';
      $output_netlist_format = 'snsch';
      $MAINLOG->info('-sch option detected. Using sch for input netlist format');
    } else {
      $input_netlist_format = 'cdba';
      $output_netlist_format = 'sn';
    }
    $rundirty = &RunNikeNetlister($MAINLOG, $cell_lc, $input_netlist_format, $output_netlist_format, "-outd $cell_netlist_dir");
    if ($rundirty) {
      $MAINLOG->infoq("Netlist run DIRTY for model: ($model). Skipping to next model");
      &DeleteFiles($cell_netlist_sn);
      next MODELSEARCH;
    }
    if (-e $cell_netlist_sn) {
      &ManipFile($MAINLOG, 'copy', '', $cell_netlist_sn, $cvssch_sn);
    } else {
      die $MAINLOG->fatalq("SN not found after nike_netlister run. See netlisting and harvest log files");
    }
  }
  

  my $iss_header = "ISS TRCSTD (LNF Input-All Data)";
  $MAINLOG->infoq("Running ${iss_header}...");
  $gdsintp = 0;
  ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'lnf', 'trcstd', '', $gdsintp);
  my $cfgstring = '';
  if (scalar @cfg_list) {
    foreach my $entry (@cfg_list) {
      my ($lib, $cfg) = split(/\s+/, $entry);
      $cfgstring .= "${lib}:($cfg) ";
    }
  }

  my $model_cfg_string = "cell:($cell_lc) model:($model) $cfgstring";
  chomp($model_cfg_string);
  if ($rundirty) {
    if ($pds_sum_or_abort =~ /\.sum$/) {
      $MAINLOG->warnq("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
      $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL');
      if ($rundirty) {
	$MAINLOG->infoq("$iss_header run DIRTY for $model_cfg_string. Skipping to next model");
	$MAINLOG->newline;
	next MODELSEARCH;
      } else {
	$MAINLOG->info("$iss_header run CLEAN-WAIVED for $model_cfg_string");
	last MODELSEARCH;
      }
    }
    elsif ($pds_sum_or_abort =~ /\.abort$/) {
      $MAINLOG->infoq("$iss_header run ABORTED for model: ($model). Skipping to next model");
      &ManipFile($MAINLOG, 'copy', '', $pds_sum_or_abort, "${PDSLOGS}/${BASEFILE}.${model}.abort");
      next MODELSEARCH;
    } else {
      die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
    }
  } else {
    $MAINLOG->info("$iss_header run CLEAN for $model_cfg_string");
    last MODELSEARCH;
  }
}

if ($rundirty) {
  if ($opt_ignorecmp) {
    $MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
  } else {
    die $MAINLOG->fatalq("Could not find clean netlist/CMP run for any target UE models");
  }
}

my $cvssch_sn_orig = "${PDSSN}/${cell_lc}.sn.${good_model}";
push(@TMPFILES, $cvssch_sn_orig);
&ManipFile($MAINLOG, 'move', $cell_netlist_dir, basename($cvssch_sn), basename($cvssch_sn_orig));
&ManipFile($MAINLOG, 'move', $PDSSN, basename($cvssch_sn), basename($cvssch_sn_orig));


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Remove bonus/fib data from clean netlist/LNF and re-verify *****");
# Run nike netlister on cell to generate SN file
my %skipcell_table;

$skipcell_table{"${cell_lc}_autovia"} = 'DELETE';
$skipcell_table{"${cell_lc}_megacontainer"} = 'DELETE';
$skipcell_table{"${cell_lc}_oth"} = 'DELETE';
$skipcell_table{'gnac*'} = 'DELETE';
$skipcell_table{'t00dcp00*'} = 'DELETE';

foreach my $cell (sort keys %skipcell_table) {
  $MAINLOG->infoq("$EXE_NAME added cell to skipcell list. Cell->($cell)   Directive->($skipcell_table{$cell})");
}

my $genbonus_cell_file = "$GLOBALS/genbonus_cell.list.mrm";
my $bonus_cell_file = "$GLOBALS/bonus_cell.list.mrm";
my @skipcell_files;

@skipcell_files = ($genbonus_cell_file, $bonus_cell_file);
if ($opt_skipcellfile_resolved) {
  push (@skipcell_files, $opt_skipcellfile_resolved);
}

foreach my $file (@skipcell_files) {
  &AddCellsToSkipTable($MAINLOG, \%skipcell_table, $file, 'DELETE');
}

&RemoveCellsFromSkipTable($MAINLOG, \%skipcell_table, 'lcpfibop', 'fibnc', 'fibc');  # Remove cells from skip list that impact CMP cleanliness
my $skipcell_file = "${WARD}/${BASEFILE}.skipcell";
&GenerateSkipCellFile($MAINLOG, \%skipcell_table, $skipcell_file);
my $explodelist = "${WARD}/${BASEFILE}.explode";
push(@TMPFILES, $explodelist);
&GenerateExplodeList($MAINLOG, \%skipcell_table, $explodelist);


my $mkisp_sn = "${WARD}/netlists/mkisp/${cell_lc}.sn";
push(@TMPFILES, $mkisp_sn);
&ManipFile($MAINLOG, 'copy', '', $cvssch_sn_orig, $mkisp_sn);
&ManipFile($MAINLOG, 'copy', '', $mkisp_sn, "${mkisp_sn}.withbonus.${mig_input_process}");
# Run nike netlister on cell to generate SN file
$MAINLOG->infoq("Running nike_netlister with skiplist to generate SN...");
my $input_netlist_format;
my $output_netlist_format;
if ($opt_sch) {
  $input_netlist_format = 'sch';
  $output_netlist_format = 'snsch';
} else {
  $input_netlist_format = 'sn';
  $output_netlist_format = 'snsch';
}
$rundirty = &RunNikeNetlister($MAINLOG, $cell_lc, $input_netlist_format,  $output_netlist_format, "-outd $cell_netlist_dir", "-skip_input_cell_list $skipcell_file");
if ($rundirty) {
  die $MAINLOG->fatalq("Netlist run with skipcell list failed");
}
my $cvssch_sn_nobonus = "${cvssch_sn_orig}.nobonus.${mig_input_process}";
&ManipFile($MAINLOG, 'copy', $cell_netlist_dir, basename($cell_netlist_sn), basename($cvssch_sn_nobonus));
&ManipFile($MAINLOG, 'copy', '', $cell_netlist_sn, $cvssch_sn_nobonus);
&ManipFile($MAINLOG, 'symlink', $PDSSN, basename($cvssch_sn_nobonus), basename($cvssch_sn));


# Run PDS TRCSTD on LNF with explode list to remove undesired cells
my $iss_header = "ISS TRCSTD (LNF-CellsRemoved)";
$MAINLOG->infoq("Running ${iss_header}...");
$gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'lnf', 'trcstd', $explodelist, $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL');
    if ($rundirty) {
      if ($opt_ignorecmp) {
	$MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
      } else {
	die $MAINLOG->fatalq("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
    }
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    if ($opt_ignorecmp) {
      $MAINLOG->warn("-ignorecmp detected. CMP run aborted but proceeding to next stage");
    } else {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    }
  } else {
    die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
  }
} else {
  $MAINLOG->info("$iss_header run CLEAN");
}


# Run PDS TRCSTD with explode list again, but this time to migrated schematic 
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: ISS TRCSTD On layout vs migrated SN  *****");
my $fub_sch_area = "$mig_lookup{$SITE}{'migsch'}/${cell_lc}";
my $fub_mig_sn = "${fub_sch_area}/${cell_lc}_after.sn";
my $fub_mig_cfg = "${fub_sch_area}/${cell_lc}.sch_cfg";
if (-e $fub_mig_sn) {
  $MAINLOG->info("Migrated SN found: $fub_mig_sn");
  &ManipFile($MAINLOG, 'copy', $PDSSN, $fub_mig_sn, basename($fub_mig_sn));
  &ManipFile($MAINLOG, 'symlink', $PDSSN, basename($fub_mig_sn), basename($cvssch_sn));
  open (CFG, $fub_mig_cfg) or die $MAINLOG->fatalq("Could not open cfg file for reading: $fub_mig_cfg");
  my $cfg = 'NO_CONFIG';
  while (<CFG>) {
    if (/(\S+)/) {
      $cfg = $1;
      last;
    }
  }
  close (CFG);
  $MAINLOG->infoq("Migration SN config:(${cfg})");
  # Run PDS TRCSTD on LNF with explode list to remove undesired cells
  $iss_header = "ISS TRCSTD (LNF-CellsRemoved-MigratedSN)";
  $MAINLOG->infoq("Running ${iss_header}...");
  $gdsintp = 0;
  ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'lnf', 'trcstd', $explodelist, $gdsintp);
  if ($rundirty) {
    if ($pds_sum_or_abort =~ /\.sum$/) {
      $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
      $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL');
      if ($rundirty) {
	if ($opt_ignorecmp) {
	  $MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
	} else {
	  $MAINLOG->warn("$iss_header run DIRTY");
	}
      } else {
	$MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
      }
    }
    elsif ($pds_sum_or_abort =~ /\.abort$/) {
      if ($opt_ignorecmp) {
	$MAINLOG->warn("-ignorecmp detected. CMP run aborted but proceeding to next stage");
      } else {
	die $MAINLOG->fatalq("$iss_header run ABORTED");
      }
    } else {
      die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
    }
  } else {
    $MAINLOG->info("$iss_header run CLEAN");
  }
} else {
  $MAINLOG->warnp("Migrated SN NOT found: $fub_mig_sn");
}
&ManipFile($MAINLOG, 'symlink', $PDSSN, basename($cvssch_sn_nobonus), basename($cvssch_sn));


# Call Genesys and convert LNF->GDSII
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Preprocess LNF files and write/verify Genesys STM  *****");
$MAINLOG->infoq("Preprocessing LNF files in Genesys...");
# Pre-deleted .stm file until I can dig up the UDM function
# to force the save with no prompting

my $genesys_stm = "${WORK_AREA_ROOT_DIR}/genesys/stm/${cell_lc}.stm";
&DeleteFiles($genesys_stm);

# Disable the undo stack
$ENV{'TRANSIENT_PSE_DB'} = 1;

# Exclude the nasty polygons that exist on the keepout layers
my %tech_table;
my @layers_to_exclude_from_genesys_stm;
&ReadDTTechFile($MAINLOG, $pds_lookup{$SITE}{"niketech${mig_input_process}"}, \%tech_table, $opt_debug);
foreach my $layer (sort keys %{ $tech_table{'MODTECH'} }) {
  if ($layer =~ /(KEEPOUT|OVZ)$/) {
    push (@layers_to_exclude_from_genesys_stm, lc($layer));
    $MAINLOG->infoq("The following layer will be excluded from Genesys stm file: $layer");
  }
}

# Use release with new force term inst labels option for stm output
if ($opt_textflow) {
  $GENESYS_DIR = "${CAD_ROOT}/genesys/5.1.1_stPseOpt";
  $GENESYS = "$GENESYS_DIR/bin";
  $GENESYSSCRIPTS = "$GENESYS_DIR/data/scripts";
  $GENESYS_VER = "5.1.1_stPseOpt";
}

# Open Genesys session
my $genesyslog = "${WARD}/${BASEFILE}.genesyslog";
my $genesysfh = &GenesysOpenSession($genesyslog);

# Set stm writer options
&GenesysCommandLine($genesysfh, "\nstm instanceProperty 112");
&GenesysCommandLine($genesysfh, 'stm userUnits .001');
&GenesysCommandLine($genesysfh, 'stm outputCellInsts 0');
&GenesysCommandLine($genesysfh, 'stm filterPolygons 1');
&GenesysCommandLine($genesysfh, 'stm mergePolygons 0');
&GenesysCommandLine($genesysfh, 'stm useExcludeLayers 1');
my @layer_exclude_directives;
foreach my $layer (@layers_to_exclude_from_genesys_stm) {
  &GenesysCommandLine($genesysfh, "stm addExcludeLayer $layer");
}

if ($opt_textflow) {
  &GenesysCommandLine($genesysfh, 'stm outputTermInsts 0');
  &GenesysCommandLine($genesysfh, 'stm forcedTermInstLabels 1');
} else {
  &GenesysCommandLine($genesysfh, 'stm outputTermInsts 1');
}


# Minimize the amount of data in the run area
&GenesysCommandLine($genesysfh, 'set cvm [::boo::CellViewMgr_getCellViewMgr]');
&GenesysCommandLine($genesysfh, '$cvm setSaveBackups 0');

# Preprocess LNF files
my $readonly = 1;
&GenesysOpenCell($cell_lc, 'lnf', '', $readonly, $genesysfh);
&GenesysLoadModules(\@mig_tcl_modules_list, $genesysfh);
foreach my $targetcell (sort keys %skipcell_table) {
  if ($skipcell_table{$targetcell} eq 'DELETE') {
    &GenesysCommandLine($genesysfh, "::mig::deleteCell $targetcell");
  }
}
&GenesysCommandLine($genesysfh, '::mig::markTermInsts') if $opt_textflow;
&GenesysCommandLine($genesysfh, '::mig::getCellHeightWidth');

# Save snapshot of LNF data
&GenesysSaveStm($cell_lc, "$WARD/genesys/stm", $genesysfh);
my $genesyslnfdir = "${WARD}/genesys/lnf/${cell_lc}_${EXE_PREFIX}_lnf_${mig_input_process}";
&GenesysSaveAllWithPrefix($cell_lc, 'lnf', '', $genesyslnfdir, $genesysfh);

# Close session and check output (open3... someday)
&GenesysCloseSession($genesysfh);
&CheckGenesysPreProcess($MAINLOG, $genesyslog);
unless (-e $genesys_stm) {
  die $MAINLOG->fatalq("Stm file from Genesys not generated:", $genesys_stm);
}


# Move stm file to PDS area for ISS
my $genesys_stm_pds = "${PDSSTM}/${cell_lc}.stm.genesys";
push(@TMPFILES, $genesys_stm_pds);
my $pds_stm = "${PDSSTM}/${cell_lc}.stm";
push(@TMPFILES, $pds_stm);   # In the flow this file is a link
&DeleteFiles($pds_stm);
&ManipFile($MAINLOG, 'copy', '', $genesys_stm, $genesys_stm_pds);
&ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($genesys_stm_pds), basename($pds_stm));


# Run PDS TRCSTD on stm from Genesys
$iss_header = "ISS TRCSTD (STM-Genesys)";
$MAINLOG->infoq("Running ${iss_header}...");
$gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcstd', '', $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL');
    if ($rundirty) {
      if ($opt_ignorecmp) {
	$MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
      } else {
	die $MAINLOG->fatalq("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
    }
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    if ($opt_ignorecmp) {
      $MAINLOG->warn("-ignorecmp detected. CMP run aborted but proceeding to next stage");
    } else {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    }
  } else {
    die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
  }
} else {
  $MAINLOG->info("$iss_header run CLEAN");
}


#
# Generate initial CIF with no multivalue props. This initial CIF will have all of the layers. Since no properties are dropped, should be a better starting point for CMP

# Generate layconv map file for initial STM-CIF. This initial CIF will have all the layers the stm file has. Used to 
# avoid layconv bug with multivalue props
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Text Stripped CIF Generation  *****");
$MAINLOG->infoq("Building layconv map file (input to mulitprop clean layconv runs)");
&ReadPdbFile($MAINLOG, $mig_lookup{$SITE}{"pdb${mig_input_process}"}, \%tech_table, $opt_debug);
if ($opt_debug) {
  foreach my $layer (sort keys %{ $tech_table{'MODTECH'} }) {
    foreach my $type (sort keys %{ $tech_table{'MODTECH'}{$layer} }) {
      $MAINLOG->infod("DT TECH: layer: $layer  type: $type   value: $tech_table{'MODTECH'}{$layer}{$type}");
    }
  }
  foreach my $layer (sort keys %{ $tech_table{'PDB'} }) {
    foreach my $type (sort keys %{ $tech_table{'PDB'}{$layer} }) {
      $MAINLOG->infod("PDB: layer: $layer  type: $type   value: $tech_table{'PDB'}{$layer}{$type}");
    }
  }
}
my $mapfile = "${WARD}/${BASEFILE}.layconvmap";
push(@TMPFILES, $mapfile);
&GenerateLayconvMapFile($MAINLOG, \%tech_table, $mapfile);

# Generate initial CIF
$MAINLOG->infoq("Converting raw Genesys STM to CIF with all $mig_input_process layers (multiprop clean)...");
my $genesys_cif = "${PDSSTM}/${cell_lc}.cif.genesys";
push(@TMPFILES, $genesys_cif);
&SagantecLayconv($MAINLOG, $pds_stm, 'stm', $genesys_cif, 'cif', $mig_lookup{$SITE}{"pdb${mig_input_process}"}, "-a  $mapfile");



my $cif_for_text_generation;

if ($opt_textflow) {
  my @real_layers;
  my @port_layers;
  my @topport_marker_layers;
  foreach my $layer ('poly', 'metal1', 'metal2', 'metal3','metal4', 'metal5', 'metal6', 'metal7', 'metal8') {
    push (@real_layers, $layer);
    push (@port_layers, "${layer}_portDrawing");
    push (@topport_marker_layers, "${layer}keepout");
  }

  # Generate port properties on real layers
  my $portprop_cif = "${PDSSTM}/${cell_lc}.cif.portprops";
  push(@TMPFILES, $portprop_cif);
  &SagPerlCifIO($MAINLOG, 'GeneratePortPropsInCif', $cell_lc, $genesys_cif, $portprop_cif, @real_layers);


  # Merge ports and keepout layer markers for top ports
  my $portmerge_cif = "${PDSSTM}/${cell_lc}.cif.mergedport";
  push(@TMPFILES, $portmerge_cif);
  &Polar($MAINLOG, $portprop_cif, $portmerge_cif, $mig_pdb_file, 'merge_ports');


  # Strip text to prepare for text re-generation
  my $notext_cif = "${PDSSTM}/${cell_lc}.cif.mergedport_notext";
  push(@TMPFILES, $notext_cif);
  &SagPerlCifIO($MAINLOG, 'StripTextFromCif', $cell_lc, $portmerge_cif, $notext_cif);


  # Move 'text' property from Polar to gdsprop 126
  my $gds126_cif = "${PDSSTM}/${cell_lc}.cif.texttogds126";
  push(@TMPFILES, $gds126_cif);
  &SagPerlCifIO($MAINLOG, 'ConvertTextPropToGds126', $cell_lc, $notext_cif, $gds126_cif);

  # Regenerate text for merged port/KO layers. Multivalue props are a fatal condition unless all of the nets are syn nets
  my $reduced_kotext_cif = "${PDSSTM}/${cell_lc}.cif.reduced_kotext";
  push(@TMPFILES, $reduced_kotext_cif);
  &SagPerlCifIO($MAINLOG, 'GenerateTextInCif', $cell_lc, $gds126_cif, $reduced_kotext_cif, @port_layers,  @topport_marker_layers);


  # Map the keepout layer text to real metal text
  my $reduced_text_cif = "${PDSSTM}/${cell_lc}.cif.reduced_text";
  push(@TMPFILES, $reduced_text_cif);
  &SagPerlCifIO($MAINLOG, 'CopyKeepoutTextToMetalText', $cell_lc, $reduced_kotext_cif, $reduced_text_cif);


  # Strip the ports and keepout polygons from database
  my $ports_removed_cif = "${PDSSTM}/${cell_lc}.cif.ports_removed";
  push(@TMPFILES, $ports_removed_cif);
  &SagPerlCifIO($MAINLOG, 'StripPolygonsFromCif', $cell_lc, $reduced_text_cif, $ports_removed_cif, @port_layers,  @topport_marker_layers);

  # Keep only essential layers in the CIF
  my @delete_layers;
  open (MAPFILE, $mapfile) or die $MAINLOG->fatalq("Could not open layconv map file for reading: $mapfile");
  while (<MAPFILE>) {
    if (/^\s*(\S+)\s+\d+\s+\d+/) {
      push(@delete_layers, $1);
    }
  }
  my $essential_layer_cif = "${PDSSTM}/${cell_lc}.cif.essential_layers";
  push(@TMPFILES, $essential_layer_cif);
  &SagPerlCifIO($MAINLOG, 'StripLayersFromCif', $cell_lc, $ports_removed_cif, $essential_layer_cif, @delete_layers);

  $cif_for_text_generation = $essential_layer_cif;

} else {

  # Re-write GDSII with only PDB layers
  $MAINLOG->infoq("Converting Genesys CIF to STM, $mig_input_process PDB layers only...");
  my $essential_layer_stm = "${PDSSTM}/${cell_lc}.stm.essential_layers";
  push(@TMPFILES, $essential_layer_stm);
  &SagantecLayconv($MAINLOG, $genesys_cif, 'cif', $essential_layer_stm, 'stm', $mig_lookup{$SITE}{"pdb${mig_input_process}"}, '-w');
  
  # Re-convert to CIF with only required layers
  $MAINLOG->infoq("Converting essential layer STM to CIF...");
  my $essential_layer_cif = "${PDSSTM}/${cell_lc}.cif.essential_layers";
  push(@TMPFILES, $essential_layer_cif);
  &SagantecLayconv($MAINLOG, $essential_layer_stm, 'stm', $essential_layer_cif, 'cif', $mig_lookup{$SITE}{"pdb${mig_input_process}"}, '');

  # Strip syn net properties from CIF
  $MAINLOG->infoq("Stripping syn net properties from CIF...");
  my $nosyn_cif = "${PDSSTM}/${cell_lc}.cif.nosyn";
  &SagPerlCifIO($MAINLOG, 'StripSynPropsFromCif', $cell_lc, $essential_layer_cif, $nosyn_cif);

  # Strip all text from CIF file
  $MAINLOG->infoq("Stripping Text From CIF to generate $mig_input_process harvest CIF...");
  my $notext_cif = "${PDSSTM}/${cell_lc}.cif.notext";
  &SagPerlCifIO($MAINLOG, 'StripTextFromCif', $cell_lc, $nosyn_cif, $notext_cif);

  $cif_for_text_generation = $notext_cif;

}


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Final CIF->STM Verification  *****");
# Add text back into CIF, regenerate GDS, and run final 1264 verification
$MAINLOG->infoq("Regenerating text in CIF for final ${mig_input_process} verification...");
my $gentext_cif = "${PDSSTM}/${cell_lc}.cif.gentext";
push(@TMPFILES,  $gentext_cif);
&SagPerlCifIO($MAINLOG, 'GenerateTextInCif', $cell_lc, $cif_for_text_generation, $gentext_cif);
my $gentext_stm = "${PDSSTM}/${cell_lc}.stm.gentext";
&SagantecLayconv($MAINLOG, $gentext_cif, 'cif', $gentext_stm, 'stm', $mig_lookup{$SITE}{"pdb${mig_input_process}"}, '-w');
&ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($gentext_stm), basename($pds_stm));

$iss_header = "ISS TRCSTD (STM-GeneratedFrom1264CIF)";
$MAINLOG->infoq("Running ${iss_header}...");
$gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcstd', '', $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL');
    if ($rundirty) {
      if ($opt_ignorecmp) {
	$MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
      } else {
	die $MAINLOG->fatalq("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
    }
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    if ($opt_ignorecmp) {
      $MAINLOG->warn("-ignorecmp detected. CMP run aborted but proceeding to next stage");
    } else {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    }
  } else {
    die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
  }
} else {
  $MAINLOG->info("$iss_header run CLEAN");
}

my $input_process_harvest_cif = "${PDSSTM}/${cell_lc}.cif.${good_model}.${mig_input_process}";
&ManipFile($MAINLOG, 'copy', '', $cif_for_text_generation, $input_process_harvest_cif);
$MAINLOG->infoq("Final (${mig_input_process}) harvest cif -> $input_process_harvest_cif");

# Run PDSXOR between stripped STM and original LNF data
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: XOR between LNF and final STM for data collection *****");
# Hack in genesys lnf dir into isstools path
open (DMSPATH, $DMSPATH) or die $MAINLOG->fatalq("Could not open $DMSPATH for reading");
my $tempdms = "${WARD}/${BASEFILE}.dms.pth.xor";
push(@TMPFILES, $tempdms);
open (TEMPDMS, ">$tempdms") or die $MAINLOG->fatalq("Could not open $tempdms for writing");
my $isstools_section = 0;
while (<DMSPATH>) {
  if (/DMS PATH FOR TOOL: isstools/) {
    $isstools_section = 1;
  }
  if ($isstools_section) {
    if (/\$WORK_AREA_ROOT_DIR\/layout/) {
      s/\$WORK_AREA_ROOT_DIR\/layout/$genesyslnfdir/;
    }
    if (/libpath/) {
      $isstools_section = 0;
    }
  }
  print TEMPDMS $_;
}
close (DMSPATH);
close (TEMPDMS);
&ManipFile($MAINLOG, 'copy', '', $tempdms, $DMSPATH);
$rundirty = &RunPdsXor($MAINLOG, $cell_lc, $cell_lc, 'lnf', 'stm', "-stm2 $pds_stm");


# Initialize migration environment
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Initializing migration environment and directories *****");
# Change context back to original 1266 UE
# Unset the entire environment
$MAINLOG->infoq("Resetting environment back to original 1266 UE");
&ClearEnvironment($MAINLOG, '');
# Reload environment from original snapshot
$force_set_env = 0;   # Environment should be empty...
&SetEnvironment($MAINLOG, \%env_snapshot, $force_set_env, $opt_debug);

# Read specialized migration vars
our %mig_env_table;
&ReadEnvironmentFile($MAINLOG, $mig_mode_table{'1265'}, \%mig_env_table);
$force_set_env = 0;   # Want to use any mig env vars already set in environment
&SetEnvironment($MAINLOG, \%mig_env_table, $force_set_env, 1);
if ($opt_nofub) {
  $ENV{'name_prefix'} = 'xx';
} else {
  $ENV{'name_prefix'} = &GetFubCode($MAINLOG, $cell_lc);
}
$ENV{'fub'} = $cell_lc;

$MAINLOG->infoq("\$fub = $ENV{'fub'}\n");
$MAINLOG->infoq("\$name_prefix = $ENV{'name_prefix'}");

my $mig_ue_area = "$WORK_AREA_ROOT_DIR/mig";
my $mig_auxiliaries = "${mig_ue_area}/${cell_lc}/auxiliaries";
my $mig_input_process_src = "${mig_ue_area}/${cell_lc}/src-${mig_input_process}";
my $mig_src = "${mig_ue_area}/${cell_lc}/src";
my $mig_bin = "${mig_ue_area}/${cell_lc}/bin";
my $mig_setup = "${mig_ue_area}/${cell_lc}/setup";
my $mig_work = "${mig_ue_area}/${cell_lc}/work-${cell_lc}-harvest";
&CreateDirTrees($mig_ue_area, $mig_auxiliaries, $mig_bin, $mig_setup, $mig_work);
&CreateDirTrees($mig_input_process_src, $mig_src);

&ManipFile($MAINLOG, 'copy', $mig_input_process_src, $input_process_harvest_cif, basename($input_process_harvest_cif));
&ManipFile($MAINLOG, 'symlink', $mig_input_process_src, basename($input_process_harvest_cif), "${cell_lc}.cif");


if ($opt_only1264) {
  $MAINLOG->info("-only1264 switch detected. Skipping 1264->1265 manipulations");
  &ManipFile($MAINLOG, 'copy', $mig_src,  $input_process_harvest_cif, "${cell_lc}.cif");
  $MAINLOG->infoq("Final (${mig_input_process}) harvest cif -> ${mig_input_process_src}/${cell_lc}.cif.${good_model}.${mig_input_process}");
  $MAINLOG->infoq("$mig_input_process CIF copied to /src area");
  goto END;
}


my $mig_intermediate_process_src = "${mig_ue_area}/${cell_lc}/src-${mig_intermediate_process}";
&CreateDirTrees($mig_intermediate_process_src);

$MAINLOG->infod("Checking out RCS contents to bin area...") if $opt_debug;
&RcsCo($MAINLOG, $mig_bin, $mig_lookup{$SITE}{'rcsbin'}, $opt_debug);
$MAINLOG->infod("Checking out RCS contents to setup area...") if $opt_debug;
&RcsCo($MAINLOG, $mig_setup, $mig_lookup{$SITE}{'rcssetup'}, $opt_debug);
&ManipFile($MAINLOG, 'copy', $mig_input_process_src, $input_process_harvest_cif, basename($input_process_harvest_cif));
&ManipFile($MAINLOG, 'symlink', $mig_input_process_src, basename($input_process_harvest_cif), "${cell_lc}.cif");


# Search for override PDB files in users area and overwrite with existing files
$MAINLOG->infod("Searching for override PDB files...") if $opt_debug;
my $override_pdb_area = "$HOME/pdb";
if (-d $override_pdb_area) {
  opendir (OVERPDB, $override_pdb_area) or die $MAINLOG->fatalq("Could not open directory: $override_pdb_area");
  my @override_pdb_files = grep /\.pdb$/, readdir(OVERPDB);
  foreach my $file (@override_pdb_files) {
    &ManipFile($MAINLOG, 'copy', '', "${override_pdb_area}/${file}", "${mig_setup}/${file}");
    $MAINLOG->warn("Override PDB file copied from \$HOME/pdb: $file");
  }
  closedir (MIGSETUP);
}
					 

# Create work-(cell) environment
$MAINLOG->infod("Linking PDB files to migration work area...") if $opt_debug;
&ManipFile($MAINLOG, 'symlink', $mig_work, '../setup', 'setup');
&ManipFile($MAINLOG, 'symlink', $mig_work, '../bin', 'bin');
&ManipFile($MAINLOG, 'symlink', $mig_work, "../".basename($mig_input_process_src), 'src');
opendir (MIGSETUP, $mig_setup) or die $MAINLOG->fatalq("Could not open directory: $mig_setup");
my @fub_pdb_files = grep /fub.+\.pdb/, readdir(MIGSETUP);
closedir (MIGSETUP);
foreach my $file (@fub_pdb_files) {
  &ManipFile($MAINLOG, 'symlink', $mig_work, "../setup/${file}", "$file");
}

# Run 1264->1265 Conversion. Waiving TRCALT errors here; flow not guaranteed to be clean.
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Run $mig_input_process -> $mig_intermediate_process conversion/verify *****");
my $intermediate_process_harvest_stm = "${mig_work}/work-fub_harvest${mig_intermediate_process}/${cell_lc}.stm.fub_harvest${mig_intermediate_process}";
&DeleteFiles($intermediate_process_harvest_stm);
&Harvest1265($MAINLOG, $mig_work, "fub_harvest${mig_intermediate_process}.pdb");
unless (-f $intermediate_process_harvest_stm) {
  die $MAINLOG->fatalq("1265 harvest run did not produce output stm. See log file:", $MAINLOG->filename);
}
&ManipFile($MAINLOG, 'symlink', '', $intermediate_process_harvest_stm, $pds_stm);
$iss_header = "ISS TRCALT (STM-Harvest1265)";
$MAINLOG->infoq("Running ${iss_header}...");
$gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcalt', '', $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL');
    if ($rundirty) {
      if ($opt_ignorecmp) {
	$MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
      } else {
	$MAINLOG->warn("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
    }
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    if ($opt_ignorecmp) {
      $MAINLOG->warn("-ignorecmp detected. CMP run aborted but proceeding to next stage");
    } else {
      $MAINLOG->warn("$iss_header run ABORTED");
    }
  } else {
    die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
  }
} else {
  $MAINLOG->info("$iss_header run CLEAN");
}

my $intermediate_process_harvest_cif = "${mig_work}/result-fub_harvest1265/${cell_lc}.cif";
&ManipFile($MAINLOG, 'copy', $mig_intermediate_process_src, $intermediate_process_harvest_cif, "${cell_lc}.cif.${good_model}.${mig_intermediate_process}");
&ManipFile($MAINLOG, 'symlink', $mig_intermediate_process_src, "${cell_lc}.cif.${good_model}.${mig_intermediate_process}", "${cell_lc}.cif");
&ManipFile($MAINLOG, 'copy', $mig_src,  $intermediate_process_harvest_cif, "${cell_lc}.cif");
$MAINLOG->infoq("Final (${mig_intermediate_process}) harvest cif -> ${mig_intermediate_process_src}/${cell_lc}.cif.${good_model}.${mig_intermediate_process}");
$MAINLOG->infoq("$mig_intermediate_process CIF copied to /src area");



END:
$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");




##### Start subroutine definitions #####


# Fub is assumed to be the proper case (in this case, lower case)
sub ValidateFubExists {
  my $fub = shift;
  my $fubfile = "${WARD}/${BASEFILE}.check";
  my $foundfub = 0;
  my $fubquery; 
  
  $fubquery = "$PROJ_SKILL/gallery/bin/users_request/isFub.pl $PROJECT $fub";
  open (FUBQUERY, "$fubquery |") or die $MAINLOG->fatalq("Could not open fub query:", $fubquery);
  while (<FUBQUERY>) {
    if (/^\s*(\S+)\s+/) {
      if (($1 ne 'Block') and ($1 eq $fub)) {
	$foundfub = 1;
      }
      chomp;
      $MAINLOG->infoq("isFUB.pl Query: $_");
    }
  }
  close (FUBQUERY);
  unless ($foundfub) {
    die $MAINLOG->fatalq("fub=$fub is not a valid fub name");
  } 
}

sub GetConfigsFromModel {

  my $loghandle = shift;
  my $targetdbb = shift;
  my $cfgfile = shift;

  my @cfg_list;
  my $cfgfh = new IO::File;
  $cfgfh->open($cfgfile) or die $loghandle->fatalq("Could not open $cfgfile for reading");
  while (<$cfgfh>) {
    if (/${targetdbb}/) {
      my @record = split;
      my @dbb_list = split (/:/, $record[2]);
      foreach my $dbb (@dbb_list) {
        if ($dbb eq $targetdbb) {
          if ($record[0] =~ /${PROJECT}_(lay|sch|net)/) {
	    my $cfg_string = "$record[0] $record[1]";
	    push (@cfg_list, $cfg_string);
	  }
	}
      }
    }
  }
  $cfgfh->close();
  return (@cfg_list);
}


sub RecompileDmspath {

  my $loghandle = shift;
  my $dbb = shift;
  my $model = shift;
  my $newdmsfile = shift;
  my $newcdsfile = shift;

  my $options_string = join(' ', @_);
  
  my $parent_flow = $loghandle->flowname('RecompileDmspath');

  # Add proper variable path
  $DBB = $dbb;
  $MODEL = $model;
  unless (&Tcsh($MAINLOG, "(dmsCompiler_new.pl -dbtypes lay sch flp dev sim net ctl -createDms2opus $newcdsfile -outfile $newdmsfile $options_string) >& /dev/null")) {
    die $loghandle->fatalq('DMSPATH recompilation for target cell returned non-zero exit status');
  }
  # Confirm existance of new file. Its non-existance is an unexpected condition.
  unless (-e $newdmsfile) {
    die $MAINLOG->fatalq("New dmspth file: $newdmsfile was not created properly for dbb $dbb");
  }
  $loghandle->flowname($parent_flow);
}


sub RunNikeNetlister {

  my $loghandle = shift;
  my $cell = shift;
  my $inputformat = shift;
  my $outputformat = shift;
  my $other_args = join(' ', @_);
  my $outnetlist;
  my $outnetlistlog;
  my $summary_found = 0;
  my $fatal_count;
  my $error_count;
  my $warning_count;
  my $run_is_dirty = 0;
  
  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname('RunNikeNetlister');

  # Remove previous netlist (future: key off of input format);
  my $outputformat_ucf = ucfirst($outputformat);

  my $netlist_dir;
  my $sn_dir;
  if ($other_args =~ /\-outd (\S+)/) {
    $netlist_dir = $1;
    $sn_dir = $1;
  } else {
    $netlist_dir = "$WARD/netlists";
    $sn_dir = "$WARD/netlists/cvssch";
  }
 
  $outnetlistlog = "${netlist_dir}/${cell}__${inputformat}_to_${outputformat_ucf}__nike_netlister.log";
  $outnetlist = "${sn_dir}/${cell}.sn";
  &DeleteFiles($outnetlist, $outnetlistlog);

  # Nike netlister returns non-zero status if there are non-fatal issues with netlisting, as well as any process issues (like no disk space or wrong switches).
  # Since I don't know how to tell the difference, just check for the log file)
  unless (&Tcsh($loghandle, "$NIKE_NETLISTER -cell $cell -inf $inputformat -remp none -outf $outputformat $other_args >& /dev/null")) {
    $loghandle->warn('NIKE netlister call returned non-zero status.');
  }

  # Confirm there were no errors in the log file
  open (OUTNETLISTLOG, $outnetlistlog) or die $loghandle->fatalq("Could not open $outnetlistlog for reading");
  while (<OUTNETLISTLOG>) {
    if (/Fatals:\s+(\d+)\s+Errors:\s+(\d+)\s+Warnings:\s+(\d+)/) {
      $fatal_count = $1;
      $error_count = $2;
      $warning_count = $3;
      $summary_found = 1;
      chomp;
      $loghandle->infoq($_);
      last;
    }
  }
  close (OUTNETLISTLOG);

  if ($summary_found) {
    if (($fatal_count ne '0') or ($error_count ne '0')) {
      $loghandle->warnp("Fatals/errors occured during nike_netlister run.",
	       "See $outnetlistlog");
      $run_is_dirty = 1;
    }
    if ($warning_count ne '0') {
      $loghandle->warnp("Warnings occured during nike_netlister run.",
	   "See $outnetlistlog");
    }
  } else {
    die $loghandle->fatalq("Nike netlister log was found, but no summary was contained in file",
	     "See $outnetlistlog");
  }
  # Confirm output netlist was generated, die otherwise

  $loghandle->flowname($parent_flow);
  return $run_is_dirty;
}


sub GenesysOpenSession {

  my $genesyslog = shift;
  my $parentfh = select;  # Capture existing value
  my $genesys_cmd_line;

  local *GENESYSFH;

  $genesys_cmd_line = "$GENESYS_DIR/ConfigFiles/nike.wrapper $GENESYS_DIR/bin/genesys -nullgt";
  open (GENESYSFH, "| $genesys_cmd_line > $genesyslog 2>&1") or die
    $MAINLOG->fatalq("Could not open a pipe to Genesys");
  select(GENESYSFH);
  $| = 1;

  select($parentfh);
  return *GENESYSFH;
}


sub GenesysCloseSession {

  my $genesysfh = shift;
  my $parentfh = select($genesysfh);   

  print "quit\n";
  print "no\n";
  close ($genesysfh);
  select($parentfh);
}


sub GenesysTouchAndWaitForFile {

   my $flagfile = shift;
   my $genesysfh = shift;
   my $parentfh = select($genesysfh);

   if (-e $flagfile) {
     die $MAINLOG->fatalq("Flagfile detected before polling started:", $flagfile);
   }
   print "exec touch $flagfile\n";
   &PollForFile($flagfile);

   select($parentfh);
}


sub CheckGenesysPreProcess {

  my $loghandle = shift;
  my $genesyslog = shift;

  my $parent_flow = $loghandle->flowname('CheckGenesysPreProcess');

  open (GENESYSLOG, $genesyslog) or die $loghandle->fatalq("Could not open $genesyslog for reading");
  
  while (<GENESYSLOG>) {
    if (/markLanding:|getCellHeightWidth:|DELETED/) {
      chomp;
      $loghandle->infoq($_);
    }
    if (/invalid command name(.+)Baa/) {
      chomp;
      $loghandle->infoq($_);
      die $loghandle->fatalq("Problem occurred during LNF pre-processing. See Genesys log file:", $genesyslog);
    }
    if (/Error messages will be written to (GDSII\S+)\s+$/) {
      push (@TMPFILES, "${WARD}/${1}");
    }
  }
  close (GENESYSLOG);
  
  $loghandle->flowname($parent_flow);
}


# If you are not going to use readonly, you be
sub GenesysOpenCell {

   my $cell = shift;
   my $view = shift;
   my $path = shift;
   my $readonly = shift;
   my $genesysfh = shift;
   my $parentfh = select($genesysfh);
   my $path_with_flag;

   if (-e $path) {
     $path_with_flag = "-path ${path}/${cell}.${view}";
   } else {
     $path_with_flag = "";
   }

   if ($readonly) {
     print "\nRead -cellname $cell -viewname $view $path_with_flag\n";
   } else {
     print "\nOpen -cellname $cell -viewname $view $path_with_flag\n";
     # Just in case you try to use this without having all the data in a local library
     # Never did figure out what -noask does...
     # Flag this when commands get wrapped
     print "no\n";
   }
   select($parentfh);
}


sub GenesysDiscardAll {

  my $genesysfh = shift;
  my $parentfh = select($genesysfh);

  print "DiscardAll\n";
  print "yes\n";

  select($parentfh);
}


sub GenesysCommandLine {

  my $genesysfh = shift;
  my $genesys_command = shift;
  my $parentfh = select($genesysfh);

  print "\n$genesys_command\n";

  select($parentfh);
}


sub GenesysLoadModules {

  my $tcl_module_list_ref = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  my $tclfile;
  my $at_least_one_module_bad = 0;

  # Very dirty way for doing this right now...
  # Assume if the file exists it is OK
  foreach $tclfile (@{$tcl_module_list_ref}) {
    if (-e $tclfile) {
      print "source $tclfile\n";
    } else {
      $MAINLOG->fatalq("Could not load TCL module into Genesys:", $tclfile);
      my $at_least_one_module_bad = 1;
    }
  }
  if ($at_least_one_module_bad) {
    die $MAINLOG->fatalq("At least one TCL file not sourced properly into Genesys");
  }
  select($parentfh);
}


sub GenesysSaveAllWithPrefix {

  my $cell = shift;
  my $view = shift;
  my $prefix = shift;
  my $outdir = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  my $dir;
  my $expected_outfile;
  my $saveall_flag = "${WARD}/genesys/${BASEFILE}.saveall_flag";
  my $prefix_with_flag;

  &DeleteFiles($saveall_flag);
  push (@TMPFILES, $saveall_flag);
  if (&CreateDirTrees($outdir)) {
    die $MAINLOG->fatalq("Could not create directory for lnf save:", $outdir);
  }
  
  if ($prefix) {
    $prefix_with_flag = "-prefix $prefix";
  } else {
    $prefix_with_flag = "";
  }
  print "\nSaveAll -cellname $cell -dir $outdir -targetview $view $prefix_with_flag\n";
  &GenesysTouchAndWaitForFile($saveall_flag, $genesysfh);
  $expected_outfile = "${outdir}/${prefix}${cell}.${view}";
  unless (-e $expected_outfile) {
    die $MAINLOG->fatalq("Genesys output not written out. Expected:", $expected_outfile);
  }

  select($parentfh);
}


sub GenesysSaveStm {
  my $cell = shift;
  my $path = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  
  print "\nSaveAs -cellname $cell -viewname stm -convertToCuts -path ${path}/${cell}.stm\n";
  select ($parentfh);
}


sub GenerateCarFile {

  my $incarfile = shift;
  my $outcarfile = shift;
  my $strap_obj_found = 0;
  open (INCAR, $incarfile) or die $MAINLOG->fatalq("Could not open $incarfile for reading");
  open (OUTCAR, ">$outcarfile") or die $MAINLOG->fatalq("Could not open $outcarfile for writing");
  while (<INCAR>) {
    if (/name STRAP/) {
      $strap_obj_found = 1;
    }
    if ((/libMosfetStrapGen/) and ($strap_obj_found)){
      s/libMosfetStrapGen/libVContStrapGen/;
      $strap_obj_found = 0;
    }
    print OUTCAR $_;
  }
  close (INCAR);
  close (OUTCAR);
}






