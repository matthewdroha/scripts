#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: mkcif.pl,v 1.23 2006/02/25 02:11:15 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: mkcif.pl,v 1.23 2006/02/25 02:11:15 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: mkcif.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: This script accepts clean 1266 LNF as input and
generates a CIF file that can be used as input to the next migration stage.

This script performs the following tasks on the input fub/cell:

- Preps SN and LNF from work area or library
- Runs ISS TRCALT on cleaned data 
- Genesys pre-processing
  - LNF->GDSII Using Genesys
  - ISS TRCSTD (Genesys STM)
- GDSII->CIF
- CIF prep with new text option (old option also supported)
- CIF TRCALT verification

=cut


# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
  if (defined $ENV{'MIG_OVR'}) {
    push @INC, $ENV{'MIG_OVR'};
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

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Get the site
our $SITE = &GetSite();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
                  [-lnfdir <lnf directory>]
                  [-dbb <dbb name>] [-ignorecmp]
                  [-uemodel <UE model>] [-notext]
                  [-env 'VAR=VALUE']
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input cell name. SN file for this cell is expected in \$PDSSN

-lnfdir           Optional. Argument is directory. If not provided, LNF will be taken from $DMSPATH

-dbb              Optional. If not provided, default DBB is the cell name

-uemodel          Optional. If not provided, default model is current UE model

-notext           If used, original flow that strips all text from output CIF is used
                  In place of text, duplicate metal with proper naming is placed on terminsts

-env              Optional. Set env var at start of execution. Can have more than one -env
                  flag.

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend
         $EXE_NAME -cell bnsdcdtimer -dbb dccdatad -uemodel pshift2 -lnfdir ~ltamir/mylnf

Files that result from this run:

$WORK/mig/<cell>/src-mkcif/<cell>.mkcif.cif[.notext]

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_cell, $opt_lnfdir, $opt_dbb, $opt_uemodel, $opt_ignorecmp);
our ($opt_notext, @opt_env);
our ($opt_help, $opt_debug, $opt_verbose);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "lnfdir=s",
			     "dbb=s",
			     "uemodel=s",
			     "notext",
			     "env=s@",
			     "ignorecmp",
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
our ($HOME, $WORK_AREA_ROOT_DIR);
my @env_list = ('HOME', 'WORK_AREA_ROOT_DIR');

our ($DB_ROOT, $PROJECT, $GENESYS_DIR, $MODEL);
our ($DMSPATH, $DBB, $CDSLIB, $LM_LICENSE_FILE);
our ($GENESYS_MACROS);
@env_list = (@env_list, 'DB_ROOT', 'PROJECT', 'GENESYS_DIR', 'MODEL');
@env_list = (@env_list, 'DMSPATH', 'DBB', 'CDSLIB', 'LM_LICENSE_FILE');
@env_list = (@env_list, 'GENESYS_MACROS');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}

our ($TRANSIENT_PSE_DB, $USERCFGFILE);
&Env::import('TRANSIENT_PSE_DB', 'USERCFGFILE');

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


# Set any command line env vars
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


# Make sure we can't mess with the ATF database
$ENV{'ATF_LOCKED'} = 'YES';

# We have to mess with the license path a bit later on. The US Sagantec licenses don't
# support stream sts754.
my $orig_lic_path = $LM_LICENSE_FILE;


my $uemodel;
if ($opt_uemodel) {
  $uemodel = $opt_uemodel;
} else {
  $uemodel = $MODEL;
}

my $dbb;
if ($opt_dbb) {
  $dbb = $opt_dbb;
} else {
  $dbb = $cell_lc;
}


my $stage = 1;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Prepping SN and LNF *****");

my $sn_file = "${PDSSN}/${cell_lc}.sn";
unless (-e $sn_file) {
  $MAINLOG->fatalq("SN file does not exist: $sn_file");
}

my ($name,$path,$suffix) = fileparse($sn_file);
my $resolved_path = abs_path($path);
$sn_file = "${resolved_path}/${name}"; 

if (-e $sn_file) {
  $MAINLOG->infoq("Using SN file: $sn_file");
} else {
  die $MAINLOG->fatalq("SN file does not exist: $sn_file");
}


