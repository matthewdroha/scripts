#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: mkmap.pl,v 1.1 2007/09/13 18:01:03 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  mkmap.pl			Project: Penryn
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
#* This script generates a pdb file and layer map file for layconv
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

my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -inputtech <tech file> -inputpdb <pdbfile> -outputmap <output mapfile>
flag descriptions:

-techfile         Input techfile from \$CAD_ROOT/techfiles

-pdbfile          Input pdb file

-outputmapfile    Output map file used as input to Sagantec layconv

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -techfile \$CAD_ROOT/techfiles/2.6/p1264.tech
Files that result from this run:

<cell>.${EXE_NAME}.layconvmap

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
use vars qw($opt_help $opt_debug $opt_verbose);
use vars qw($opt_inputtech $opt_inputpdb $opt_outputmap);
$options_ok = &GetOptions("help",
			  "inputtech=s",
			  "inputpdb=s",
			  "outputmap=s",
			  "debug",
			  "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  print "-E- $EXE_NAME: One or more command line parameters incorrect.\n";
  print "$SPACER Use -help to list input flags.\n";
  die "\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-inputtech', '-inputpdb');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

# Constants


# Variables
use vars qw($BASEFILE $MAINLOG);
$BASEFILE = "${BASE_EXE_NAME}";
my $mainlogbase = "${BASEFILE}.log";
$MAINLOG = "${mainlogbase}";

# Get script name
use vars qw($EXE_NAME $BASE_EXE_NAME);
$EXE_NAME = basename($0);
($BASE_EXE_NAME) = split(/\./,$EXE_NAME);

my $base_techfile = basename($opt_inputtech);
my $mapfile = "${base_techfile}.map";

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

my %tech_table;
&ReadDTTechFile($opt_inputtech, \%tech_table);
&ReadPdbFile($opt_inputpdb, \%tech_table);

if ($opt_debug) {
  foreach my $layer (sort keys %{ $tech_table{'MODTECH'} }) {
    foreach my $type (sort keys %{ $tech_table{'MODTECH'}{$layer} }) {
      &Log('QID', "DT TECH: layer: $layer  type: $type   value: $tech_table{'MODTECH'}{$layer}{$type}");
    }
  }
  foreach my $layer (sort keys %{ $tech_table{'PDB'} }) {
    foreach my $type (sort keys %{ $tech_table{'PDB'}{$layer} }) {
      &Log('QID', "PDB: layer: $layer  type: $type   value: $tech_table{'PDB'}{$layer}{$type}");
    }
  }
}

&GenerateLayconvMapFile(\%tech_table, $mapfile);

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


sub ReadDTTechFile {

  my $techfile = shift;
  my $tech_table_ref = shift;
  my $tag;
  my $value;
  
  
  open (TECHFILE, $techfile) or die;
  while (<TECHFILE>) {
    if (/\((\s*)generic\s+(\S+)\s+(\d+)\s+/) {
      $tag = $2;
      $value = $3;
      if ($tag =~ /LAYERNUM|DATATYPE/i) {
	$$tech_table_ref{'DTTECH'}{uc($tag)} = $value;
      }
    }
  }
  close (TECHFILE);
  
  my $newtag;
  my $layer;
  my $type;
  foreach my $tag (sort keys %{ $$tech_table_ref{'DTTECH'} }) {
    $newtag = $tag;
    $newtag =~ s/DEVICE|WIRE|TAP//;
    $newtag =~ s/ICVSDEBUG/FUSEID/;
    $newtag =~ s/NWELLRESISTOR/WELLRESID/;
    if ($newtag =~ /(\S+)(LAYERNUM|DATATYPE)/) {
      $layer = $1;
      $type = $2;
      $$tech_table_ref{'MODTECH'}{$layer}{$type} = $$tech_table_ref{'DTTECH'}{$tag};
    } else {
      print "tag: $tag\n";
      die "Something is wrong, unexpected value\n";
    }
  }
  # Manufacture port data type
  foreach $layer (sort keys %{ $$tech_table_ref{'MODTECH'} }) {
    if ($$tech_table_ref{'MODTECH'}{$layer}{'DATATYPE'} == 0) {
      my $portlayer = "${layer}PORTDRAWING";
      $$tech_table_ref{'MODTECH'}{$portlayer}{'LAYERNUM'} = $$tech_table_ref{'MODTECH'}{$layer}{'LAYERNUM'};
      $$tech_table_ref{'MODTECH'}{$portlayer}{'DATATYPE'} = $$tech_table_ref{'DTTECH'}{'PORTDATATYPE'};
    }
  }
}


sub ReadPdbFile {

  my $pdbfile = shift;
  my $tech_table_ref = shift;
  my $tag;
  my $value;
  my $posible_layer;
  my $layer;
  my $indent_count = 0;
  my $layernum = -1;
  my $datatype = -1;
  
  my $in_section_process = 0;
  my $in_section_layer = 0;
  my $streamin_found = 0;
  open (PDBFILE, $pdbfile) or die;
  while (<PDBFILE>) {
    if (/^\s+process\s+\{/i) {
      $in_section_process = 1;
    }
    if ($in_section_process) {
      if (/^\s+layers\s+\{/i) {
	$in_section_layer = 1;
	$indent_count = 0;
      }
      if ($in_section_layer) {
	if ((/^\s+(\S+)\s+\{/i) and ($indent_count==1)) {
	  $layer = $1;
	}
	if (/streamin/i) {
	  $streamin_found = 1;
	}
	if (/^\s+gds2_nr\s+\{\s*(\d+)\s*\}/) {
	  $layernum = $1;
	}
	if (/^\s+gds2_datatype\s+\{\s*(\d+)\s*\}/) {
	  $datatype = $1;
	}
	if (/\{/) {
	  $indent_count++;
	}
	if (/\}/) {
	  $indent_count--;
	  if ($indent_count == 1) {
	    if ($streamin_found) {
	      &Log('QID', "Recording PDB record for layer: $layer datanum: $layernum datatype: $datatype") if $opt_debug;
	      unless ($layernum == -1 or $datatype == -1) {
		$$tech_table_ref{'PDB'}{$layer}{'LAYERNUM'} = $layernum;
		$$tech_table_ref{'PDB'}{$layer}{'DATATYPE'} = $datatype;
		$streamin_found = 0;
		$layernum = -1;
		$datatype = -1;
	      } else {
		&Log('QID', "Found invalid layernum or datatype. Skipping entry") if $opt_debug;
	      }
	    } else {
	      &Log('QWD', "Got through a layer without a streamin def found: $layer") if $opt_debug;
	    }
	  }
	  elsif ($indent_count == 0) {
	    last;
	  }
	}
      }
    }
  }
}



sub GenerateLayconvMapFile {

  my $tech_table_ref = shift;
  my $outmapfile = shift;
  my $dtlayernum;
  my $dtdatatype;
  my $pdblayernum;
  my $pdbdatatype;
  my $dt_layer_and_datatype_in_pdb = 0;

  open (OUTMAP, ">$outmapfile") or die &Log('QE', "Could not open $outmapfile for writing");
  foreach my $dtlayer (sort keys %{ $$tech_table_ref{'MODTECH'} }) {
    $dt_layer_and_datatype_in_pdb = 0;
    if (exists $$tech_table_ref{'MODTECH'}{$dtlayer}{'LAYERNUM'}) {
      $dtlayernum = $$tech_table_ref{'MODTECH'}{$dtlayer}{'LAYERNUM'};
    } else {
      unless ($dtlayer eq 'PORT') {
	die &Log('QE', "layer: $dtlayer does not have a LAYERNUM entry");
      } 
    }
    if (exists $$tech_table_ref{'MODTECH'}{$dtlayer}{'DATATYPE'}) {
      $dtdatatype = $$tech_table_ref{'MODTECH'}{$dtlayer}{'DATATYPE'};
    } else {
      die &Log('QE', "layer: $dtlayer does not have a DATATYPE entry");
    }
    foreach my $pdblayer (sort keys %{ $$tech_table_ref{'PDB'} }) {
      if (exists $$tech_table_ref{'PDB'}{$pdblayer}{'LAYERNUM'}) {
	$pdblayernum = $$tech_table_ref{'PDB'}{$pdblayer}{'LAYERNUM'};
      } else {
	die &Log('QE', "layer: $pdblayer does not have a LAYERNUM entry");
      }
      if (exists $$tech_table_ref{'PDB'}{$pdblayer}{'DATATYPE'}) {
	$pdbdatatype = $$tech_table_ref{'PDB'}{$pdblayer}{'DATATYPE'};
      } else {
	die &Log('QE', "layer: $pdblayer does not have a DATATYPE entry");
      }    
      if (($dtlayernum == $pdblayernum) and ($dtdatatype == $pdbdatatype)) {
	&Log('QID', "DT layernum and datatype is in PDB: layer: $dtlayer layernum: $dtlayernum  dataype: $dtdatatype") if $opt_debug;
	$dt_layer_and_datatype_in_pdb = 1;
	last;
      }
    }
    unless (($dt_layer_and_datatype_in_pdb) or ($dtlayer eq 'PORT')) {
      print OUTMAP "$dtlayer $dtlayernum $dtdatatype\n";
    }
  }
  close (OUTMAP);
}
