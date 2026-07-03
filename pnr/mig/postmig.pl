#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: postmig.pl,v 1.8 2005/01/18 13:17:04 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  postmig.pl			Project: Penryn
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* (C) Copyright Intel Corporation, 2004
#* Licensed material -- Program property of Intel Corporation
#* All Rights Reserved
#*
#* This program is the property of Intel Corporation and is furnished
#* pursuant to a written license agreement. It may not be used, reproduced,
#* or disclosed to others except in accordance with the terms and conditions
#* of that agreement.
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Original Author: Matthew Roha 
#*
#* Functional description:
#*
#* This script performs the following tasks on the input fub/cell:
#*
#* - Fetches appropriate input STM and SN data for run
#* - Extracts cell height/width
#* - Runs PDS on the fillGate and nofillGate stm files
#* - Runs PIE (not implimented yet)
#* - Runs PDS on the fillGate and nofillGate lnf files (no implimented yet)
#* 
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# Disable command buffering 
$| = 1;


# Define standard libs used

# Temporary until we get a central release area built
use strict;
use warnings;
use English;
use File::Basename;
use File::Copy;
use File::Path;
use Getopt::Long;
use Time::Local;
use Cwd 'chdir';
use Cwd 'abs_path';
use Cwd 'cwd';


# Set up exception handling
$SIG{'INT'}  = \&ExceptionHandler;
$SIG{'TERM'} = \&ExceptionHandler;


# Get script name
use vars qw($EXE_NAME $BASE_EXE_NAME);
$EXE_NAME = basename($0);
($BASE_EXE_NAME) = split(/\./,$EXE_NAME);


# Get the script start time
use vars qw($START_TIME);
$START_TIME = &GetDate;


# Assign a variable ($SPACER) for the spacing in output lines that
# overlap the first line. For example:
# -E- startascript.pl:  You had an error and the spacer variable will
#                       help your formatting like in this case.
# <---- ($SPACER) ---->
use vars qw($SPACER);
my $length = length($EXE_NAME);
$SPACER = " " x 5 . " " x $length;

# Debug string in log file if debug option used
use vars qw ($DEBUG_STRING);
$DEBUG_STRING = '[DEBUG]';


# Set the following perl varables to their parent shell counterparts 
use vars qw($WORK_AREA_ROOT_DIR $DMSPATH $PDSPATH $PDSSN $GENESYS);
use vars qw($PDSSTM $PROCESS_NAME $SAGROOT $CAD_ROOT $UESITE $USER);
use vars qw($PDSLOGS $GENESYS_DIR $PDSWORKROOT);
my @env_list = ('WORK_AREA_ROOT_DIR', 'DMSPATH', 'PDSPATH', 'PDSSN');
@env_list = (@env_list, 'PDSSTM', 'PROCESS_NAME', 'SAGROOT', 'CAD_ROOT');
@env_list = (@env_list, 'UESITE', 'USER', 'GENESYS', 'PDSLOGS', 'GENESYS_DIR');
@env_list = (@env_list, 'PDSWORKROOT');

my $env_var;
for $env_var (@env_list) {
  if (&CheckAndGetEnvVars($env_var)) {
    print "\n-E- $EXE_NAME: Something is wrong with your UE session:\n";
    print "$SPACER \$$env_var is not defined.\n";
    exit 1;
  }
}


# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
                  -migdir <migration run directory>
                  [pdsflow <pds flow name>] [-onlysc]
                  [-help] [-debug] [-verbose]

flag descriptions:

-cell             Input cell name for post migration run

-pdsflow          PDS flow ran for analysis. Default is fuball.

-onlysc           Running on symlib and fubx-first stage run only
                  (post SiClone only)

-migdir           Input work area containing migration run.
                  Three possible paths are searched:

                  If this directory contains /src and
                  /work-<cell>, the it is assumed this is the
                  intended input area.

                  If <migdir>.mig.log exists from mig.pl, then
                  it is assumed the input area is in
                  <migdir>/mig/<cell>

                  If migdir contains stm/<target process> and
                  /mig/<cell>.mig.log then it is assumed this
                  is an archive area and will use the input
                  from there.

                  No other matches will cause a failure.
  
-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend -migworkdir .

Files that result from this run:

- Verification runs in \$PDSLOGS

EOD