# Create lnf snapshot area. LNFs in -lnfdir have the highest precendence
my @source_dirs;
my $lnfdir;
if ($opt_lnfdir) {
  if (-d $opt_lnfdir) {
    $lnfdir = abs_path($opt_lnfdir);
    push @source_dirs, $lnfdir;
  } else {
    die $MAINLOG->fatalq("Directory provided by -lnfdir is non existent: $lnfdir");
  }
}

my $lnf_snapshot_dir = "${WARD}/genesys/lnf/${cell_lc}_${EXE_PREFIX}_lnf";
&CreateDirTrees($lnf_snapshot_dir);

push @source_dirs, "${WARD}/genesys/lnf";
foreach my $sourcedir (@source_dirs) {
  unless (-d $sourcedir) {
    die $MAINLOG->fatalq("Directory does not exist: $sourcedir");
  }
  my @files_copied = &CopyFilesToDir($MAINLOG, '\.lnf$', $sourcedir, $lnf_snapshot_dir);
  my $file_count = scalar @files_copied;
  foreach my $file (@files_copied) {
    $MAINLOG->infoq("File copied: ($file) from $sourcedir");
  }
  if ($file_count == 0) {
    $MAINLOG->info("$file_count override LNF files found in $sourcedir");
  } else {
    $MAINLOG->warn("$file_count override LNF files found in $sourcedir");
  }
}


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Recompiling DMSPATH *****");
if ($USERCFGFILE) {
  $MAINLOG->warn("User cfg file detected. Will be included in recompile: $USERCFGFILE");
}
my $origdmspath = "${WORK_AREA_ROOT_DIR}/${BASEFILE}.dms.pth.orig";
&ManipFile($MAINLOG, 'copy', '.', $DMSPATH, $origdmspath);
push(@TMPFILES, $origdmspath);
my $newdmspath = "${WORK_AREA_ROOT_DIR}/${BASEFILE}.dms.pth";
push(@TMPFILES, $newdmspath);
my $newdmsmodes = "${WORK_AREA_ROOT_DIR}/${BASEFILE}.dms.pth.modes";
push(@TMPFILES, $newdmsmodes);
my $newcdslib = "${WORK_AREA_ROOT_DIR}/${BASEFILE}.cds.lib";
push(@TMPFILES, $newcdslib);
&RecompileDmspath($MAINLOG, $dbb, $uemodel, $newdmspath, $newcdslib);
$DMSPATH = $newdmspath;
$CDSLIB = $newcdslib;

# Hack in genesys lnf dir into DMSPATH
open (DMSPATH, $DMSPATH) or die $MAINLOG->fatalq("Could not open $DMSPATH for reading");
my $tempdms = "${WARD}/${BASEFILE}.dms.pth.presnapshot";
push(@TMPFILES, $tempdms);
open (TEMPDMS, ">$tempdms") or die $MAINLOG->fatalq("Could not open $tempdms for writing");
my $isstools_section = 0;
my $genesys_section = 0;
while (<DMSPATH>) {
  if (/DMS PATH FOR TOOL: isstools/) {
    $isstools_section = 1;
  }
  if (/DMS PATH FOR TOOL: genesys/) {
    $genesys_section = 1;
  }
  if ($isstools_section) {
    if (/\$WORK_AREA_ROOT_DIR\/layout/) {
      s/\$WORK_AREA_ROOT_DIR\/layout/$lnf_snapshot_dir/;
    }
    if (/libpath/) {
      $isstools_section = 0;
    }
  }
  if ($genesys_section) {
    if ((/\$WORK_AREA_ROOT_DIR\/genesys\/lnf/) and (!(/\lnfbackup/))) { 
      s/\$WORK_AREA_ROOT_DIR\/genesys\/lnf/$lnf_snapshot_dir/;
    }
    if (/libpath/) {
      $genesys_section = 0;
    }
  }
  print TEMPDMS $_;
}
close (DMSPATH);
close (TEMPDMS);
&ManipFile($MAINLOG, 'copy', '', $tempdms, $DMSPATH);


