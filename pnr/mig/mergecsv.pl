#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: mergecsv.pl,v 1.1 2004/12/17 19:49:51 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  mergecsv.pl			Project: Penryn
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
#* This script merges csv files from migreport.pl. Handy for Excel analysis.
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
use Cwd 'realpath';
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


# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -csvfile
                  [-help] [-debug] [-verbose]

flag descriptions:

-csvfile          Input cell name for analysis

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -csvfile <cell>.migreport.csv -csvfile <dir with migreport.csv files>

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
use vars qw(@opt_csvfile $opt_verbose $opt_help $opt_libflow $opt_debug);
$options_ok = &GetOptions("help",
			  "csvfile=s@",
			  "debug",
			  "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  print "-E- $EXE_NAME: One or more command line parameters incorrect.\n";
  print "$SPACER Use -help to list input flags.\n";
  die "\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-csvfile');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

# Constants

use vars qw($DESC_KEY $VALUE_KEY $FLOW_KEY $CODE_KEY $NODATA_CONST);
$DESC_KEY = 'DESCRIPTION';
$VALUE_KEY = 'VALUE';
$FLOW_KEY = 'FLOW';
$CODE_KEY = 'CODE';
$NODATA_CONST = '0';

# Variables

use vars qw($BASEFILE $MAINLOG);
$BASEFILE = "${BASE_EXE_NAME}";
my $mainlogbase = "${BASEFILE}.log";
$MAINLOG = "${mainlogbase}";
my $csvoutfile = "${BASEFILE}.csv";



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

if (-e $csvoutfile) {
  &Log('PW', "mergecsv.csv file detected. Will not be used as input.");
  &DeleteFiles($csvoutfile);
}


my $entry;
my $temp_csv_file;
my @temp_csv_file_list;
my @csvfile_list;
foreach $entry (@opt_csvfile) {
  if (-d $entry) {
    &Log('I', "Directory detected. Will harvest all .csv files from area:", $entry);
    opendir (CSVDIR, $entry) or die &Log('QE', "Could not open directory $entry for reading");
    @temp_csv_file_list = grep /.csv$/, readdir(CSVDIR);
    foreach $temp_csv_file (@temp_csv_file_list) {
      &Log('QI', "Files in input dir: $temp_csv_file");
      if ($entry eq '.') {
        push (@csvfile_list, $temp_csv_file);
      } else {
        push (@csvfile_list, "${entry}/${temp_csv_file}");
      }
    }
    closedir (CSVDIR);
  }
  elsif (-f $entry) {
    &Log('I', "File detected. Will harvest $entry.");
    push (@csvfile_list, $entry);
  }
}


my %data_table;
my $block_counter = 0;
my %block_alias_table;
my @block_list;

# For each sumfile
foreach my $csvfile (@csvfile_list) {
  # Open sumfile and process summary results
  &Log('I', "Parsing cvsfile: $csvfile");
  &ReadCsvFile($csvfile, \%data_table, \$block_counter, \%block_alias_table, \@block_list);
}

if ($opt_debug) {
  foreach my $block (sort keys %block_alias_table) {
    &Log('QDI', "Block alias: $block_alias_table{$block} -> $block");
  }
}

my $csvfile_count = scalar(@csvfile_list);
&Log('I', "$csvfile_count sumfiles were processed");

# Backfill any missing values with NO_DATA to fully populate the table
&BackfillCsv(\%data_table, \@block_list);

# Print output csv file
&WriteCsv($csvoutfile, \%data_table, \@block_list, \%block_alias_table);
&Log('I', "csvfile written: $csvoutfile");


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


sub ReadCsvFile {

  my $csvfile = shift;
  my $data_table_ref = shift;
  my $block_counter_ref = shift;
  my $block_alias_table_ref = shift;
  my $block_list_ref = shift;
  my @record;
  my $field_row_parsed = 0;
  my $block_alias;
  my @local_block_list;
  my $flow;
  my $code;
  my $description;
 
  open(CSVFILE, $csvfile) or die &Log('QE', "Could not open $csvfile for reading");
  while (<CSVFILE>) {
    # Split csv record;
    chomp;
    @record = split (/\,/, $_);
    unless ($field_row_parsed) {
      foreach my $column (@record) {
	if ($column =~ /_STM_|_LNF_/) {
	  $block_alias = "BLOCK$${block_counter_ref}";
	  $$block_alias_table_ref{$block_alias} = $column;
	  push(@local_block_list, $block_alias);
	  $$block_counter_ref++;
	}
      }
      push(@{$block_list_ref}, @local_block_list);
      $field_row_parsed = 1;
      next;
    }
    $flow = shift(@record);
    $code = shift(@record);
    foreach my $block (@local_block_list) {
      $$data_table_ref{$flow}{$code}{$block} = shift(@record);
    }
    $description = shift(@record);
    # A bit inefficient: last description for flow-code wins
    $$data_table_ref{$flow}{$code}{$DESC_KEY} = $description;
  }
  close (CSVFILE);
} 





sub BackfillCsv {

  my $data_table_ref = shift;
  my $block_list_ref = shift;

  foreach my $flow (sort keys %{ $data_table_ref }) {
    foreach my $code (sort keys %{ $$data_table_ref{$flow} }) {
      foreach my $block (sort @{ $block_list_ref }) {
	&Log('QDI', "Backfilling Out: Flow: $flow  Code: $code Block: $block") if $opt_debug;
	unless (exists $$data_table_ref{$flow}{$code}{$block}) {
	  &Log('QDI', "Backfilling In: Flow: $flow  Code: $code Block: $block") if $opt_debug;
	  $$data_table_ref{$flow}{$code}{$block} = $NODATA_CONST;
	}
      }
    }
  }
}


sub WriteCsv {
  
  my $csvoutfile = shift;
  my $data_table_ref = shift;
  my $block_list_ref = shift;
  my $block_alias_table_ref = shift;
  my $record;
  my @value_list;
  my $value;
  
  
  open (CSVOUT, ">$csvoutfile") or die &Log('QE', "Could not open $csvoutfile for writing");
  my @header = ($FLOW_KEY, $CODE_KEY);
  foreach my $block (@{ $block_list_ref }) {
    push (@header, $$block_alias_table_ref{$block});
  }
  push (@header, $DESC_KEY);
  $record = join(',', @header);
  print CSVOUT "$record\n";
  foreach my $flow (sort keys %{ $data_table_ref }) {
    foreach my $code (sort keys %{ $$data_table_ref{$flow} }) {
      @value_list = ($flow, $code);
      foreach my $block (@{ $block_list_ref }) {
	if (exists $$data_table_ref{$flow}{$code}{$block}) {
	  if ($block eq $DESC_KEY) {
	    next;
	  }
	  $value = $$data_table_ref{$flow}{$code}{$block};
	} else {
	  die &Log('QE', "Value did not exist. With backfilling this should not happen:",
		   "Flow: $flow  Code: $code  Block: $block");
	}
	push (@value_list, $value);
      }
      push (@value_list, $$data_table_ref{$flow}{$code}{$DESC_KEY});
      $record = join(',', @value_list);
      print CSVOUT "$record\n";
      @value_list = ();
    }
  }
}
