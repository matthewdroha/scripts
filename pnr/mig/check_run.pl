#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: check_run.pl,v 1.2 2004/09/18 22:47:45 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  check_run.pl			Project: Penryn
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
#* This script reports the status of the premig run. It will be incorporated
#* into the eventual migtool framework
#* 
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


# Disable command buffering 
$| = 1;


# Define standard libs used
use strict;
use warnings;
use English;
use File::Basename;
use File::Copy;
use Getopt::Long;
use Time::Local;
use Cwd;


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
use vars qw($DB_ROOT $PROJECT $NIKE_NETLISTER $PROJ_SKILL);
use vars qw($WORK_AREA_ROOT_DIR $DMSPATH $PDSPATH);
my @env_list = ('DB_ROOT', 'PROJECT', 'NIKE_NETLISTER', 'PROJ_SKILL');
@env_list = (@env_list, 'WORK_AREA_ROOT_DIR', 'DMSPATH', 'PDSPATH');

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
usage:  $EXE_NAME -celllist <cell list file> [-help] [-debug] [-verbose]

flag descriptions:

-celllist         Contains the list of cells to process. Assumed a csv
                  file with first field list of cell names, so a list
                  of cells seperated by newlines is OK as input.

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT. 

-help             This usage message will appear. 

Files that result from this run:

${EXE_NAME}.csv

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
use vars qw($opt_celllist $opt_debug $opt_verbose $opt_help);
$options_ok = &GetOptions("help",
                          "celllist=s",
			  "debug",
			  "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  print "-E- $EXE_NAME: One or more command line parameters incorrect.\n";
  print "$SPACER Use -help to list input flags.\n";
  die "\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-celllist');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
use vars qw(@TMPFILES_LIST);
@TMPFILES_LIST = ();
&DeleteFiles;   # Do this to make sure everything is cleaned up before we start
&PushFilesToTemporaryList;


##### Main Program #####

# Constants

use vars qw($YES_CONST $NO_CONST $NAME_CONST);
use vars qw($NETLOG_FOUND_CONST $NETLOG_FATAL_CONST $NETLOG_ERROR_CONST $NETLOG_WARN_CONST);
use vars qw($SN_FOUND_CONST $PDS_SUM_FOUND_CONST $CMP_ERROR_CONST);
use vars qw($CMP_WARN_CONST $GENESYS_STM_FOUND_CONST @CSVFIELDS);

$YES_CONST = 'OK';
$NO_CONST = 'NO';
$NAME_CONST = 'Cell Name';
$NETLOG_FOUND_CONST = 'Netlist Log Found';
$NETLOG_FATAL_CONST = 'Netlisting Fatals';
$NETLOG_ERROR_CONST = 'Netlisting Errors';
$NETLOG_WARN_CONST = 'Netlisting Warnings';
$SN_FOUND_CONST = 'SN Found';
$PDS_SUM_FOUND_CONST = 'PDS Sum Found';
$CMP_ERROR_CONST = 'CVSCMP Errors';
$CMP_WARN_CONST = 'CVSCMP Warnings';
$GENESYS_STM_FOUND_CONST = 'STM Found (Genesys)';

@CSVFIELDS = ($NETLOG_FOUND_CONST, $NETLOG_FATAL_CONST, $NETLOG_ERROR_CONST, $NETLOG_WARN_CONST);
@CSVFIELDS = (@CSVFIELDS, $SN_FOUND_CONST, $PDS_SUM_FOUND_CONST, $CMP_ERROR_CONST);
@CSVFIELDS = (@CSVFIELDS, $CMP_WARN_CONST, $GENESYS_STM_FOUND_CONST);



# Variables

use vars qw($BASEFILE $MAINLOG $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${BASE_EXE_NAME}";
$MAINLOG = "${WARD}/${BASEFILE}.log";

my $csvoutfile = "${WARD}/${BASEFILE}.csv";
my %cell_record;
my $cell;


# Set the working directory to WARD
chdir ($WARD) or die "-E- $EXE_NAME: Could not change script working dir to $WARD\n";

# Open the main log file
open(MAINLOG, ">$MAINLOG") or die "-E- $EXE_NAME: Could not open $MAINLOG for writing\n";
select(MAINLOG);
$| = 1;
select (STDOUT);

# Add function to check for zero size files

# Read in Gallery-like input list
&OpenCelllist($opt_celllist, \%cell_record);
# For each fub in the list
foreach $cell (keys %cell_record) {
  # Check if nike_netlist log exists and capture fatals, errors, warnings
  # Check if SN Exists
  #&ScanNetlistingRun($cell, \%cell_record);
  # Check if .sum file Exists and capture cvscmp errors and warnings
  # Check if stm file exists
  # Run TRCSTD on the new set of stm files
  print "Cell: $cell\n";
  &RunISSTrcstd($cell, 'stm');
}

&Log('I', "$START_TIME Run Started.");
&Log('QI', "Script started: $EXE_NAME $COMMAND_LINE");
&DeleteFiles(@TMPFILES_LIST) unless $opt_debug;
use vars qw($STOP_TIME);
$STOP_TIME = &GetDate;
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
    if (-e $file) {
      unlink ($file)
      }
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
#                  "this string by default, no 'P' directive needed);

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


sub OpenCelllist {

  my $cell_list_file = shift;
  my $cell_record_ref = shift;
  my @record;

  open (CELLLIST, $cell_list_file) or die &Log('QE', "Could not open $cell_list_file for reading");
  while (<CELLLIST>) {
    @record = split(/,/, $_);
    chomp $record[0];
    $$cell_record_ref{$record[0]}{$NAME_CONST} = $record[0];
  }
  close (CELLLIST);
}


sub ScanNetlistingRun {

  my $cell = shift;
  my $cell_record_ref = shift;
  my $outnetlistlog = "$WARD/netlists/${cell}__sch_to_Snsch__nike_netlister.log";
  my $outnetlist = "$WARD/netlists/cvssch/${cell}.sn";

  if (-e $outnetlistlog) {
    $$cell_record_ref{$cell}{$NETLOG_FOUND_CONST} = $YES_CONST;
    open (OUTNETLOG, $outnetlistlog) or die &Log('QE', "Could not open $outnetlistlog for reading");
    while (<OUTNETLOG>) {
    }
  }   
}


sub ScanISSRun {

  my $cell = shift;
  my $cell_record_ref = shift;
  my $pdssumfile = "${WARD}/pds/logs/${cell}.trcstd.iss.log.sum";
  
  if (-e $pdssumfile) {
    $$cell_record_ref{$cell}{$PDS_SUM_FOUND_CONST} = $YES_CONST;
    open (PDSSUMFILE, $pdssumfile) or die &Log('QE', "Could not open $pdssumfile for reading");
    while (<PDSSUMFILE>) {
    }
  }
}

sub RunISSTrcstd {

  my $cell = shift;
  my $inputtype = shift;

  # ADDIN: Clean all pre-existing files: .abort, .sum, .log, .cell, .data
  # Add mode to input parameters
  # Add batch capability to this function
  $ENV{'PDSBATCHER'} = '/usr/intel/bin/nbq';
  $ENV{'PDSBATCHLINE'} = '-P MPG_IALcs -C P4 -Q 22';

  system("$PDSPATH/_pdsbuilder.new -database ' ' -laytopcell $cell -mode trcstd -saveworkdir no -mailuser no -ecn ECNOFF -runmode batch -incremental no -newinc ' ' -autotail no -signallist ' ' -verifytool cmp -inputtype $inputtype -trcpin top -commandfile ' ' -laychangefile ' ' -topframe nocheck -outtype apl -sigfiles ' ' -skipcvsin no -calcres no -batch1 HIDE -skewtype TTTT -tooltype iss -explode DEFAULT -autohmsprt no -smshopt relax -dvssmshfile none -ltlinpath none -ltloutpath none -groupdir none -chkptdir none -libspec $cell -lnpath ' ' -batch2 HIDE -batch3 HIDE -onecell no -crosscap none -make_sn 1 -fg yes -snname DEFAULT >& /dev/null");

  # ADDIN: Confirm sum file was created and has valid contents

}   




















