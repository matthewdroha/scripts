#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: reportmig.pl,v 1.4 2004/12/21 15:08:01 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  migreport.pl			Project: Penryn
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
#* Fetches input from the following sources:
#*   - <cell>.premig.log
#*   - <cell>.mig.log
#*   - <cell>.postmig.log
#*   - <CELL>_STM_NOFILLGATE
#*   - <CELL>_STM_FILLGATE
#*   - <CELL>_STM_FUBXFIRST
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
use vars qw($EXE_NAME $BASE_EXE_NAME $BASE_EXE_NAME_UC);
$EXE_NAME = basename($0);
($BASE_EXE_NAME) = split(/\./,$EXE_NAME);
$BASE_EXE_NAME_UC = uc($BASE_EXE_NAME);


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
use vars qw();
my @env_list = ();

my $env_var;
for $env_var (@env_list) {
  if (&CheckAndGetEnvVars($env_var)) {
    print "\n-E- $EXE_NAME: Something is wrong with your UE session:\n";
    print "$SPACER \$$env_var is not defined.\n";
    exit 1;
  }
}

my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
        [-libflow] [-outcsv <output csv name>]
        [-premigrundir <premig run area>|-premigarchdir <premig archive area>]
        [-migrundir <mig run area>|-migarchdir <mig archive area>]
        [-postmigrundir <postmig run area>|-postarchdir <postmig archive area>]
        [-help] [-debug] [-verbose]

flag descriptions:

-cell             Input cell name for analysis

-libflow          Input cell is a library cell

-outcsv           Output .csv name. Default is <cell>.${EXE_NAME}.csv

-sumfilter        Takes a regex as input. Will only process PDS
                  sumfiles that match that regex. Is case sensitive.

-premigdir        Input work area containing <cell>.premig.log files.
                  If no flag is given, flow will take latest premig
                  log file from the central archive                

-migdir           Similar to -premigdir, except search is for
                  <cell>.mig.log

-postmigdir       Similar to -premigdir, except search is for
                  the following files:
                 
                  <cell>.postmig.log
                  <postmigdir>/pds/logs/<CELL>_STM_NOFILLGATE_SUM (if present)
                  <postmigdir>/pds/logs/<CELL>_STM_FILLGATE_SUM (if present)
                  <postmigdir>/pds/logs/<CELL>_STM_FUBXFIRST_SUM (if present)

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend -premigrundir . -migrundir . -postmigrundir .
example: $EXE_NAME -cell pbctrsn -migrundir . -postmigrundir . -sumfilter "nofillGate\$"

Files that result from this run:

<cell>.${EXE_NAME}.log
<cell>.${EXE_NAME}.report
<cell>.${EXE_NAME}.csv  

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
use vars qw($opt_cell $opt_verbose $opt_debug $opt_help $opt_libflow $opt_outcsv $opt_sumfilter);
use vars qw($opt_premigdir $opt_migdir $opt_postmigdir);
$options_ok = &GetOptions("help",
			  "cell=s",
			  "premigdir=s",
  			  "migdir=s",
			  "postmigdir=s",
                          "outcsv=s",
			  "sumfilter=s",
			  "debug",
                          "libflow",
			  "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  print "-E- $EXE_NAME: One or more command line parameters incorrect.\n";
  print "$SPACER Use -help to list input flags.\n";
  die "\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

# Constants

use vars qw($DESC_KEY $VALUE_KEY $FLOW_KEY $CODE_KEY);
$DESC_KEY = 'DESCRIPTION';
$VALUE_KEY = 'VALUE';
$FLOW_KEY = 'FLOW';
$CODE_KEY = 'CODE';

use vars qw(%DESC_RECORD @CMP_RECORD_ORDER);

# This flow
$DESC_RECORD{'LAYOUT_X_SCALE'} = 'Layout X linear scaling';
$DESC_RECORD{'LAYOUT_Y_SCALE'} = 'Layout Y linear scaling';

$DESC_RECORD{'FILE'} = 'Full path to PDS sum file';
$DESC_RECORD{'BASEFILE'} = 'Base name for PDS sum file';
$DESC_RECORD{'CELLNAME'} = 'Cell Name';
$DESC_RECORD{'MIGSTAGE'} = 'Migration Stage';
$DESC_RECORD{'INPUT'} = 'Input Data Type';


# Premig
$DESC_RECORD{'LAYOUT_DEVICES'} = "Total layout devices";
$DESC_RECORD{'FUB_TYPE'} = "FUB type";
$DESC_RECORD{'1264_X_WIDTH'} = "1264 FUB X Width (units=u)";
$DESC_RECORD{'1264_Y_HEIGHT'} = "1264 FUB Y Height (units=u)";

# Postmig
$DESC_RECORD{'1266_X_WIDTH'} = "1266 FUB X Width (units=u)";
$DESC_RECORD{'1266_Y_HEIGHT'} = "1266 FUB Y Height (units=u)";

# ISS
$DESC_RECORD{'SHORT'} = 'Text Shorts';
$DESC_RECORD{'OPEN'} = 'Text Opens';
$DESC_RECORD{'TOTAL_LAY_NODES'} = 'Total layout nodes';
$DESC_RECORD{'TOTAL_SCH_NODES'} = 'Total schematic nodes';
$DESC_RECORD{'UNMATCH_LAY_NODES'} = 'Unmatched layout nodes';
$DESC_RECORD{'UNMATCH_SCH_NODES'} = 'Unmatched schematic nodes';
$DESC_RECORD{'UNMATCH_LAY_DEVICES'} = 'Unmatched layout devices';
$DESC_RECORD{'UNMATCH_SCH_DEVICES'} = 'Unmatched schematic devices';
$DESC_RECORD{'ZL'} = 'Z/L errors';
$DESC_RECORD{'BULK'} = 'Bulk connection errors';
$DESC_RECORD{'UPC'} = 'Unusable pin connection errors';
$DESC_RECORD{'TOTALS'} = 'ERROR_TOTAL';

@CMP_RECORD_ORDER = ('TOTAL_LAY_NODES', 'TOTAL_SCH_NODES', 'UNMATCH_LAY_NODES');
@CMP_RECORD_ORDER = (@CMP_RECORD_ORDER, 'UNMATCH_SCH_NODES', 'UNMATCH_LAY_DEVICES');
@CMP_RECORD_ORDER = (@CMP_RECORD_ORDER, 'UNMATCH_SCH_DEVICES', 'ZL', 'BULK', 'UPC');



# Variables
my $cell_lc = lc($opt_cell);
my $cell_uc = uc($opt_cell);

use vars qw($BASEFILE $MAINLOG);
$BASEFILE = "${cell_lc}.${BASE_EXE_NAME}";
my $mainlogbase = "${BASEFILE}.log";
$MAINLOG = "${mainlogbase}";

my $input_process = '1264';
my $output_process = '1266';

my $csvoutfile = "${BASEFILE}.csv";

my $base_sn = "${cell_lc}.sn";
my $base_stm = "${cell_lc}.stm";
my $base_lnf = "${cell_lc}.lnf";
my $nofill_ext = "nofillGate";
my $fill_ext = "fillGate";
my $fubxfirst_ext = 'fubx_first_results';
my $sn_ext = '';
my $base_sum_suffix = "^(${cell_uc}|${cell_lc})(\.|_)(.+)(.iss.log.sum|SUM)\$";

my %archive_root;

$archive_root{'iil'} = "/nfs/iil/proj/mpg/mpg46/work/mig_data/idc";
$archive_root{'fm'} = "/nfs/site/disks/fm_fdc_s10079/penryn_area/mig_data/idc";

# Will get multisite support outside of UE set up when I can...
my $site = 'iil';

my $premig_archive;
my $mig_archive;
my $postmig_archive;

if ($opt_libflow) {
  $premig_archive = "$archive_root{$site}/latest_${input_process}_lib_data";
  $mig_archive = "$archive_root{$site}/latest_${output_process}_lib_data";
  $postmig_archive = "$archive_root{$site}/latest_${output_process}_lib_data";
} else {
  $premig_archive = "$archive_root{$site}/latest_${input_process}_fub_data";
  $mig_archive = "$archive_root{$site}/latest_${output_process}_fub_data";
  $postmig_archive = "$archive_root{$site}/latest_${output_process}_fub_data";
}

my %log_table;
$log_table{'premig'}{'BASE'} = "${cell_lc}.premig.log";
$log_table{'mig'}{'BASE'} = "${cell_lc}.mig.log";
$log_table{'postmig'}{'BASE'} = "${cell_lc}.postmig.log";
$log_table{'premig'}{'DEFAULT'} = "${premig_archive}/premig";
$log_table{'mig'}{'DEFAULT'} = "${mig_archive}/mig";
$log_table{'postmig'}{'DEFAULT'} = "${postmig_archive}/postmig";
$log_table{'postmig'}{'DEFAULTSUMDIR'} = "${postmig_archive}/postmig";
$log_table{'premig'}{'MISSING'} = "No scale factor or device count";
$log_table{'mig'}{'MISSING'} = "No migration configuration, run time, memory stats";
$log_table{'postmig'}{'MISSING'} = "No scale factor or ISS data";


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
use vars qw(@TMPFILES_LIST);
@TMPFILES_LIST = ();

# This step is really important to help the script run in an already messy area
&DeleteFiles();
&PushFilesToTemporaryList();

# Open the main log file
open(MAINLOG, ">$MAINLOG") or die "-E- $EXE_NAME: Could not open $MAINLOG for writing\n";
select(MAINLOG);
$| = 1;
select (STDOUT);

&Log('I', "$START_TIME Run Started.");
&Log('I', "Script started: $EXE_NAME $COMMAND_LINE");

if ($opt_sumfilter) {
  $base_sum_suffix = $opt_sumfilter;
  &Log('I', "-sumfilter detected. Only PDS sumfiles matching to $base_sum_suffix will be processed");
}


if ($opt_premigdir) {
  $log_table{'premig'}{'USER'} = $opt_premigdir;
  $log_table{'premig'}{'ARCHIVE'} = "$log_table{'premig'}{'USER'}/premig";
}
if ($opt_migdir) {
  $log_table{'mig'}{'USER'} = $opt_migdir;
  $log_table{'mig'}{'ARCHIVE'} = "$log_table{'mig'}{'USER'}/mig";
}
if ($opt_postmigdir) {
  $log_table{'postmig'}{'USER'} = $opt_postmigdir;
  $log_table{'postmig'}{'ARCHIVE'} = "$log_table{'postmig'}{'USER'}/postmig";
  $log_table{'postmig'}{'USERSUMDIR'} = "$log_table{'postmig'}{'USER'}/pds/logs";
  $log_table{'postmig'}{'ARCHIVESUMDIR'} = $log_table{'postmig'}{'ARCHIVE'};
}


foreach my $logtype ('premig', 'mig', 'postmig') {
  foreach my $sourcetype ('USER', 'ARCHIVE', 'DEFAULT') {
    if (exists $log_table{$logtype}{$sourcetype}) {
      my $targetlog = "$log_table{$logtype}{$sourcetype}/$log_table{$logtype}{'BASE'}";
      if (-f $targetlog) {
	&Log('QI', "Found $logtype log, source $sourcetype: $targetlog");
	my $resolved_path = abs_path($log_table{$logtype}{$sourcetype});
	$targetlog = "${resolved_path}/$log_table{$logtype}{'BASE'}";
	&Log('QI', "Resolved path for $logtype: $targetlog");
	$log_table{$logtype}{'EXISTS'} = $targetlog;
	if ($logtype eq 'postmig') {
	  $log_table{$logtype}{'EXISTSSUMDIR'} = $log_table{$logtype}{"${sourcetype}SUMDIR"};
	}
	last;
      }
    }
  }
}

foreach my $logtype ('premig', 'mig', 'postmig') {
  unless (exists $log_table{$logtype}{'EXISTS'}) {
    &Log('PW', "No $logtype log found in -${logtype}dir or in central archive",
	 "Consequences: $log_table{$logtype}{'MISSING'}");
    if ($logtype eq 'postmig') {
      die &Log('QE', "No postmig log or ISS runs found... no point in continuing");
    }
  }
}




my $postmigsumdir = abs_path($log_table{'postmig'}{'EXISTSSUMDIR'});
opendir (SUMDIR, $postmigsumdir) or die &Log("Could not open $postmigsumdir for reading");
my @temp_list = grep /${base_sum_suffix}/, readdir (SUMDIR);
my $file;
my @pdssumfile_list;
closedir (SUMDIR);
foreach $file (@temp_list) {
  unless (-d "${postmigsumdir}/${file}") {
    push(@pdssumfile_list, "${postmigsumdir}/${file}");
  }
}
unless (scalar @pdssumfile_list) {
  &Log('PW', "No PDS sum files were found in expected postmig location. See help");
}



my %log_record;
&Log('QI', "Resolving log file paths...");
my $premiglog = $log_table{'premig'}{'EXISTS'};
my $miglog = $log_table{'mig'}{'EXISTS'};
my $postmiglog = $log_table{'postmig'}{'EXISTS'};
if (($premiglog) and (-f $premiglog)) {
  &Log('I', "Parsing premig logfile: $log_table{'premig'}{'EXISTS'}");
  &ParsePremigLog($premiglog, \%log_record);
}
if (($miglog) and (-f $miglog)) {
  &Log('I', "Parsing mig logfile: $miglog");
  &ParseMigLog($log_table{'mig'}{'EXISTS'}, \%log_record);
}
if (($postmiglog) and (-f $postmiglog)) {
  &Log('I', "Parsing postmig logfile: $postmiglog");
  &ParsePostmigLog($log_table{'postmig'}{'EXISTS'}, \%log_record);
}

if ($premiglog and $postmiglog) {
  &Log('I', "Calculating scale factors");
  &CalcScaling(\%log_record);
}


if ($opt_debug) {
  my $const;
  my $flow;
  my $code;
  my $value;
  &Log('QDI', "Unrolling log_record hash");
  foreach $flow (sort keys %log_record) {
    foreach $code (sort keys %{ $log_record{$flow} }) {
      foreach $const (sort keys %{ $log_record{$flow}{$code} }) {
	if (exists $log_record{$flow}{$code}{$const}) {
	  &Log('QDI', "Flow: $flow  Code: $code  Key: $const  Value: $log_record{$flow}{$code}{$const}");
	}
      }
    }
  }
}

my $sumfile;
my %data_table;
my %duplicate_code_record;
# For each sumfile
foreach $sumfile (@pdssumfile_list) {
  # Open sumfile and process summary results
  &Log('I', "Parsing PDS sumfile: $sumfile");
  &ReadPdsSumFile($sumfile, \%data_table, \%duplicate_code_record);
}
my $sumfile_count = scalar(@pdssumfile_list);
&Log('I', "$sumfile_count sumfiles were processed");

# Roll in log file input into every sumfile entry... it is duplicate data but is required
&MergeLogDataIntoDataTable(\%data_table, \%log_record, \%duplicate_code_record);

# Generate a list of flow-error code pairs that is the union of all data
my %merged_codes_table;
&GenerateFlowCodePairs(\%data_table, \%merged_codes_table);


if ($opt_debug) {
  my $flow;
  my $code;
  foreach $flow (sort keys %merged_codes_table) {
    foreach $code (sort keys %{$merged_codes_table{$flow}}) {
      &Log('QDI', "Flow:$flow   Error:$code   Descrip:$merged_codes_table{$flow}{$code}");
    }
  }
}


# Print output csv file
my @csvfield_list = ($FLOW_KEY, $CODE_KEY, @pdssumfile_list, $DESC_KEY);
&WriteSumCsv($csvoutfile, \@csvfield_list, \@pdssumfile_list, \%data_table, \%merged_codes_table);

if ($opt_outcsv) {
  &Log('I', "-outcsv detected. Creating file $opt_outcsv");
  &ManipFile('move', $csvoutfile, $opt_outcsv);
  &Log('I', "csvfile written: $opt_outcsv");
} else {
  &Log('I', "csvfile written: $csvoutfile");
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


sub ConvertElapsedTimeToSeconds {

  my $days = shift;
  my $hours = shift;
  my $minutes = shift;
  my $seconds = shift;

  my $elapsed_time = int($days*86400);
  $elapsed_time += int($hours*3600);
  $elapsed_time += int($minutes*60);
  $elapsed_time += int($seconds);
}


sub ConvertTopMemToKBytes {

  my $value = shift;
  my $units = shift;
  my %units_map;

  $units_map{'Gigs'} = 1000000;
  $units_map{'Megs'} = 1000;
  $units_map{'K'} = 1;

  return ($value * $units_map{$units});
}


sub ReadPdsSumFile {

  my $sumfile = shift;
  my $data_table_ref = shift;
  my $duplicate_code_record_ref = shift;
  my $flow;
  my $in_flow_section = 0;
  my $value;
  my $code;
  my $description;
  my $cmp_value;
  my $extension;
  my @record;
  my $totals_code;
  my $totals_description;
  my $warn_if_duplicate_code;
  my $record_only;

  my $BASE_EXE_NAME_UC = uc($BASE_EXE_NAME);

  open(SUMFILE, $sumfile) or die &Log('QE', "Could not open $sumfile for reading");
  while (<SUMFILE>) {
    if (/\* FLOW =\s+(\w+)\s+(\w+)?\s+\*/) {
      $flow = $1;
      $extension = $2;
      &Log('QDI', "Flow found:  Flow=${flow}") if $opt_debug;
      if ($extension) {
	&Log('QDI', "Extension=${extension}") if $opt_debug;
	$flow .= "_${extension}";
      }
      $totals_code = "$DESC_RECORD{'TOTALS'}_${flow}";
      $totals_description = "Total error markers for flow: $flow";
      $in_flow_section = 1;
    } 
    if (/Input Data Type = (\S+)/) {
      $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'INPUT'}{$DESC_KEY} = $DESC_RECORD{'INPUT'};
      $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'INPUT'}{$VALUE_KEY} = $1;
    }
    if ($in_flow_section) {
      if (/^\s*(\d+)\s+(\S+)\s+(.*)/) {
	$value = $1;
	$code = $2;
	$description = $3;
	chomp($description);
	$description =~ s/\,/ /g;
	if ($code !~ /((\S+)_(\S+))|(UNK)|(illdev)/) {
	  $code .= " $description";
	  $description = $code;
	}
	if ($description =~ /TOTAL\s+\S+\s+ERRORS/) {
	  $code = $totals_code;
	  $description = $totals_description;
	}
	&Log('QDI', "Found DRC style error code: Code: $code   Descrip: $description") if $opt_debug;

	$warn_if_duplicate_code = 1;
	$record_only = 0;
	&RecordValue($data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, $value, $code, $description, $record_only, $warn_if_duplicate_code);
      }
      elsif (/SHORT_CIRCUITS:/) {
	$code = 'SHORT';
	$description = $DESC_RECORD{$code};
	$$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
	$$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = 0;
      }
      elsif (/OPEN_CIRCUITS:/) {
	$code = 'OPEN';
	$description = $DESC_RECORD{$code};
	$$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
	$$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = 0;
      }
      # Text short or text open format
      elsif (/^\S+\s+\S+((\(\d+\;\d+\)\s+\S+\(\d+\;\d+\))|(\s+\d+\;\d+))/) {
	chomp;
	if ($opt_debug) {
	  &Log('QDI', "Found TRC style error code: $code");
	  &Log('QDI', "$_");
	}
	$warn_if_duplicate_code = 0;
	$record_only = 0;
	&RecordValue($data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, 1, $code, $description, $record_only, $warn_if_duplicate_code);
	# For trc, opens and shorts don't get talied in the totals section, so add them here
	$warn_if_duplicate_code = 0;
	&RecordValue($data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, 1, $totals_code, $totals_description, $record_only, $warn_if_duplicate_code);
      }
      elsif (/^Total(\s+\d+){9}/) {
	@record = split;
	chomp;
	if ($opt_debug) {
	  &Log('QDI', "Found CMP style error");
	  &Log('QDI', "$_");
	}
	shift(@record);
	foreach $code (@CMP_RECORD_ORDER) {
	  $cmp_value = shift(@record);
	  $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	  $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = $cmp_value;
	}
      }
      elsif (/ERR Files Created/) {
	$in_flow_section = 0;
      }
    }
  }
  close (SUMFILE);
  
  my $base_sumfile = basename($sumfile);
  $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'FILE'}{$DESC_KEY} = $DESC_RECORD{'FILE'};
  $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'FILE'}{$VALUE_KEY} = $sumfile;
  $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'BASEFILE'}{$DESC_KEY} = $DESC_RECORD{'BASEFILE'};
  $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'BASEFILE'}{$VALUE_KEY} = $base_sumfile;
  $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'CELLNAME'}{$DESC_KEY} = $DESC_RECORD{'CELLNAME'};
  $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'CELLNAME'}{$VALUE_KEY} = $cell_lc;
  if ($sumfile =~ /^\S+_(LNF|STM)_(\S+)_SUM$/) {
    $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'MIGSTAGE'}{$DESC_KEY} = $DESC_RECORD{'MIGSTAGE'};
    $$data_table_ref{$sumfile}{$BASE_EXE_NAME_UC}{'MIGSTAGE'}{$VALUE_KEY} = $2;
  }
} 


