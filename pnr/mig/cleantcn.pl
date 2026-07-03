#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: cleantcn.pl,v 1.2 2005/09/08 19:17:02 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: cleantcn.pl,v 1.2 2005/09/08 19:17:02 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: cleantcn.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Throw-away code to remove poly touching TCN on post SiClone CIF. Output is LNF data.

=cut


# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
  our %mig_utils;
  $mig_utils{'iil'} = "/nfs/iil/disks/home10/mroha/pnr/mig";
  $mig_utils{'fm'} = "/usr/users/home2/mroha/pnr/mig";
  push @INC, values %mig_utils;
}
our %mig_utils;

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
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
usage:  $EXE_NAME -cell <input cell> -relmodel <release model name>
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input cell name

-relmodel         Migration release model. Will be searched for in release area

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 



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
our ($opt_cell, $opt_relmodel, $opt_debug, $opt_verbose, $opt_help);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "relmodel=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell', '-relmodel');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####


# Capture initial environment variables
our ($HOME, $WORK_AREA_ROOT_DIR, $OVERRIDE_WORK_DIR, $AREA_NAME, $PROCESS_NAME);
my @env_list = ('WORK_AREA_ROOT_DIR', 'OVERRIDE_WORK_DIR', 'AREA_NAME', 'PROCESS_NAME');
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


# Set the working directory to WARD
chdir ($WARD) or die "-E- $EXE_NAME: Could not change script working dir to $WARD\n";


# Copy input SN and CIF file from release dir
$release_area = "/nfs/iil/proj/mpg/mpg14/pnrmig/mig_data/idc";

my $rel_lnf_dir = "${release_area}/${opt_relmodel}/lnf/${cell_lc}_siclone_cleaned_lnf_1266";
my $rel_sn_dir = "${release_area}/${opt_relmodel}/sn";

unless (-e $rel_lnf_dir) {
  die $MAINLOG->fatalq("Could not find LNF area from -relmodel: $rel_lnf_dir");
}

unless (-e $rel_sn_dir) {
  die $MAINLOG->fatalq("Could not find SN area from -relmodel: $rel_sn_dir");
}

opendir (RELSN, $rel_sn_dir) or die $MAINLOG->fatalq("Could not open SN $release dir: $rel_sn_dir");
@files = grep /${cell}\.sn.+\.nobonus/, readdir(RELSN);
unless (scalar @files == 1) {
  die $MAINLOG->fatalq("Picked up extra SN file somehow: $cell_lc  $opt_relmodel");
}
&ManipFile($MAINLOG, 'copy', $PDSSN, "${rel_sn_dir}/$files[0]", "${cell_lc}.sn");

my $genesys_lnf = "${WARD}/genesys/lnf";
my $files_copied_count = &CopyFilesToDir($MAINLOG, '.lnf$', $rel_lnf_dir, $genesys_lnf);
unless ($files_copied_count) {
  die $MAINLOG->fatalq("Could not copy LNF files to storage dir: $genesys_lnf_snapshot");
}


# Generate CIF with TCN processing
# Generate migration area for prop_to_text.csh
# Run prop_to_text.csh
# Run ISS on new STM (original stm guaranteed clean from release)
# Generate LNF data
# Run ISS on new LNF data
# Generate LNF release area



&ManipFile($MAINLOG, 'symlink', $PDSSTM, basename($gentext_stm), basename($pds_stm));

my $iss_header = "ISS TRCSTD (STM-GeneratedFrom1264CIF)";
$MAINLOG->infoq("Running ${iss_header}...");
my $gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcstd', '', $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort);
    if ($rundirty) {
      die $MAINLOG->fatalq("$iss_header run DIRTY");
    } else {
      $MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
    }
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    die $MAINLOG->fatalq("$iss_header run ABORTED");
  } else {
    die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
  }
} else {
  $MAINLOG->info("$iss_header run CLEAN");
}