# Set the working directory to WARD
chdir ($WARD) or die "-E- $EXE_NAME: Could not change script working dir to $WARD\n";



# Run PDS TRCALT on original LNF
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: ISS TRCALT on original LNF data *****");

my $iss_header = "ISS TRCALT (LNF-Original)";
$MAINLOG->infoq("Running ${iss_header}...");
my $gdsintp = 0;
my ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'lnf', 'trcalt', '', $gdsintp);
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
      $MAINLOG->info("$iss_header run CLEAN-WAIVED");
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
#undef $TRANSIENT_PSE_DB;
$TRANSIENT_PSE_DB = 1;

# Exclude the nasty polygons that exist on the keepout layers
my %tech_table;
my @layers_to_exclude_from_genesys_stm;
my @layers_to_delete_from_genesys_memory;
&ReadDTTechFile($MAINLOG, $pds_lookup{$SITE}{"niketech${mig_output_process}"}, \%tech_table, $opt_debug);
my @layer_list = sort ((keys %{ $tech_table{'MODTECH'} }), 'WIREPOLYKEEPOUT');
foreach my $layer (@layer_list) {
  if ($layer =~ /OVZ$/) {
    push (@layers_to_exclude_from_genesys_stm, lc($layer));
    $MAINLOG->infoq("The following layer will be excluded from Genesys stm file: $layer");
  }
  if ($layer =~ /KEEPOUT$/) {
    if ($opt_notext) {
      push (@layers_to_exclude_from_genesys_stm, lc($layer));
      $MAINLOG->infoq("The following layer will be excluded from Genesys stm file: $layer");
    } else {
      push (@layers_to_delete_from_genesys_memory, lc($layer));
      $MAINLOG->infoq("The following layer will be deleted from Genesys memory: $layer");
    }
  }
}


# Open Genesys session
my $genesyslog = "${WARD}/${BASEFILE}.genesyslog";
my $genesysfh = &GenesysOpenSession($genesyslog);
#&GenesysCloseSession($genesysfh);
#exit;

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

if ($opt_notext) {
  &GenesysCommandLine($genesysfh, 'stm outputTermInsts 1');
} else {
  &GenesysCommandLine($genesysfh, 'stm outputTermInsts 0');
  &GenesysCommandLine($genesysfh, 'stm forcedTermInstLabels 1');
}


# Preprocess LNF files
my $readonly = 1;
&GenesysOpenCell($cell_lc, 'lnf', '', $readonly, $genesysfh);
my @target_tcl_modules_list = (@mig_tcl_modules_list, "${GENESYS_MACROS}/Hwireless_ports.tcl");
@target_tcl_modules_list = (@target_tcl_modules_list, "${GENESYS_MACROS}/detox.tcl");
@target_tcl_modules_list = (@target_tcl_modules_list, "${GENESYS_MACROS}/pwrUtils.tcl");
&GenesysLoadModules(\@target_tcl_modules_list, $genesysfh);
unless ($opt_notext) {
  foreach my $layer (@layers_to_delete_from_genesys_memory) {
    #&GenesysCommandLine($genesysfh, "::mig::deleteLayer $layer");
    &GenesysCommandLine($genesysfh, "::mig::deleteKOR $layer");
  }
}
&GenesysCommandLine($genesysfh, 'defeatReadOnly');
&GenesysCommandLine($genesysfh, '::Hwireless_ports::Hwireless_ports');
&GenesysCommandLine($genesysfh, '::pwrUtils::rmTdbuHier');
&GenesysCommandLine($genesysfh, '::mig::runCmdDepthFirst "::detox::fix_PortNoMet"');
&GenesysCommandLine($genesysfh, '');
&GenesysCommandLine($genesysfh, '::mig::markTermInsts') unless $opt_notext;
&GenesysCommandLine($genesysfh, '::mig::getCellHeightWidth');


# Save snapshot of LNF data
&GenesysSaveAllWithPrefix($cell_lc, 'lnf', '', $lnf_snapshot_dir, $genesysfh);
&GenesysCommandLine($genesysfh, 'DiscardAll -noask');
&GenesysOpenCell($cell_lc, 'lnf', '', $readonly, $genesysfh);
&GenesysSaveStm($cell_lc, "$WARD/genesys/stm", $genesysfh);