sub RecordValue {

  my $data_table_ref = shift;
  my $duplicate_code_record_ref = shift;
  my $sumfile = shift;
  my $flow = shift;
  my $value = shift;
  my $code = shift;
  my $description = shift;
  my $record_only = shift;
  my $warn_if_duplicate_error = shift;

  $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
  if (exists $$duplicate_code_record_ref{$sumfile}{$flow}{$code}) {
    &Log('WP', "A duplicate error code was parsed from sum file: $sumfile", "Code: $code") if $warn_if_duplicate_error;
    if ($record_only) {
      &Log('WP', "Reseting conflicting error counts to new value") if $warn_if_duplicate_error;
      $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = $value;
    } else {
      &Log('WP', "Adding conflicting error counts") if $warn_if_duplicate_error;
      $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} += $value;
    }
  } else {
    $$duplicate_code_record_ref{$sumfile}{$flow}{$code} = 1;
    $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = $value;
  }
}


sub MergeLogDataIntoDataTable {

  my $data_table_ref = shift;
  my $log_record_ref = shift;
  my $duplicate_code_record_ref = shift;
  my $sumfile;
  my $flow;
  my $code;
  my $value;
  my $description;
  
  my $record_only = 1;
  my $warn_if_duplicate_code = 1;

  foreach $sumfile (sort keys %{ $data_table_ref }) {
    foreach $flow (sort keys %{ $log_record_ref }) {
      foreach $code (sort keys %{ $$log_record_ref{$flow} }) {
	$value = $$log_record_ref{$flow}{$code}{$VALUE_KEY};
	$description = $$log_record_ref{$flow}{$code}{$DESC_KEY};
	&RecordValue($data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, $value, $code, $description, $record_only, $warn_if_duplicate_code);
	&Log('QDI', "Logged value into data table: Flow: $flow  Code: $code  Value: $value") if $opt_debug;
      }
    }
  }
}