my $input_process_harvest_cif = "${PDSSTM}/${cell_lc}.cif.${good_model}.${mig_input_process}";
&ManipFile($MAINLOG, 'copy', '', $notext_cif, $input_process_harvest_cif);
$MAINLOG->infoq("Final (${mig_input_process}) harvest cif -> $input_process_harvest_cif");


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
my $mig_env_file = $fub_env_file;

my %mig_env_table;
&ReadEnvironmentFile($MAINLOG, $mig_env_file, \%mig_env_table);
$force_set_env = 0;   # Want to use any mig env vars already set in environment
&SetEnvironment($MAINLOG, \%mig_env_table, $force_set_env, 1);
$ENV{'fub'} = $cell_lc;

my $mig_ue_area = "$WORK_AREA_ROOT_DIR/mig";
my $mig_auxiliaries = "${mig_ue_area}/${cell_lc}/auxiliaries";
my $mig_input_process_src = "${mig_ue_area}/${cell_lc}/src-${mig_input_process}";
my $mig_intermediate_process_src = "${mig_ue_area}/${cell_lc}/src-${mig_intermediate_process}";
my $mig_src = "${mig_ue_area}/${cell_lc}/src";
my $mig_bin = "${mig_ue_area}/${cell_lc}/bin";
my $mig_setup = "${mig_ue_area}/${cell_lc}/setup";
my $mig_work = "${mig_ue_area}/${cell_lc}/work-${cell_lc}-harvest";
&CreateDirTrees($mig_ue_area, $mig_auxiliaries, $mig_bin, $mig_setup, $mig_work);
&CreateDirTrees($mig_input_process_src, $mig_intermediate_process_src, $mig_src);


my $rcs_bin = "/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/process/p1266/bin/RCS";
my $rcs_setup = "/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/process/p1266/setup/RCS";
$MAINLOG->infod("Checking out RCS contents to bin area...") if $opt_debug;
&RcsCo($MAINLOG, $mig_bin, $rcs_bin, $opt_debug);
$MAINLOG->infod("Checking out RCS contents to setup area...") if $opt_debug;
&RcsCo($MAINLOG, $mig_setup, $rcs_setup, $opt_debug);
&ManipFile($MAINLOG, 'copy', $mig_input_process_src, $input_process_harvest_cif, basename($input_process_harvest_cif));
&ManipFile($MAINLOG, 'symlink', $mig_input_process_src, basename($input_process_harvest_cif), "${cell_lc}.cif");


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

# Run 1264->1265 Conversion
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
$iss_header = "ISS TRCALT1266 (STM-Harvest1265)";
$MAINLOG->infoq("Running ${iss_header}...");
$gdsintp = 0;
($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcalt1266', '', $gdsintp);
if ($rundirty) {
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $MAINLOG->warn("$iss_header run was dirty. Checking if TRC/CMP errors can be waived...");
    $rundirty = &WaiveTrcCmpErrors($MAINLOG, $pds_sum_or_abort);
    if ($rundirty) {
      $MAINLOG->warn("$iss_header run DIRTY");
    } else {
      $MAINLOG->infoq("$iss_header run CLEAN-WAIVED");
    }
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    die $MAINLOG->fatalq("$iss_header run ABORTED");
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
  my $cell = shift;
  my $cfgfile = shift;

  my $sch_cfg = '';
  my $lay_cfg = '';
  my $cfgfh = new IO::File;
  $cfgfh->open($cfgfile) or die $MAINLOG->fatalq("Could not open $cfgfile for reading");
  while (<$cfgfh>) {
    if (/^\s*${cell_lc}_${PROJECT}_lay\s+(\S+)/) {
      $lay_cfg = $1;
    }
    if (/^\s*${cell_lc}_${PROJECT}_sch\s+(\S+)/) {
      $sch_cfg = $1;
    }
  }
  $cfgfh->close();
  return ($sch_cfg, $lay_cfg);
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