# Close session and check output
&GenesysCloseSession($genesysfh);
&CheckGenesysPreProcess($MAINLOG, $genesyslog);
if (-e $genesys_stm) {
  my @stat_list = stat($genesys_stm);
  if ($stat_list[7] == 0) {
    die $MAINLOG->fatalq("Genesys created a 0 length stm file in pds/stream. See genesys log: $genesyslog");
  }
} else {
  die $MAINLOG->fatalq("Stm file from Genesys not generated:", $genesys_stm);
}



# Move stm file to PDS area for ISS
my $genesys_stm_rename = "${PDSSTM}/${BASEFILE}.stm.genesys";
push(@TMPFILES, $genesys_stm_rename);
my $pds_stm = "${PDSSTM}/${cell_lc}.stm";
push(@TMPFILES, $pds_stm);   # In the flow this file is a link
&DeleteFiles($pds_stm);
&ManipFile($MAINLOG, 'copy', '', $genesys_stm, $genesys_stm_rename);
&ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($genesys_stm_rename), basename($pds_stm));


# Run PDS TRCALT on stm from Genesys
$iss_header = "ISS TRCALT (STM-Genesys)";
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
	die $MAINLOG->fatalq("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->info("$iss_header run CLEAN-WAIVED");
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


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: CIF Generation And Verification  *****");
$MAINLOG->infoq("Building layconv map file (input to mulitprop clean layconv runs)");
&ReadPdbFile($MAINLOG, $mig_lookup{$SITE}{"pdb${mig_output_process}"}, \%tech_table, $opt_debug);
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
$MAINLOG->infoq("Converting raw Genesys STM to CIF with all $mig_output_process layers (multiprop clean)...");
my $genesys_cif = "${PDSSTM}/${cell_lc}.cif.genesys";
push(@TMPFILES, $genesys_cif);
&SagantecLayconv($MAINLOG, $pds_stm, 'stm', $genesys_cif, 'cif', $mig_lookup{$SITE}{"pdb${mig_output_process}"}, "-a  $mapfile");


my $cif_for_lnftomig = "${PDSSTM}/${cell_lc}.cif.input_for_lnftomig";

# If -notext is specified, no text will be in CIF. Additional metal will be added to preserve
# proper naming
if ($opt_notext) {
  # Re-write GDSII with only PDB layers
  $MAINLOG->infoq("Converting Genesys CIF to STM, $mig_output_process PDB layers only...");
  my $essential_layer_stm = "${PDSSTM}/${cell_lc}.stm.essential_layers";
  push(@TMPFILES, $essential_layer_stm);
  &SagantecLayconv($MAINLOG, $genesys_cif, 'cif', $essential_layer_stm, 'stm', $mig_lookup{$SITE}{"pdb${mig_output_process}"}, '-w');
  
  # Re-convert to CIF with only required layers
  $MAINLOG->infoq("Converting essential layer STM to CIF...");
  my $essential_layer_cif = "${PDSSTM}/${cell_lc}.cif.essential_layers";
  push(@TMPFILES, $essential_layer_cif);
  &SagantecLayconv($MAINLOG, $essential_layer_stm, 'stm', $essential_layer_cif, 'cif', $mig_lookup{$SITE}{"pdb${mig_output_process}"}, '');

  # Strip syn net properties from CIF
  $MAINLOG->infoq("Stripping syn net properties from CIF...");
  my $nosyn_cif = "${PDSSTM}/${cell_lc}.cif.nosyn";
  push(@TMPFILES, $nosyn_cif); 
  &SagPerlCifIO($MAINLOG, 'StripSynPropsFromCif', $cell_lc, $essential_layer_cif, $nosyn_cif);

  # Strip all text from CIF file
  $MAINLOG->infoq("Stripping Text From CIF to generate $mig_output_process harvest CIF...");
  my $notext_cif = "${PDSSTM}/${cell_lc}.cif.notext";
  &SagPerlCifIO($MAINLOG, 'StripTextFromCif', $cell_lc, $nosyn_cif, $notext_cif);

  &ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($notext_cif), basename($cif_for_lnftomig));


# If standard mode is used, then text based flow will be used. Here, all port geometries are
# stripped from the final output. Port text and metal text over terminsts are preserved.
} else {

  my @mask_layers = ('vpoly', 'TCN', 'GCN', 'metal1', 'metal2', 'metal3', 'metal4', 'metal5', 'metal6', 'metal7', 'metal8');

  my @port_layers;
  my @topport_marker_layers;

  foreach my $layer (@mask_layers) {
    push (@port_layers, "${layer}_portDrawing");
    push (@topport_marker_layers, "${layer}keepout");
  }
  
  # Remap poly, diffcon, and polycon KO layers to vpoly, TCN, and GCN names
  my $ko_remap_cif = "${PDSSTM}/${cell_lc}.cif.ko_remap";
  push(@TMPFILES, $ko_remap_cif);
  &SagPerlCifIO($MAINLOG, 'ChangeLayerNamesInCif', $cell_lc, $genesys_cif, $ko_remap_cif, 'polykeepout:vpolykeepout', 'diffconkeepout:TCNkeepout', 'polyconkeepout:GCNkeepout');

  # Generate port properties on real routing layers that intersect with the port layers.
  # The new geometry represents the new port.
  my $portprop_cif = "${PDSSTM}/${cell_lc}.cif.portproperties";
  push(@TMPFILES, $portprop_cif);
  &SagPerlCifIO($MAINLOG, 'GeneratePortPropsInCif', $cell_lc, $ko_remap_cif, $portprop_cif, @mask_layers);

  # Merge ports and also merge keepout layer markers. Push text properties onto these new
  # merged structures.
  # For US, switch LM_LICENSE_FILE to IDC Sagantec path; US licenses don't exist for sts754
  $LM_LICENSE_FILE = $idc_lic_path;
  my $portmerge_cif = "${PDSSTM}/${cell_lc}.cif.mergedport";
  push(@TMPFILES, $portmerge_cif);
  &Polar($MAINLOG, $portprop_cif, $portmerge_cif, $mig_pdb_file, 'merge_ports_1266');

  # Strip text to prepare for text re-generation
  my $notext_cif = "${PDSSTM}/${cell_lc}.cif.mergedport_notext";
  push(@TMPFILES, $notext_cif);
  #&Polar($MAINLOG, $portmerge_cif, $notext_cif, $mig_pdb_file, 'delete_text_1266');
  &SagPerlCifIO($MAINLOG, 'StripTextFromCif', $cell_lc, $portmerge_cif, $notext_cif);

  # Move 'text' property from Polar to gdsprop 126
  my $gds126_cif = "${PDSSTM}/${cell_lc}.cif.texttogds126";
  push(@TMPFILES, $gds126_cif);
  &SagPerlCifIO($MAINLOG, 'ConvertTextPropToGds126', $cell_lc, $notext_cif, $gds126_cif);

  # Regenerate text for merged port/KO layers.
  my $reduced_kotext_cif = "${PDSSTM}/${cell_lc}.cif.reduced_kotext";
  push(@TMPFILES, $reduced_kotext_cif);
  &SagPerlCifIO($MAINLOG, 'GenerateTextInCif', $cell_lc, $gds126_cif, $reduced_kotext_cif, @port_layers,  @topport_marker_layers);


  # Map the keepout layer text to real metal text
  my $reduced_text_cif = "${PDSSTM}/${cell_lc}.cif.reduced_text";
  push(@TMPFILES, $reduced_text_cif);
  &SagPerlCifIO($MAINLOG, 'CopyKeepoutTextToMetalText', $cell_lc, $reduced_kotext_cif, $reduced_text_cif);

  # Strip the port polygons from database
  my $ports_removed_cif = "${PDSSTM}/${cell_lc}.cif.port_plys_removed";
  push(@TMPFILES, $ports_removed_cif);
  &SagPerlCifIO($MAINLOG, 'StripPolygonsFromCif', $cell_lc, $reduced_text_cif, $ports_removed_cif, @port_layers);

  # Keep only essential layers in the CIF
  my @delete_layers;
  open (MAPFILE, $mapfile) or die $MAINLOG->fatalq("Could not open layconv map file for reading: $mapfile");
  while (<MAPFILE>) {
    if (/^\s*(\S+)\s+\d+\s+\d+/) {
      push(@delete_layers, $1);
    }
  }
  my $textports_cif = "${PDSSTM}/${cell_lc}.cif.textports";
  # Some redundancy with the topport marker layers, but the dt tech file has
  # diffcon while the master PDB has TCN, etc...
  &SagPerlCifIO($MAINLOG, 'StripLayersFromCif', $cell_lc, $ports_removed_cif, $textports_cif, @delete_layers, @topport_marker_layers);
  $LM_LICENSE_FILE = $orig_lic_path;

  &ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($textports_cif), basename($cif_for_lnftomig));
 


  # Convert the cif slated for LnfToMig.csh to stm and run TRCALT one more time

  my $cif_for_lnftomig_retexted = "${PDSSTM}/${cell_lc}.cif.input_for_lnftomig_retexted";
  push(@TMPFILES, $cif_for_lnftomig_retexted);
  &SagPerlCifIO($MAINLOG, 'GenerateTextInCif', $cell_lc, $cif_for_lnftomig, $cif_for_lnftomig_retexted);

  my $stm_for_lnftomig = "${PDSSTM}/${cell_lc}.stm.input_for_lnftomig_retexted";
  push(@TMPFILES, $stm_for_lnftomig);
  &SagantecLayconv($MAINLOG, $cif_for_lnftomig_retexted, 'cif', $stm_for_lnftomig, 'stm', $mig_lookup{$SITE}{"pdb${mig_output_process}"}, '-w');
  &ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($stm_for_lnftomig), basename($pds_stm));
  
  $iss_header = "ISS TRCALT (STM-InputForLnfToMig)";
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
	  die $MAINLOG->fatalq("$iss_header run DIRTY");
	}
      } else {
	$MAINLOG->info("$iss_header run CLEAN-WAIVED");
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
}


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Run/Verify LnfToMig.csh  *****");
my $mig_ue_area = "$WORK_AREA_ROOT_DIR/mig";
my $mig_auxiliaries = "${mig_ue_area}/${cell_lc}/auxiliaries";
my $mig_bin = "${mig_ue_area}/${cell_lc}/bin";
my $mig_setup = "${mig_ue_area}/${cell_lc}/setup";
my $mig_src = "${mig_ue_area}/${cell_lc}/src";
my $mig_work = "${mig_ue_area}/${cell_lc}/work-${cell_lc}-preMigration";
&CreateDirTrees($mig_ue_area, $mig_auxiliaries, $mig_bin, $mig_setup, $mig_src);
$MAINLOG->infoq("Checking out RCS contents to bin area...");
&RcsCo($MAINLOG, $mig_bin, $mig_lookup{$SITE}{'rcsbin'}, $opt_debug);
$MAINLOG->infoq("Checking out RCS contents to setup area...");
&RcsCo($MAINLOG, $mig_setup, $mig_lookup{$SITE}{'rcssetup'}, $opt_debug);
if (-e "${mig_src}/${cell_lc}.cif") {
  &ManipFile($MAINLOG, 'move', $mig_src, "${cell_lc}.cif", "${cell_lc}.cif.bak");
}
&ManipFile($MAINLOG, 'copy', $mig_src, $cif_for_lnftomig, basename($cif_for_lnftomig));
&ManipFile($MAINLOG, 'symlink', $mig_src, basename($cif_for_lnftomig), "${cell_lc}.cif");