sub GenerateFlowCodePairs {

  my $data_table_ref = shift;
  my $merged_codes_table_ref = shift;
  my $sumfile;
  my $flow;
  my $code;
  
  foreach $sumfile (keys %{$data_table_ref}) {
    foreach $flow (keys %{$$data_table_ref{$sumfile}}) {
      foreach $code (keys %{$$data_table_ref{$sumfile}{$flow}}) {
	$$merged_codes_table_ref{$flow}{$code} = 
	  $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY};
      }
    }
  }
}


sub WriteSumCsv {

  my $csvoutfile = shift;
  my $csvfield_list_ref = shift;
  my $sumfile_list_ref = shift;
  my $data_table_ref = shift;
  my $merged_codes_table_ref = shift;
  my @value_list = ();
  my $record;
  my $sumfile;
  my $flow;
  my $code;
  my $value;
  
  
  open (CSVOUT, ">$csvoutfile") or die &Log('QE', "Could not open $csvoutfile for writing");
  my @header;
  my $field;
  foreach $field (@{$csvfield_list_ref}) {
    if (exists $$data_table_ref{$field}) {
      push(@header, $$data_table_ref{$field}{$BASE_EXE_NAME_UC}{'BASEFILE'}{$VALUE_KEY});
    } else {
      push(@header, $field);
    }
  }
  $record = join(',', @header);
  print CSVOUT "$record\n";
  foreach $flow (sort keys %{$merged_codes_table_ref}) {
    foreach $code (sort keys %{$$merged_codes_table_ref{$flow}}) {
      @value_list = ($flow, $code);
      foreach $sumfile (@ {$sumfile_list_ref}) {
	if (exists $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY}) {
	  $value = $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY};
	} else {
	  $value = 0;   # set to zero instead of ''
	}
	push (@value_list, $value);
      }
      push (@value_list, $$merged_codes_table_ref{$flow}{$code});
      $record = join(',', @value_list);
      print CSVOUT "$record\n";
      @value_list = ();
    }
  }
  close (CSVOUT);
}