my $options_ok = 1;

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
use vars qw($COMMAND_LINE @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
use vars qw($opt_cell $opt_migdir $opt_debug $opt_verbose $opt_help);
use vars qw($opt_pdsflow $opt_onlysc);
$options_ok = &GetOptions("help",
                          "pdsflow=s",
			  "cell=s",
			  "migdir=s",
                          "onlysc",
			  "debug",
			  "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  print "-E- $EXE_NAME: One or more command line parameters incorrect.\n";
  print "$SPACER Use -help to list input flags.\n";
  die "\n";
}

		   &Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell', '-migdir');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

# Constants

# At some point define the legal set of nike netlister input/outputs


# Variables
my $cell_lc = lc($opt_cell);

use vars qw($BASEFILE $MAINLOG $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${BASE_EXE_NAME}";
my $mainlogbase = "${BASEFILE}.log";
$MAINLOG = "${WARD}/${mainlogbase}";

my $input_process = '1264';
my $output_process = '1266';

my @genesys_tcl_modules_list;

if ($UESITE eq 'iil') {
  @genesys_tcl_modules_list = ("/nfs/iil/home/mroha/pnr/mig/mig.tcl");
}
elsif ($UESITE eq 'fm') {
  @genesys_tcl_modules_list = ("/usr/users/home2/mroha/mig/mig.tcl");
} else {
  die "-E- $EXE_NAME: Script is only supported in IDC or FDC\n";
}


my $genesys_log = "${WARD}/${BASEFILE}.genesys";

my $base_sn = "${cell_lc}.sn";
my $base_stm = "${cell_lc}.stm";
my $base_lnf = "${cell_lc}.lnf";
my $nofill_ext = "nofillGate";
my $fill_ext = "fillGate";
my $fubxfirst_ext = 'fubx_first_results';
my $symlib_ext = 'fubx_first_symlib';
my $base_ext = '';
my $base_miglog = "${cell_lc}.mig.log";

my %file_map;
$file_map{'BASE'}{'STM'}{$fill_ext} = "${base_stm}.${fill_ext}";
$file_map{'BASE'}{'STM'}{$nofill_ext} = "${base_stm}.${nofill_ext}";
$file_map{'BASE'}{'STM'}{$fubxfirst_ext} = "${base_stm}.${fubxfirst_ext}";
$file_map{'BASE'}{'STM'}{$symlib_ext} = "${base_stm}.${fubxfirst_ext}";
$file_map{'BASE'}{'STM'}{$base_ext} = ${base_stm};
$file_map{'BASE'}{'SN'}{$base_ext} = ${base_sn};
$file_map{'PDS'}{'STM'}{$fill_ext} = "${PDSSTM}/$file_map{'BASE'}{'STM'}{$fill_ext}";
$file_map{'PDS'}{'STM'}{$nofill_ext} = "${PDSSTM}/$file_map{'BASE'}{'STM'}{$nofill_ext}";
$file_map{'PDS'}{'STM'}{$fubxfirst_ext} = "${PDSSTM}/$file_map{'BASE'}{'STM'}{$fubxfirst_ext}";
$file_map{'PDS'}{'STM'}{$symlib_ext} = "${PDSSTM}/$file_map{'BASE'}{'STM'}{$symlib_ext}";
$file_map{'PDS'}{'STM'}{$base_ext} = "${PDSSTM}/$file_map{'BASE'}{'STM'}{$base_ext}";
$file_map{'PDS'}{'SN'}{$base_ext} = "${PDSSN}/$file_map{'BASE'}{'SN'}{$base_ext}";
$file_map{'PDSSUMDIR'}{'STM'}{$fill_ext} = "${cell_lc}_stm_${fill_ext}";
$file_map{'PDSSUMDIR'}{'STM'}{$nofill_ext} = "${cell_lc}_stm_${nofill_ext}";
$file_map{'PDSSUMDIR'}{'STM'}{$fubxfirst_ext} = "${cell_lc}_stm_${fubxfirst_ext}";
$file_map{'PDSSUMDIR'}{'STM'}{$symlib_ext} = "${cell_lc}_stm_${symlib_ext}";


if ($output_process ne $PROCESS_NAME) {
  die "-E- $EXE_NAME: Script must be ran under $output_process UE\n";
}

my %archive_root;
$archive_root{'iil'} = "/nfs/iil/proj/mpg/mpg46/work/mig_data/idc";
$archive_root{'fm'} = "/nfs/site/disks/fm_fdc_s10079/penryn_area/mig_data/idc";

my $pdsflow;
if ($opt_pdsflow) {
  $pdsflow = $opt_pdsflow;
} else {
  $pdsflow = 'fuball';
}


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
use vars qw(@TMPFILES_LIST);
@TMPFILES_LIST = ();

# This step is really important to help the script run in an already messy area
foreach my $extension (sort keys (%{ $file_map{'PDS'}{'STM'} })) {
  &DeleteFiles("${PDSSTM}/$file_map{'PDS'}{'STM'}{$extension}");
}
&PushFilesToTemporaryList();

# Open the main log file
open(MAINLOG, ">$MAINLOG") or die "-E- $EXE_NAME: Could not open $MAINLOG for writing\n";
select(MAINLOG);
$| = 1;
select (STDOUT);

&Log('I', "$START_TIME Run Started.");
&Log('I', "Script started: $EXE_NAME $COMMAND_LINE");


my $migrundir;
my $archive_structure = 0;
if (-d "${opt_migdir}/work-${cell_lc}") {
  $migrundir = ${opt_migdir};
  &Log('I', "/work-${cell_lc} directory detected. Setting migration run area to:", $migrundir);
}
elsif ((-f "${opt_migdir}/${base_miglog}") and (-d "${opt_migdir}/mig/${cell_lc}")) {
  $migrundir = "${opt_migdir}/mig/${cell_lc}";
  &Log('I', "${base_miglog} and /mig/${cell_lc} detected. Setting migration run area to:", $migrundir);
}
elsif ((-f "${opt_migdir}/mig/${base_miglog}") and (-d "${opt_migdir}/stm/${output_process}")) {
  $migrundir = "${opt_migdir}";
  $archive_structure = 1;
  &Log('I', "/mig/${base_miglog} and /stm/${output_process} detected. Assuming an archive structure in:", $migrundir); 
} else {
  die &Log('QE', "Was not able to detect migration run area. Use -help to see search sequence for -migdir");
}

$migrundir = abs_path($migrundir);
&Log('QI', "Resolved path for migrundir: $migrundir");


my $migworkdir;
unless ($archive_structure) {
  $migworkdir = "${migrundir}/work-${cell_lc}";
  $file_map{'INPUT'}{'STM'}{$fill_ext} = "${migworkdir}/$file_map{'BASE'}{'STM'}{$fill_ext}";
  $file_map{'INPUT'}{'STM'}{$nofill_ext} = "${migworkdir}/$file_map{'BASE'}{'STM'}{$nofill_ext}";
  $file_map{'INPUT'}{'STM'}{$fubxfirst_ext} = "${migworkdir}/work-fubX_first/$file_map{'BASE'}{'STM'}{$fubxfirst_ext}";
  $file_map{'INPUT'}{'STM'}{$symlib_ext} = "${migworkdir}/work-fubX_first/$file_map{'BASE'}{'STM'}{$symlib_ext}";
  if (-e "${migworkdir}/$file_map{'BASE'}{'SN'}{$base_ext}") {
    $file_map{'INPUT'}{'SN'}{$base_ext} = "${migworkdir}/$file_map{'BASE'}{'SN'}{$base_ext}";
  }
  elsif (-e "$archive_root{$UESITE}/latest_1264_fub_data/sn/${input_process}/$file_map{'BASE'}{'SN'}{$base_ext}") {
    $file_map{'INPUT'}{'SN'}{$base_ext} = "$archive_root{$UESITE}/latest_1264_fub_data/sn/${input_process}/$file_map{'BASE'}{'SN'}{$base_ext}";
    &Log('QW', "Migrated SN file in migration area not found. Taking 1264 version from archive area:",  $file_map{'INPUT'}{'SN'}{$base_ext});
  }
  elsif (-e "$archive_root{$UESITE}/latest_1264_lib_data/sn/$file_map{'BASE'}{'SN'}{$base_ext}") {
     $file_map{'INPUT'}{'SN'}{$base_ext} = "$archive_root{$UESITE}/latest_1264_lib_data/sn/$file_map{'BASE'}{'SN'}{$base_ext}";
    &Log('QW', "Migrated SN file in migration area not found. Taking 1264 version from archive area:",  $file_map{'INPUT'}{'SN'}{$base_ext});
  }
} else {
  $migworkdir = "${migrundir}";
  $file_map{'INPUT'}{'STM'}{$fill_ext} = "${migworkdir}/stm/${output_process}/$file_map{'BASE'}{'STM'}{$fill_ext}";
  $file_map{'INPUT'}{'STM'}{$nofill_ext} = "${migworkdir}/stm/${output_process}/$file_map{'BASE'}{'STM'}{$nofill_ext}";
  $file_map{'INPUT'}{'STM'}{$fubxfirst_ext} = "${migworkdir}/stm/${output_process}/$file_map{'BASE'}{'STM'}{$fubxfirst_ext}";
  $file_map{'INPUT'}{'STM'}{$symlib_ext} = "${migworkdir}/stm/${output_process}/$file_map{'BASE'}{'STM'}{$symlib_ext}";
  $file_map{'INPUT'}{'SN'}{$base_ext} = "${migworkdir}/sn/${output_process}/$file_map{'BASE'}{'SN'}{$base_ext}";
}


foreach my $type (sort keys %{ $file_map{'INPUT'} }) {
  foreach my $extension (sort keys %{ $file_map{'INPUT'}{$type} }) {
    if ($type eq 'SN') {
      if ($pdsflow =~ /drc/) {
	next;
      } else {
	unless (-f $file_map{'INPUT'}{$type}{$extension}) {
	  die &Log('QE', "Could not find SN file in migdir area or archive area. Can not run TRCSTD. Try -pdsflow flag if TRCSTD is not required");
	}
      }
    }
    elsif ($type eq 'STM') {
      if (($opt_onlysc) and ($extension ne $fubxfirst_ext)) {
	next;
      }
    }
    &Log('QID', "Copying: $file_map{'INPUT'}{$type}{$extension} -> $file_map{'PDS'}{$type}{$extension}");
    &ManipFile('copy', $file_map{'INPUT'}{$type}{$extension}, $file_map{'PDS'}{$type}{$extension});
  }
}


if ($opt_onlysc) {
  &ManipFile('symlink', $file_map{'INPUT'}{'STM'}{$fubxfirst_ext}, $file_map{'PDS'}{'STM'}{$base_ext});
} else {
  &ManipFile('symlink', $file_map{'INPUT'}{'STM'}{$nofill_ext}, $file_map{'PDS'}{'STM'}{$base_ext});
}


&Log('I', "-onlysc flag detected. Only fubx-first data will be analyzed.");
chdir ($WARD) or die "-E- $EXE_NAME: Could not change script working dir to $WARD\n";
# Call Genesys and measure layout bounding box
&Log('I', "Starting Genesys to take bounding box measurements...");
my $readonly = 0;
my $genesysfh = &GenesysOpenSession($genesys_log);
&GenesysSetStmOptions($genesysfh);
&GenesysLoadModules(\@genesys_tcl_modules_list, $genesysfh);
&GenesysOpenCell($cell_lc, 'stm', $PDSSTM, $readonly, $genesysfh);
&GenesysLoadModules(\@genesys_tcl_modules_list, $genesysfh);
&GenesysCommandLine('::mig::getCellHeightWidth', $genesysfh);
&GenesysCloseSession($genesysfh);
&CheckGenesysRun($genesys_log);


&Log('I', "ISS runmode for all runs: $pdsflow");
my $run_is_dirty;
my $pdssumfile;

# Not ready to add lnf yet...
foreach my $viewtype ('STM') {
  foreach my $extension (sort keys %{ $file_map{'BASE'}{$viewtype} }) {
    if (($opt_onlysc) and (($extension ne $fubxfirst_ext) and ($extension ne $symlib_ext))) {
      next;
    }
    if ($extension eq $base_ext) {
      next;
    }
    my $target_file = $file_map{'PDS'}{$viewtype}{$extension};
    my $target_file_name = $file_map{'BASE'}{$viewtype}{$extension};
    my $target_pdssum_dir = $file_map{'PDSSUMDIR'}{$viewtype}{$extension};
    my $sumfile_link = uc("${target_pdssum_dir}_SUM");
    &Log('I', "Running ISS $pdsflow on $viewtype $target_file_name...");
    # Remove any existing file or symlink
    &DeleteFiles($file_map{'PDS'}{'STM'}{$base_ext});
    # Link to the appropriate stream file
    &ManipFile('symlink', $target_file, $file_map{'PDS'}{'STM'}{$base_ext});
    # Record the file sizes so we can sort things out later
    my @stat_list = stat($target_file);
    &Log('QI', "Prepping to run ISS on file: $target_file_name");
    &Log('QI', "$target_file_name has file size->$stat_list[7]");
    # Run ISS
    my $use_gdsintp = 0;
    &RunISS($cell_lc, $viewtype, $pdsflow, $use_gdsintp);
    # Copy all log files into sub directory
    &CreateDirTrees("${PDSLOGS}/$target_pdssum_dir");
    opendir(PDSLOGS, $PDSLOGS) or die &Log('QE', "Could not open dir $PDSLOGS for reading");
    my @pdsfiles_list = grep /^${cell_lc}(\.|_)/, readdir(PDSLOGS);
    close (PDSLOGS);
    my $file;
    my $current_dir = cwd;
    chdir($PDSLOGS) or die &Log('QE', "Could not temporarily change dir:", $PDSLOGS); 
    foreach $file (@pdsfiles_list) {
      if (-f "${PDSLOGS}/${file}") {
	if (-l "${PDSLOGS}/${file}") {
	  next;
	}
	&ManipFile('copy', "${PDSLOGS}/${file}", "${PDSLOGS}/${target_pdssum_dir}/${file}");
	if ($file =~ /.iss.log.sum/) {
	  &ManipFile('symlink', "${target_pdssum_dir}/${file}", $sumfile_link);
	}
	# Keep things tidy
	&DeleteFiles("${PDSLOGS}/${file}");
      }
    }
    chdir($current_dir) or die &Log('QE', "Could not change back to working dir:", $current_dir);
  }
}

&DeleteFiles(@TMPFILES_LIST) unless $opt_debug;
use vars qw($STOP_TIME);
$STOP_TIME = &GetDate;
&Log('I', "Log file: $MAINLOG");
&Log('I', "$STOP_TIME Run Complete.");
close (MAINLOG);



########## Begin subroutine definitions ##########

# Exception hander
sub ExceptionHandler {

  die &Log('QE', "Exception Occurred. Exiting...");
}


# Deletes every file in the provided list, if it exists
sub DeleteFiles {

  my @files_list = @_;
  my $file;
  
  foreach $file (@files_list) {
    if ((-f $file) or (-l $file)) {
      unlink ($file);
    }
  }
}


sub DeleteDirTrees {

  my @targetdirs = @_;
  my $dir;

  foreach $dir (@targetdirs) {
    if (-d $dir) {
      rmtree($dir, 0, 1);
      if (-d $dir) {
	return 0;
      }
    }
  }
  return 1;
}


# Creates specified directory tree
sub CreateDirTrees {

  my @targetdirs = @_;
  my $dir;

  foreach $dir (@targetdirs) {
    unless (-d $dir) {
      mkpath($dir, 0, 0755);
      unless (-d $dir) {
	return 1;
      }
    }
  }
  return 0;
}


sub ManipFile {

  my $mode = shift;
  my $sourcefile = shift;
  my $destfile = shift;
  my $ok;
  my %cmd_hash;
  my $command;

  if ($mode eq 'copy') {
    $ok = copy($sourcefile, $destfile);
  }
  elsif ($mode eq 'symlink') {
    # Kinda like ln -sf, but safer
    if (-l $destfile) {
      unlink($destfile);
    }
    $ok = symlink($sourcefile, $destfile);
  }
  elsif ($mode eq 'move') {
    $ok = move($sourcefile, $destfile);
  } else {
    die &Log('QE', 'Invalid mode passed to procedure ManipFile: $mode');
  }
  unless ($ok) {
    die &Log('QE', "Could not run $mode on files:",
	     "From: $sourcefile",
	     "To: $destfile");
  }
}


# Places files deemed as temporary into the global temp file list.
# This is to ensure that residual files do not interfere with the
# current run
sub PushFilesToTemporaryList {
  
  my @file_list = @_;
  
  push(@TMPFILES_LIST, @file_list);
}



# Gets the date and processes it to a nicer format
sub GetDate {

  my $date;
  
  $date = "(".scalar localtime().")";
  return $date;
}

sub Tcsh {

  my $mode = shift;
  my $cmd = shift;
  
  my $tcsh_cmd = "/bin/tcsh -fc";

  if ($mode eq 'bg') {
    &Log('QI', "Starting background process: $tcsh_cmd \"$cmd\"");
    system("$tcsh_cmd \"$cmd\" &");
  } else {
    &Log('QI', "Starting foreground process: $tcsh_cmd \"$cmd\"");
    system("$tcsh_cmd \"$cmd\"");
  } 
}


# Polls for the existance of the given file once every POLL_INTERVAL seconds
sub PollForFile {
  my $flag_file = shift; 
  my $POLL_INTERVAL = 5;
  
  while (!(-e $flag_file)) {
    sleep $POLL_INTERVAL;
  }
}



# Does a closer check of the command line flags. Will check that
# flags required for the script execution are present, and will also check
# that a flag is not listed twice.
# For cases where one flag from a list of flags is required, separate by ":"
sub CheckForMissingFlags {

  my $argv_list_ref = shift;
  my $required_flags_list_ref = shift;
  my %argv_hash;
  my $flag;
  my @flags;
  my $required_flag_found;
  my $flag_spec;
  my $listflag;

  map { $argv_hash{$_} = 1 } @{ $argv_list_ref };
  foreach $flag_spec (@{ $required_flags_list_ref }) {
    $required_flag_found = 0;
    @flags = split(/:/, $flag_spec);
    foreach $flag (@flags) {
      if (exists $argv_hash{$flag}) { 
	if ($required_flag_found) {
	  print "$EXE_NAME: Only one flag from $flag_spec can be specified.";
	  print "$SPACER Use -help to list input flags.\n";
	  die "\n";
	} else {
	  $required_flag_found = 1;
	}
      }
    }
    unless ($required_flag_found) {
      die "$EXE_NAME: Required flag(s) are missing. Use -help to list input flags.\n";
    }
  }
}



# Will print usage list that is provided. Replaces usage in inc.ph, got
# tired of having to worry whether or not the .ph file is in the
# current project.
sub Usage {

  my $error = shift;
  my @usagelist = @_;
  my $line;

  print "$error";
  print "\n";
  for $line (@usagelist) {
    print $line;
  }
  exit 1;
}



# Will set perl variables that contain the values of their environment
# counterparts.
sub CheckAndGetEnvVars {

  my @varswanted = @_;
  my $var;
  my $line;
  my $check;
  
  $check = 0;
  
  for $var (@varswanted) {
    if (!$ENV{$var}) {
      $check++;
      $line = "\$$var = \"\";";   # Prepare a variable assignment.
    } else {
      $line = "\$$var = \'$ENV{$var}\';";   # Prepare a variable assignment.
    }
    eval $line;			      # Set the internal variable.
  }
  return($check);
}


# Will log information to MAINLOG and/or STDOUT depending on the mode.
# The first arguement to the function is a string that will control the
# behavior of Log:
# 'P' regardless of $opt_verbose, print to STDOUT
# 'Q' regardless of $opt_verbose, do not print to STDOUT
# 'D' writes the $DEBUG string into message
# 'I', 'W', or 'E' may be passed to signify the message severity.
# Default severity is 'I'
#
# 'P' takes precendence over 'Q'. These two options are mutually exclusive
#
#
# Example: &Log('I', "This message will go to log",
#                    "and STDOUT if -verbose used")
#
# Example: open (FOOFILE, $foofile) or
#   die &Log('QE', "This message will also go to log and stdout",);
#                  "Since Log() returns string and die will print",
#                  "this string by default, no 'P' directive needed");


sub Log {

  my $mode = shift;
  my @message = @_;
  my $header;
  my $i = 0;
  my $printstdout = 0;
  my $logstring;
  my $logonly = 0;
  my $debug_msg = 0;
  my $debug_length;

  # Modes definition

  $mode = uc($mode);

  if ($mode =~ /P/) {
    $mode =~ s/P//;
    $printstdout = 1;
  }
  elsif ($mode =~ /Q/) {
    $mode =~ s/Q//;
    $logonly = 1;
  } 
  if ($mode =~ /D/) {
    $mode =~ s/D//;
    $debug_msg = 1;
  }
  if ($opt_verbose and !$logonly) {
    $printstdout = 1;
  }

  if ($mode !~ /(I|W|E)/) {
    $mode = 'I';
  }
  for ($i = 0; $i <= $#message; $i++) {
    if ($i == 0) {
      $header = "-${mode}- $EXE_NAME: ";
      if ($debug_msg) {
	$header = ${DEBUG_STRING} . $header;
      }
    } else {
      $header = "$SPACER ";
      if ($debug_msg) {
	$debug_length = length($DEBUG_STRING);
	$header = $header . " " x $debug_length;
      }
    }
    $logstring .= "${header}$message[$i]\n";
  }
  
  print STDOUT $logstring if $printstdout;
  print MAINLOG $logstring;
  return $logstring;
}


# Will round a floating point number to the closest integer.
sub Round {

   my $input_float = shift;
   my $output_integer;
   my $rounding_factor;

   if ($input_float < 0) {
      $rounding_factor = -.5;
   } else {
      $rounding_factor = .5;
   }

   $output_integer = int($input_float + $rounding_factor);
   return $output_integer;
}


# Meant to show how to use some of the functions.
sub Testfunction {

  my $var1 = shift;
  my $var2 = shift;
  my $anotheropenpipe = shift;
  my $parenthandle_ref = select($anotheropenpipe);

  # &DeleteFiles(); Make sure to get rid of any residual files/flags

  &Log('I', "Running Testfunction...");

  # do stuff and touch flag file when done
  # &PollForFile($touchfile);

  select ($parenthandle_ref);

}


sub GenesysOpenSession {

  my $genesyslog = shift;
  my $parentfh = select;  # Capture existing value
  my $genesys_cmd_line;

  local *GENESYSFH;

  $genesys_cmd_line = "$GENESYS_DIR/ConfigFiles/nike.wrapper $GENESYS_DIR/bin/genesys -nullgt";
  open (GENESYSFH, "| $genesys_cmd_line > $genesyslog 2>&1") or die
    &Log('QE', "Could not open a pipe to Genesys");
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


sub CheckGenesysRun {

  my $genesyslog = shift;

  open (GENESYSLOG, $genesyslog) or die &Log('QE', "Could not open $genesyslog for reading");
  
  while (<GENESYSLOG>) {
    if (/getCellHeightWidth:/) {
      chomp;
      &Log('QI', "GENESYS: $_");
    }
    if (/(invalid command name(.+)Baa)/) {
      chomp;
      &Log('QI', "GENESYS: $_");
      die &Log('QE', "Problem occurred during LNF pre-processing. See Genesys log file:", $genesyslog);
    }
  }
  close (GENESYSLOG);
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


# Very dirty. To-do: wrap this whole thing up in open3()
sub GenesysCommandLine {

  my $genesys_command = shift;
  my $genesysfh = shift;
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
      &Log('QDI', "Sourcing TCL module: $tclfile") if $opt_debug;
      print "source $tclfile\n";
    } else {
      &Log('QE', "Could not load TCL module into Genesys:", $tclfile);
      $at_least_one_module_bad = 1;
    }
  }
  if ($at_least_one_module_bad) {
    die &Log('QE', "At least one TCL file not sourced properly into Genesys");
  }
  select($parentfh);
}



sub RunISS {

  my $cell = shift;
  my $inputtype = shift;
  my $pdsflow = shift;
  my $use_gdsintp = shift;
  my $pdscellfile = "$PDSLOGS/${cell}.cell.log";
  my $pdsdatafile = "$PDSLOGS/${cell}.data.log";
  my $pdsexpfile = "$PDSLOGS/${cell}.explode.list";
  my $pdslogfile = "$PDSLOGS/${cell}.${pdsflow}.iss.log";
  my $pdssumfile = "$PDSLOGS/${cell}.${pdsflow}.iss.log.sum";
  my $pdsstdcmpfile = "$PDSLOGS/${cell}.standard.iss.cmp";
  my $pdsstdcmpallfile = "$PDSLOGS/${cell}.standard.iss.cmpall";
  my $pdsaltcmpfile = "$PDSLOGS/${cell}.alternate.iss.cmp";
  my $pdsaltcmpallfile = "$PDSLOGS/${cell}.alternate.iss.cmpall";
  my $pdsanfile = "$PDSLOGS/${cell}.analysis";
  my $pdslnsfile = "$PDSLOGS/${cell}.iss.lns";
  my $pdspinsfile = "$PDSLOGS/${cell}.sch_pins";
  my $pdsstatsfile = "$PDSLOGS/${cell}_trcstd.stats";
  my $pdsabortfile = "$PDSLOGS/${cell}.${pdsflow}.iss.log.abort";
  my @pdsfiles;
  my $run_is_dirty = 0;

  @pdsfiles = ($pdscellfile, $pdsdatafile, $pdsexpfile, $pdslogfile, $pdssumfile);
  @pdsfiles = (@pdsfiles, $pdsstdcmpfile, $pdsstdcmpallfile, $pdsanfile, $pdslnsfile);
  @pdsfiles = (@pdsfiles, $pdspinsfile, $pdsstatsfile,  $pdsabortfile);
 
  &DeleteFiles(@pdsfiles);
  # Decide which files to delete later

  # Oh brother
  if ($inputtype =~ /lnf/i) {$inputtype = 'LNF'};
  if ($inputtype =~ /stm/i) {$inputtype = 'stm'};
  if ($inputtype =~ /alf/i) {$inputtype = 'alf'};

  if ($use_gdsintp) {
    $ENV{'GDSINTP'} = 'YES';
  } else {
    $ENV{'GDSINTP'} = 'NO';
  }

  # Since we could be running the same block on the same machine, but in different work areas, set a random number for the PDSWORKROOT (which shared on the local disk)
  my $pdsworkroot_area_set = 0;
  my $pdsworkroot_suffix;
  my $newpdsworkroot;
  my $random_pdsroot_suffix_range = 10000;
  until ($pdsworkroot_area_set) {
    srand;
    $pdsworkroot_suffix = int(rand($random_pdsroot_suffix_range));
    $newpdsworkroot = "${PDSWORKROOT}/${BASE_EXE_NAME}_${pdsworkroot_suffix}";
    $newpdsworkroot =~ s/\/\//\//g;
    &Log('QI', "Trying to assign new PDSWORKROOT area: $newpdsworkroot");
    unless (-d $newpdsworkroot) {
      &CreateDirTrees($newpdsworkroot);
      $ENV{'PDSWORKROOT'} = $newpdsworkroot;
      $pdsworkroot_area_set = 1;
      &Log('QI', "New PDSWORKROOT area set: $ENV{'PDSWORKROOT'}");
    }
  }
  
  my $saveworkdir;
  if ($opt_debug) {
    $saveworkdir = 'yes';
  } else {
    $saveworkdir = 'no';
  }

  &Tcsh('fg', "$PDSPATH/_pdsbuilder.new -database ' ' -laytopcell $cell -mode $pdsflow -saveworkdir $saveworkdir -mailuser no -ecn ECNOFF -runmode local -incremental no -newinc ' ' -autotail no -signallist ' ' -verifytool cmp -inputtype $inputtype -trcpin top -commandfile ' ' -laychangefile ' ' -topframe nocheck -outtype apl -sigfiles ' ' -skipcvsin no -calcres no -batch1 HIDE -skewtype TTTT -tooltype iss -explode DEFAULT -autohmsprt no -smshopt relax -dvssmshfile none -ltlinpath none -ltloutpath none -groupdir none -chkptdir none -libspec $cell -lnpath ' ' -batch2 HIDE -batch3 HIDE -onecell no -crosscap none -make_sn 1 -fg yes -snname DEFAULT >& /dev/null");

  
  unless ($opt_debug) {
    &DeleteDirTrees($newpdsworkroot);
  }

  # Confirm sum file was created and has valid contents
  if (-e $pdsabortfile ) {
    die &Log('QE', "PDS $pdsflow run aborted.",
	     "See $pdsabortfile");
  }
  open (PDSSUM, $pdssumfile) or die &Log('QE', "Could not open $pdssumfile for reading");
  #Summary
  while (<PDSSUM>) {
    if (/^\s*(DIRTY|clean|(Total\s+\d+\s+\d+))|lay\s+sch|[dD]evices|Unmatched|Nodes|(Input Data Type)|(FLOW = cvscmp)|Flow|Tool/) {
      chomp;
      if (/DIRTY/) {
	$run_is_dirty = 1;
      }
      &Log('QI', "PDS: $_"); 
    }
  }
  close (PDSSUM);
  return ($run_is_dirty, $pdssumfile);
}


# Update this to allow a list to be passed
sub GenesysSetStmOptions {

  my $genesysfh = shift;
  my $parentfh = select($genesysfh);

  print "\nstm instanceProperty 112\n";
  #print "stm userUnits $GDSII_USERUNITS\n";
  print "stm outputCellInsts 1\n";
  print "stm outputTermInsts 1\n";
  print "stm mergePolygons 0\n";  # there is a bug with writing holes
  print "stm inputTechnology p${PROCESS_NAME}\n";
  print "stm defaultTextMagnification 0.01\n";
  select($parentfh);
}