chdir ("${mig_ue_area}/${cell_lc}") or die $MAINLOG->fatalq("Could not change directory to mig area:", "${mig_ue_area}/${cell_lc}");
my $prepcmd = "${mig_bin}/LnfToMig.csh $cell_lc";
$LM_LICENSE_FILE = $idc_lic_path;
my @stdout_and_err_ref;
&Pipe($MAINLOG, $prepcmd, '', \@stdout_and_err_ref); 
my $preplog = "${mig_work}/${cell_lc}.log";
$MAINLOG->infoq("LnfToMig.csh log file: $preplog");
$LM_LICENSE_FILE = $orig_lic_path;

my $cif_for_mig = "${mig_work}/result-for_MIGRATION/${cell_lc}.cif";
unless (-e $cif_for_mig) {
  die $MAINLOG->fatalq("LnfToMig did not generate expected CIF:", $cif_for_mig);
}

my $cif_for_mig_stm = "${mig_work}/work-preMigration/${cell_lc}.stm.preMigration_symlib";
&ManipFile($MAINLOG, 'copy', $PDSSTM, $cif_for_mig_stm, basename($cif_for_mig_stm));
&ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($cif_for_mig_stm), basename($pds_stm));


chdir ($WARD) or die $MAINLOG->fatalq("Could not change directory to $WARD");