sub ParsePremigLog {

  my $premiglog = shift;
  my $log_record_ref = shift;
  my $flow;
  my $code;
  my $value;
  my $description;

  if (-e $premiglog) {
    open (PREMIGLOG, $premiglog) or die &Log('QE', "Could not open $premiglog for reading\n");
    $flow = 'PREMIG';
    while (<PREMIGLOG>) {
      if (/isFUB.pl Query:\s+\S+\s+(\S+)/) {
	$value = $1;
	$code = 'FUB_TYPE';
	$$log_record_ref{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	$$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
      }
      if (/PDS:\s+\S+\s+(\d+)\s+total layout devices/) {
	$value = $1;
	$code = 'LAYOUT_DEVICES';
	$$log_record_ref{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	$$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
      }  
      if (/getCellHeightWidth: Cell\s+(\S+)\s+(Width|Height):\s(\S+)\s+u/) {
	my $xy = $1;
	my $heightwidth = uc($2);
	$code = "1264_${xy}_${heightwidth}";
	$value = $3;
	$$log_record_ref{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	$$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
      }
    }
    close (PREMIGLOG);
  }
}


sub ParseMigLog {

  my $miglog = shift;
  my $log_record_ref = shift;
  my $flow;
  my $code;
  my $value;
  my $description;
  
  if (-e $miglog) {
    open (MIGLOG, $miglog) or die &Log('QE', "Could not open $miglog for reading\n");
    $flow = 'MIG';
    while (<MIGLOG>) {
      if (/MIGLOG: \%USER\-I,\s+(.+)\s+\=\s+(\S+)/) {
	$value = $2;
	$code = uc($1);
	$code =~ s/\s+/_/g;
	$description = "Environment variable $code";
	$$log_record_ref{$flow}{$code}{$DESC_KEY} = $description;
	$$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
      }
      if (/MIGLOG:\s+\((\S+)\)\s+elapsed run time: (\d+)\s+days\s+(\d+)\s+hours\s+(\d+)\s+minutes\s+(\d+)/) {
	$code = uc($1);
	my $days = $2;
	my $hours = $3;
	my $minutes = $4;
	my $seconds = $5;
	
	$code =~ s/\s+/_/g;
	$code .= "_ELAPSED_TIME";
	$value = &ConvertElapsedTimeToSeconds($days, $hours, $minutes, $seconds);
	$description = "Elapsed time for flow in seconds: $code";
	$$log_record_ref{$flow}{$code}{$DESC_KEY} = $description;
	$$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
      }
      if (/TOPLOG: Max memory usage for all mig processes: NAME->(\S+)\s+PID->(\S+)\s+SIZE->(\d+)\s+(\S+)$/) {
	$code = uc($1);
	my $pid = $2;
	my $mem_value = $3;
	my $mem_units = $4;

	$code .= "_MEMORY";
	$description = "Max memory usage for process $code";
	$value = &ConvertTopMemToKBytes($mem_value, $mem_units);
	

	if (exists $$log_record_ref{$flow}{$code}{$VALUE_KEY}) {
	  if ($$log_record_ref{$flow}{$code}{$VALUE_KEY} < $value) {
	    $$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
	  }
	} else {
	  $$log_record_ref{$flow}{$code}{$DESC_KEY} = $description;
	  $$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
	}
      }
    }
    close (MIGLOG);
  } 
}


sub ParsePostmigLog {

  my $postmiglog = shift;
  my $log_record_ref = shift;
  my $flow;
  my $code;
  my $value;
  my $description;

  
  if (-e $postmiglog) {
    open (POSTMIGLOG, $postmiglog) or die &Log('QE', "Could not open $postmiglog for reading\n");
    $flow = 'POSTMIG';
    while (<POSTMIGLOG>) {
      if (/\-E\-/) {
	die &Log('QE', "Postmig run had error.");
      }
      if (/getCellHeightWidth: Cell\s+(\S+)\s+(Width|Height):\s(\S+)\s+u/) {
	my $xy = $1;
	my $heightwidth = uc($2);
	$value = $3;
	$code = "1266_${xy}_${heightwidth}";
	$$log_record_ref{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	$$log_record_ref{$flow}{$code}{$VALUE_KEY} = $value;
      }
    }
    close (POSTMIGLOG);
  }
}


sub CalcScaling {

  my $log_record_ref = shift;
  my $linear_scale;
  my $subcode;
  my $temp;
  my %code_map;
  my $flow;
  my $code;
  my $value;
  
  $code_map{'X_WIDTH'} = 'LAYOUT_X_SCALE';
  $code_map{'Y_HEIGHT'} = 'LAYOUT_Y_SCALE';
  $flow = uc($BASE_EXE_NAME);
  foreach $subcode ('X_WIDTH', 'Y_HEIGHT') {
    if (exists $$log_record_ref{'POSTMIG'}{"1266_${subcode}"}{$VALUE_KEY}) {
      if (exists $$log_record_ref{'PREMIG'}{"1264_${subcode}"}{$VALUE_KEY}) {
	$temp = ($$log_record_ref{'POSTMIG'}{"1266_${subcode}"}{$VALUE_KEY}/$$log_record_ref{'PREMIG'}{"1264_${subcode}"}{$VALUE_KEY});
	$value = sprintf("%.3f", $temp);
	$$log_record_ref{$flow}{$code_map{$subcode}}{$DESC_KEY} = $DESC_RECORD{$code_map{$subcode}};
	$$log_record_ref{$flow}{$code_map{$subcode}}{$VALUE_KEY} = $value;
      }
    }
  }
}