$iss_header = "ISS TRCALT (STM-LnfToMig.csh)";
$MAINLOG->info("Running $iss_header...");
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
	die $MAINLOG->fatalq("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->info("$iss_header run CLEAN-WAIVED");
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


$iss_header = "ISS TRCSTD (STM-LnfToMig.csh)";
$MAINLOG->info("Running $iss_header...");
$gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcstd', '', $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort, 'ZL', 'OPENS', 'SUBCELLPIN');
    if ($rundirty) {
      if ($opt_ignorecmp) {
	$MAINLOG->warn("-ignorecmp detected. CMP run dirty but proceeding to next stage");
      } else {
	die $MAINLOG->fatalq("$iss_header run DIRTY");
      }
    } else {
      $MAINLOG->info("$iss_header run CLEAN-WAIVED");
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


$MAINLOG->newline;

my $final_cif = "${PDSSTM}/${cell_lc}.cif.mkcif_results";
&ManipFile($MAINLOG, 'symlink', $PDSSTM, "../../mig/${cell_lc}/work-${cell_lc}-preMigration/result-for_MIGRATION/${cell_lc}.cif", basename($final_cif));
my $final_stm = "${PDSSTM}/${cell_lc}.stm.mkcif_results";
&ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($cif_for_mig_stm), basename($final_stm));
$MAINLOG->infoq("CIF ready for next migration stage: $cif_for_mig");

&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");




##### Start subroutine definitions #####

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
  unless (&Tcsh($MAINLOG, "$DMSMODE > ${newdmsfile}.modes")) {
    die $loghandle->fatalq('DMSMODE generation returned non-zero exit status');
  }
  if ($ENV{'USERCFGFILE'}) {
    $options_string .= " -usercfgfile $ENV{'USERCFGFILE'}";
  }
  unless (&Tcsh($MAINLOG, "(dmsCompiler_new.pl -dbtypes lay sch flp dev sim net ctl -createDms2opus $newcdsfile -outfile $newdmsfile $options_string) >& /dev/null")) {
    die $loghandle->fatalq('DMSPATH recompilation for target cell returned non-zero exit status');
  }
  # Confirm existance of new file. Its non-existance is an unexpected condition.
  unless (-e $newdmsfile) {
    die $MAINLOG->fatalq("New dmspth file: $newdmsfile was not created properly for dbb $dbb");
  }
  $loghandle->flowname($parent_flow);
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


sub CheckGenesysPreProcess {

  my $loghandle = shift;
  my $genesyslog = shift;

  my $parent_flow = $loghandle->flowname('CheckGenesysPreProcess');

  open (GENESYSLOG, $genesyslog) or die $loghandle->fatalq("Could not open $genesyslog for reading"
);
  
  while (<GENESYSLOG>) {
    if (/getCellHeightWidth/) {
      chomp;
      $loghandle->infoq($_);
    }
    if (/invalid command name(.+)Baa/) {
      chomp;
      $loghandle->infoq($_);
      die $loghandle->fatalq("Problem occurred during LNF pre-processing. See Genesys log file:", $
genesyslog);
    }
    if (/Error messages will be written to (GDSII\S+)\s+$/) {
      push (@TMPFILES, "${WARD}/${1}");
    }
  }
  close (GENESYSLOG);
  
  $loghandle->flowname($parent_flow);
}
