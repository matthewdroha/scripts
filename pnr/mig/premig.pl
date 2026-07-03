#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: premig.pl,v 1.19 2005/01/24 05:57:19 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  premig.pl			Project: Penryn
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
#* - Preps DMS path
#* - Netlist (SN from SCH)
#* - LNF Capture (megacontainer or oth removal)
#* - ISS TRCSTD (LNF)
#* - LNF via marker addition
#* - LNF->GDSII Using Genesys (no polygon merging)
#* - Text stripping of GDSII
#* - PDSXOR run on GDSII vs original LNF (there are differences, not fatal)
#* - ISS TRCSTD (GDSII)
#* - CIF generation
#* 
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# Disable command buffering 
$| = 1;


# Define standard libs used

# Temporary until we get a central release area built
unshift @INC, "/nfs/iil/disks/home10/mroha/pnr/mig";
unshift @INC, "/usr/users/home2/mroha/pnr/mig";
require GDS2;
# The GDS2 package is unaltered from its original distribution
# As per the Perl Artistic License, it use in this case is fine
# as long as Ken's original package is unaltered
use strict;
use warnings;
use English;
use File::Basename;
use File::Copy;
use File::Path;
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
use vars qw($WORK_AREA_ROOT_DIR $DMSPATH $PDSPATH $GENESYS_DIR);
use vars qw($PDSSTM $PROCESS_NAME $SAGROOT $PDSLOGS $DA_UTILS);
use vars qw($NIKE_TECH_DIR $CAD_ROOT $USERCFGFILE $MODEL);
my @env_list = ('DB_ROOT', 'PROJECT', 'NIKE_NETLISTER', 'PROJ_SKILL');
@env_list = (@env_list, 'WORK_AREA_ROOT_DIR', 'DMSPATH', 'PDSPATH');
@env_list = (@env_list, 'GENESYS_DIR', 'PDSSTM', 'PROCESS_NAME', 'SAGROOT');
@env_list = (@env_list, 'PDSLOGS', 'DA_UTILS', 'NIKE_TECH_DIR', 'CAD_ROOT');
@env_list = (@env_list, 'USERCFGFILE', 'MODEL');

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
usage:  $EXE_NAME -cell <input cell> [-nofub] 
                  [-help] [-debug] [-verbose]

flag descriptions:

-cell             Input cell name

-nofub            Skips DMSPATH recompile and fub authentication routines    

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend
         $EXE_NAME -cell tm0bin00i0 -nofub

Files that result from this run:

<cell>.stm
<cell>.sn

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
use vars qw($opt_cell $opt_nofub $opt_debug $opt_verbose $opt_help $opt_archive);
$options_ok = &GetOptions("help",
			  "cell=s",
			  "nofub",
                          "archive",
			  "debug",
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

if ($opt_archive and $opt_nofub) {
  print "-E- $EXE_NAME: -archive not supported for -nofub at this time.\n";
  die "\n";
}


##### Main Program #####

# Constants

# At some point define the legal set of nike netlister input/outputs


# Variables
my $cell_lc = lc($opt_cell);

use vars qw($BASEFILE $MAINLOG $WARD $GDSII_RESOLUTION $GDSII_USERUNITS);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${BASE_EXE_NAME}";
$MAINLOG = "${WARD}/${BASEFILE}.log";
$GDSII_RESOLUTION = "1000";
$GDSII_USERUNITS = "0.001";

my @genesys_tcl_modules_list = ("/nfs/iil/disks/home10/mroha/pnr/mig/mig.tcl");
my %techfile;
$techfile{'PDB'}{$PROCESS_NAME} = "/nfs/iil/disks/home10/mroha/pnr/mig/migrate${PROCESS_NAME}.pdb";
$techfile{'NIKE'}{$PROCESS_NAME} = "${NIKE_TECH_DIR}/p${PROCESS_NAME}.tech";
$techfile{'CAR'}{$PROCESS_NAME} = "${NIKE_TECH_DIR}/p${PROCESS_NAME}.car";

my $newdmspath = "${WARD}/dms.pth.${BASEFILE}";
my $lnf2stmlog = "${WARD}/${BASEFILE}.lnf2stm";
my $layconvlog = "${WARD}/${BASEFILE}.layconv";
my $genesyslnfdir = "${WARD}/genesys/lnf/${BASE_EXE_NAME}_${cell_lc}";
my $genesysstmdir = "${WARD}/genesys/stm";  # DMSPATH assumption
my $lnfprefix = "";  # In this script, this needs to be empty so GDSII cell names are preserved
my $basestm = "${cell_lc}.stm";
my $basestmorig = "${cell_lc}.stm.genesys";
my $basestmnotxt = "${cell_lc}.stm.no_txt";
my $basecif = "${cell_lc}.cif";
my $genesysstm = "${genesysstmdir}/${basestm}";
my $pdsstm = "${PDSSTM}/${basestm}";
my $layconvcif = "${PDSSTM}/${basecif}";
my $pdsstmnotxt = "${PDSSTM}/${basestmnotxt}";
my $pdsstmorig = "${PDSSTM}/${basestmorig}";
my $pdscif = "${PDSSTM}/${basecif}";
my $genesys_open_flag = "${WARD}/genesys/${BASEFILE}.genesysopen_flag";
my $explodelist = "${WARD}/${BASEFILE}.explode";
my $mapfile = "${WARD}/${BASEFILE}.layconvmap";

my @uemodel_list;
if ($opt_nofub) {
  @uemodel_list = ($MODEL);
  &Log('W', "-nofub option detected.",
       "Flow will not validate fub name or attempt to configure DMSPATH");
} else {
  @uemodel_list = ('1266_migration', 'lor2');
}

unless ($GENESYS_DIR =~ /5\.1/) {
  die &Log('QE', "You must be running Genesys version 5.1 or later to run this flow");
}


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
use vars qw(@TMPFILES_LIST);
@TMPFILES_LIST = ();
&DeleteFiles($newdmspath, $lnf2stmlog, $layconvlog, $genesysstm, $pdsstm, $layconvcif);
&DeleteFiles($pdsstmnotxt, $pdsstmorig, $pdscif, $genesys_open_flag, $explodelist, $mapfile);
&PushFilesToTemporaryList($genesys_open_flag);


# Set the working directory to WARD
chdir ($WARD) or die "-E- $EXE_NAME: Could not change script working dir to $WARD\n";

# Open the main log file
open(MAINLOG, ">$MAINLOG") or die "-E- $EXE_NAME: Could not open $MAINLOG for writing\n";
select(MAINLOG);
$| = 1;
select (STDOUT);

&Log('I', "$START_TIME Run Started.");
&Log('I', "Script started: $EXE_NAME $COMMAND_LINE");

# Make sure we can't mess with the ATF database
$ENV{'ATF_LOCKED'} = 'YES';

unless ($opt_nofub) {
  # Validate that the fub entry is indeed a fub
  &Log('I', "Checking fub=${cell_lc} is a valid fub in MRM...");
  &ValidateFubExists($cell_lc);
}

my $models = join(' ', @uemodel_list);
&Log('I', "The following UE models will be searched for TRC/CMP clean data: $models");

my %explode_record;
$explode_record{'DELETE'}{"${cell_lc}_megacontainer"} = 1;
$explode_record{'DELETE'}{"${cell_lc}_oth"} = 1;
&GenerateExplodeList(\%explode_record, $explodelist);


my $rundirty;
my $gdsintp = 0;
my $pdssum;
my $orig_dmspath = $DMSPATH;
foreach my $model (@uemodel_list) {
  &Log('I', "Starting search for CMP clean data on model: ($model)");
  # Recompile DMSPATH for specific fub
  &Log('I', "Compiling dmspath for UE model...");
  unless ($opt_nofub) {
    $ENV{'DMSPATH'} = $DMSPATH = $orig_dmspath;  # Reset so compiler can read original modes file
    &RecompileDmspath($cell_lc, $model, $newdmspath);
    $ENV{'DMSPATH'} = $DMSPATH = $newdmspath;
  }
  # Run nike netlister on cell to generate SN file
  &Log('I', "Running nike_netlister to generate SN...");
  $rundirty = &RunNikeNetlister($cell_lc, 'sch', 'snsch');
  if ($rundirty) {
    &Log('I', "Netlist run DIRTY for model: ($model)");
    next;
  }
  # Run PDS TRCSTD on LNF
  # Use explode list to remove megacontainer and oth cell
  &Log('I', "Running ISS TRCSTD (LNF Input)...");
  ($rundirty, $pdssum) = &RunISSTrcstd($cell_lc, 'lnf', $explodelist, $gdsintp);
  if ($rundirty) {
    &Log('I', "PDS TRCSTD (LNF Input) run DIRTY for model: ($model)");
  } else {
    &Log('I', "PDS TRCSTD (LNF Input) run CLEAN for model: ($model)");
    last;
  }
}

if ($rundirty) {
  die &Log('QE', "Could not find clean netlist/CMP run for any target UE models");
}


# Call Genesys and convert LNF->GDSII
&Log('I', "Starting Genesys and creating editable LNF image...");
# Pre-deleted .stm file until I can dig up the UDM function
# to force the save with no prompting

# Open session and set up for stream writing
my $genesysfh = &GenesysOpenSession($lnf2stmlog);
&GenesysSetStmOptions($genesysfh);
&GenesysCommandLine('set cvm [::boo::CellViewMgr_getCellViewMgr]', $genesysfh);
&GenesysCommandLine('$cvm setSaveBackups 0', $genesysfh);

# Make editable copy of LNFs (where is edbit?)
my $readonly = 1;
&GenesysOpenCell($cell_lc, 'lnf', '', $readonly, $genesysfh);
&GenesysSaveAllWithPrefix($cell_lc, 'lnf', $lnfprefix, $genesyslnfdir, $genesysfh);
&GenesysDiscardAll($genesysfh);
&GenesysTouchAndWaitForFile($genesys_open_flag, $genesysfh);

# Open editable copy of top level, precondition LNF for stream writing, and save stm
# This is a serious pain with Genesys
&Log('I', "Preprocessing LNF files...");
$readonly = 0;
&GenesysOpenCell("${lnfprefix}${cell_lc}", 'lnf', $genesyslnfdir, $readonly, $genesysfh);
&GenesysLoadModules(\@genesys_tcl_modules_list, $genesysfh);
foreach my $targetcell (sort keys %{ $explode_record{'DELETE'} }) {
  &GenesysCommandLine("::mig::deleteCell $targetcell", $genesysfh);
}
#&GenesysCommandLine('::mig::markLanding', $genesysfh);
#&GenesysCommandLine('::mig::fixSlivCont', $genesysfh);
&GenesysCommandLine('::mig::getCellHeightWidth', $genesysfh);
&GenesysSaveStm($cell_lc, $genesysfh);
&GenesysCloseSession($genesysfh);
&CheckGenesysPreProcess($lnf2stmlog);

# Confirm stm was written and move to $PDSSTM
if (-e $genesysstm) {
  unless (copy ($genesysstm, $pdsstm)) {
    die &Log('QE', "Could not copy .stm from Genesys area to PDS area");
  }
} else { 
  die &Log('QE', "Genesys .stm file was not generated.");
}

# Strip text from GDSII
&Log('I', "Stripping text from STM file...");
&StripTextFromStm($pdsstm, $pdsstmnotxt);
unless (rename($pdsstm, $pdsstmorig)) {
  die &Log('QE', "Could not rename stm file:",
	   "From: $pdsstm",
	   "To: $pdsstmorig");
}
unless (symlink ($pdsstmnotxt, $pdsstm)) {
  die &Log('QE', "Could not link to stm file:",
	   "$pdsstmnotxt");
}

# Run PDSXOR between stripped STM and original LNF data
&Log('I', "Running XOR between LNF and text stripped STM for data collection.");
my @pdsstm_opts = ("-cell1 $cell_lc", "-data1 stm", "-stm1 $pdsstmorig");
@pdsstm_opts = (@pdsstm_opts, "-data2 stm", "-stm2 $pdsstmnotxt");
$rundirty = &RunPdsXor($cell_lc, $cell_lc, 'lnf', 'stm', "-stm2 $pdsstmnotxt");
#if ($rundirty) {
#   die &Log('QE', "PDSXOR between LNF and final STM was dirty... probably SLIVCONT issue");
#} 


# Run PDS TRCSTD on non-texted stm
&Log('I', "Running ISS TRCSTD (STM Input)...");
$gdsintp = 1;
($rundirty, $pdssum) = &RunISSTrcstd($cell_lc, 'stm', '', $gdsintp);
if ($rundirty) {
  # Need to do this for this special case. Will not impact Sagantec
  &Log('W', "ISS TRCSTD (STM Input) run was dirty. Checking for glbdrv_exe opens waiver...");
  $rundirty = &WaiveGlbdrvOpens($pdssum);
  if ($rundirty) {
    die &Log('QE', "PDS TRCSTD (STM Input) run completed, but was dirty");
  } else {
    &Log('I', "ISS TRCSTD (STM Input) run has opens but all issues were waivable");
  }   
}
if ($rundirty) {
  die &Log('QE', "PDS TRCSTD (STM Input) run completed, but was dirty");
}

# Generate layconv map file
&Log('I', "Generating layer map file for layconv (eliminate multivalue props)...");
my %tech_table;
&ReadDTTechFile($techfile{'NIKE'}{$PROCESS_NAME}, \%tech_table);
&ReadPdbFile($techfile{'PDB'}{$PROCESS_NAME}, \%tech_table);

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

# Generate CIF files
&Log('I', "Running Sagantec Layconv (STM->CIF)...");
&SagantecLayconv($pdsstm, 'stm', $layconvcif, 'cif', $techfile{'PDB'}{$PROCESS_NAME}, $mapfile, $layconvlog);

open (LAYCONVLOG, $layconvlog) or die &Log('QE', "Could not open $layconvlog for reading");
while (<LAYCONVLOG>) {
  chomp;
  &Log('QI', "LAYCONV: $_");
}
close (LAYCONVLOG);

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


# Creates specified directory tree
sub CreateDirTree {

  my $targetdir = shift;
  my $dir;

  unless (-d $targetdir) {
    foreach $dir (mkpath($targetdir, 0, 0755)) {
      unless (-d $dir) {
	return 0;
      }
    }
  }
  return 1;
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

# Fub is assumed to be the proper case (in this case, lower case)
sub ValidateFubExists {
  my $fub = shift;
  my $fubfile = "${WARD}/${BASEFILE}.check";
  my $foundfub = 0;
  my $fubquery; 
  
  $fubquery = "$PROJ_SKILL/gallery/bin/users_request/isFub.pl $PROJECT $fub";
  open (FUBQUERY, "$fubquery |") or die &Log('QE', "Could not open fub query:", $fubquery);
  while (<FUBQUERY>) {
    if (/^\s*(\S+)\s+/) {
      if (($1 ne 'Block') and ($1 eq $fub)) {
	$foundfub = 1;
      }
      chomp;
      &Log('QI', "isFUB.pl Query: $_");
    }
  }
  close (FUBQUERY);
  unless ($foundfub) {
    die &Log('QE', "fub=$fub is not a valid fub name");
  } 
}

  
sub RecompileDmspath {

  my $dbb = shift;
  my $model = shift;
  my $newdmsfile = shift;

  # Add proper variable path
  $ENV{'DBB'} = $dbb;
  $ENV{'MODEL'} = $model;
  system("(dmsCompiler_new.pl -usercfgfile /p/mpg/proc/common/proj_tools/t00/mrm_3.3/setup/t00_lib.ver -dbtypes lay sch flp dev sim net ctl  > $newdmsfile) >& /dev/null");

  # Confirm existance of new file
  unless (-e $newdmsfile) {
    die &Log('QE', "New dmspth file: $newdmsfile was not created properly for dbb $dbb");
  }
}


sub RunNikeNetlister {

  my $cell = shift;
  my $inputformat = shift;
  my $outputformat = shift;
  my $outnetlist;
  my $outnetlistlog;
  my $summary_found = 0;
  my $fatal_count;
  my $error_count;
  my $warning_count;
  my $run_is_dirty = 0;
  
  # Remove previous netlist (future: key off of input format);
  $outnetlistlog = "$WARD/netlists/${cell}__sch_to_Snsch__nike_netlister.log";
  $outnetlist = "$WARD/netlists/cvssch/${cell}.sn";
  &DeleteFiles($outnetlist, $outnetlistlog);

  system("$NIKE_NETLISTER -cell $cell -inf $inputformat -remp none -outf $outputformat >& /dev/null");

  # Confirm there were no errors in the log file
  open (OUTNETLISTLOG, $outnetlistlog) or die &Log('QE', "Could not open $outnetlistlog for reading");
  while (<OUTNETLISTLOG>) {
    if (/Fatals:\s+(\d+)\s+Errors:\s+(\d+)\s+Warnings:\s+(\d+)/) {
      $fatal_count = $1;
      $error_count = $2;
      $warning_count = $3;
      $summary_found = 1;
      chomp;
      &Log('QI', "NIKE_NETLISTER: $_");
      last;
    }
  }
  close (OUTNETLISTLOG);

  if ($summary_found) {
    if (($fatal_count ne '0') or ($error_count ne '0')) {
      &Log('PW', "Fatals/errors occured during nike_netlister run.",
	       "See $outnetlistlog");
      $run_is_dirty = 1;
    }
    if ($warning_count ne '0') {
      &Log('PW', "Warnings occured during nike_netlister run.",
	   "See $outnetlistlog");
    }
  } else {
    die &Log('QE', "Nike netlister log was found, but no summary was contained in file",
	     "See $outnetlistlog");
  }
  # Confirm output netlist was generated, die otherwise

  return $run_is_dirty;
  unless (-e $outnetlist) {
    die &Log('QE', "Output netlist was not found, yet nike netlister log is OK",
	     "See $outnetlistlog");
  }
}


sub RunISSTrcstd {

  my $cell = shift;
  my $inputtype = shift;
  my $explodelist = shift;
  my $use_gdsintp = shift;
  my $pdscellfile = "$PDSLOGS/${cell}.cell.log";
  my $pdsdatafile = "$PDSLOGS/${cell}.data.log";
  my $pdsexpfile = "$PDSLOGS/${cell}.explode.list";
  my $pdslogfile = "$PDSLOGS/${cell}.trcstd.iss.log";
  my $pdssumfile = "$PDSLOGS/${cell}.trcstd.iss.log.sum";
  my $pdscmpfile = "$PDSLOGS/${cell}.standard.iss.cmp";
  my $pdscmpallfile = "$PDSLOGS/${cell}.standard.iss.cmpall";
  my $pdsanfile = "$PDSLOGS/${cell}.analysis";
  my $pdslnsfile = "$PDSLOGS/${cell}.iss.lns";
  my $pdspinsfile = "$PDSLOGS/${cell}.sch_pins";
  my $pdsstatsfile = "$PDSLOGS/${cell}_trcstd.stats";
  my $pdsabortfile = "$PDSLOGS/${cell}.trcstd.iss.log.abort";
  my @pdsfiles;
  my $run_is_dirty = 0;

  @pdsfiles = ($pdscellfile, $pdsdatafile, $pdsexpfile, $pdslogfile, $pdssumfile);
  @pdsfiles = (@pdsfiles, $pdscmpfile, $pdscmpallfile, $pdsanfile, $pdslnsfile);
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

  unless (-f $explodelist) {
    $explodelist = 'DEFAULT';
  }

  system("$PDSPATH/_pdsbuilder.new -database ' ' -laytopcell $cell -mode trcstd -saveworkdir no -mailuser no -ecn ECNOFF -runmode local -incremental no -newinc ' ' -autotail no -signallist ' ' -verifytool cmp -inputtype $inputtype -trcpin top -commandfile ' ' -laychangefile ' ' -topframe nocheck -outtype apl -sigfiles ' ' -skipcvsin no -calcres no -batch1 HIDE -skewtype TTTT -tooltype iss -explode $explodelist -autohmsprt no -smshopt relax -dvssmshfile none -ltlinpath none -ltloutpath none -groupdir none -chkptdir none -libspec $cell -lnpath ' ' -batch2 HIDE -batch3 HIDE -onecell no -crosscap none -make_sn 1 -fg yes -snname DEFAULT >& /dev/null");

  # Confirm sum file was created and has valid contents
  if (-e $pdsabortfile ) {
    die &Log('QE', "PDS TRCSTD run aborted.",
	     "See $pdsabortfile");
  }
  open (PDSSUM, $pdssumfile) or die &Log('QE', "Could not open $pdssumfile for reading");
  while (<PDSSUM>) {
    if (/^\s*(DIRTY|clean|(Total\s+\d+\s+\d+))|lay\s+sch|[dD]evices|Unmatched|Nodes|Input Data Type/) {
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


sub WaiveGlbdrvOpens {

  my $pdssum = shift;
  my $trcstd_dirty = 0;
  my $run_is_dirty = 1;
  my $in_open_circuit_section = 0;
  my $flow;
  my $cell;
  my $signal;

  open (PDSSUM, $pdssum) or die &Log('QE', "Could not open $pdssum for reading");
  while (<PDSSUM>) {
    if (/^DIRTY\s+(\S+)/) {
      $flow = $1;
      if ($flow eq 'trcstd') {
	$trcstd_dirty = 0;
      } else {
	$run_is_dirty = 1;
	last;
      }
    }
    if (/SHORT_CIRCUITS:/) {
      $run_is_dirty = 1;
      last;
    }
    if (/OPEN_CIRCUITS:/) {
      $in_open_circuit_section = 1;
    }
    if ($in_open_circuit_section) {
      if (/^(\S+)\s+(\S+)\s+\d+\;\s+/) {
	$cell = $1;
	$signal = $2;
	chomp;
	&Log('QDW', "WaiveGlbdrvOpens: $_") if $opt_debug;
	unless (($cell eq 'glbdrv_exe') and ($signal eq 'clkout')) {
	  $run_is_dirty = 1;
	  last;
	}
      }
      # Made it
      if (/FLOW = cvscmp/) {
	$run_is_dirty = 0;
	last;
      }
    }
  }  
  close (PDSSUM);
  return $run_is_dirty;
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


sub GenesysTouchAndWaitForFile {

   my $flagfile = shift;
   my $genesysfh = shift;
   my $parentfh = select($genesysfh);

   if (-e $flagfile) {
     die &Log('QE', "Flagfile detected before polling started:", $flagfile);
   }
   print "exec touch $flagfile\n";
   &PollForFile($flagfile);

   select($parentfh);
}


sub CheckGenesysPreProcess {

  my $genesyslog = shift;

  open (GENESYSLOG, $genesyslog) or die &Log('QE', "Could not open $genesyslog for reading");
  
  while (<GENESYSLOG>) {
    if (/markLanding:|(fixSlivCont: Top Cell)|(SLIVCONT layer detected)|(slivcont (straps|vias))|(No SLIVCONT)|:getCellHeightWidth:/) {
      chomp;
      &Log('QI', "GENESYS: $_");
    }
    if (/invalid command name(.+)Baa/) {
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


sub GenesysDiscardAll {

  my $genesysfh = shift;
  my $parentfh = select($genesysfh);

  print "DiscardAll\n";
  print "yes\n";

  select($parentfh);
}



# Update this to allow a list to be passed
sub GenesysSetStmOptions {

  my $genesysfh = shift;
  my $parentfh = select($genesysfh);

  print "\nstm instanceProperty 112\n";
  print "stm userUnits $GDSII_USERUNITS\n";
  print "stm outputCellInsts 1\n";
  print "stm outputTermInsts 1\n";
  print "stm mergePolygons 0\n";  # there is a bug with this option; holes
                                # not written out properly
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
      print "source $tclfile\n";
    } else {
      &Log('QE', "Could not load TCL module into Genesys:", $tclfile);
      my $at_least_one_module_bad = 1;
    }
  }
  if ($at_least_one_module_bad) {
    die &Log('QE', "At least one TCL file not sourced properly into Genesys");
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
  &PushFilesToTemporaryList($saveall_flag);
  unless (&CreateDirTree($outdir)) {
    die &Log('QE', "Could not create directory for lnf save:", $outdir);
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
    die &Log('QE', "Genesys output not written out. Expected:", $expected_outfile);
  }

  select($parentfh);
}


sub GenesysSaveStm {
  my $cell = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  
  print "\nSaveAs -cellname $cell -viewname stm -convertToCuts\n";
  select ($parentfh);
}


sub GenerateCarFile {

  my $incarfile = shift;
  my $outcarfile = shift;
  my $strap_obj_found = 0;
  open (INCAR, $incarfile) or die &Log('QE', "Could not open $incarfile for reading");
  open (OUTCAR, ">$outcarfile") or die &Log('QE', "Could not open $outcarfile for writing");
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



sub SagantecLayconv {
  my $inputfile = shift;
  my $inputformat = shift;
  my $outputfile = shift;
  my $outputformat = shift;
  my $pdbfile = shift;
  my $mapfile = shift;
  my $logfile = shift;

  if ($inputformat =~ /stm|gds/i) {$inputformat = '-ig'}
  if ($inputformat =~ /cif/i) {$inputformat = '-ic'}
  if ($outputformat =~ /stm|gds/i) {$outputformat = '-og'}
  if ($outputformat =~ /cif/i) {$outputformat = '-oc'}

  unless (-e $inputfile) {
    die &Log('QE', "Could not locate input file for layconv:",
	     $inputfile);
  }
  unless (-e $pdbfile) {
    die &Log('QE', "Could not locate pdb file for layconv:",
	     $pdbfile);
  }

  my $mapflag;
  if (-f $mapfile) {
    $mapflag = "-a $mapfile";
  } else {
    $mapflag = '';
  }
  
  system("$SAGROOT/bin/layconv $inputformat $inputfile $outputformat $outputfile -p $pdbfile $mapflag >& $logfile");
  
  unless (-e $outputfile) {
    die &Log('QE', "Could not find output file from layconv run",
	     "See $logfile");
  }
}


sub StripTextFromStm {

  my $inputstm = shift;
  my $outputstm = shift;
  my $current_record;
  my $record;
  my @record_list;
  my $text_found = 0;
  my $boundary_found = 0;
  my $keeptext = 0;
  my $throw_away_properties = 0;
  my $layer;
  my %preserve_text_layer_hash;
  my $resolution;


  # Keep diffusion text
  #$preserve_text_layer_hash{'1'} = 'NDIFF';
  #$preserve_text_layer_hash{'8'} = 'PDIFF';

  my $gds2InFile = new GDS2(-fileName => $inputstm, -resolution => $GDSII_RESOLUTION);
  my $gds2OutFile = new GDS2(-fileName => ">$outputstm", -resolution => $GDSII_RESOLUTION);

  while ($current_record = $gds2InFile -> readGds2Record) {
  # If the record is of type TEXT, then set a flag to indicate that we want
  # to save the remaining records. If the layer for the TEXT ends up being
  # ndiff or pdiff, then we will make a note to keep this text.
  # Continue until ENDEL and reset search. If we said to keep the text,
  # then print all the records including current one. Otherwise 
  # clear out the record list and skip current record.
  
    if ($gds2InFile -> isText) {
      $text_found = 1;
    }

    if ($text_found) {  
      push (@record_list, $current_record);
      $layer = $gds2InFile->returnLayer;
      if (exists $preserve_text_layer_hash{$layer}) {
        $keeptext = 1;
      }
      if ($gds2InFile -> isEndel) {
	if ($keeptext) {
	  foreach $record (@record_list) {
	    $gds2OutFile -> printRecord(-data=>$record);
	  }
	  $gds2OutFile -> printRecord(-data=>$current_record); # don't forget endel
	}
	@record_list = ();
	$text_found = 0;
	$keeptext = 0;
      }
    } else {
      $gds2OutFile -> printRecord(-data=>$current_record);
    }
  }
}


sub RunPdsXor {

  my $cell1 = shift;
  my $cell2 = shift;
  my $data1 = shift;
  my $data2 = shift;
  my @remaining_options = @_;
  my $xorstatsfile = "$PDSLOGS/${cell1}_xor.stats";
  my $xorsumfile = "$PDSLOGS/pdsxor.${cell1}.${data1}.${cell2}.${data2}.log.sum";
  my $xorabortfile = "$PDSLOGS/pdsxor.${cell1}.${data1}.${cell2}.${data2}.log.abort";
  my $xorlogfile = "$PDSLOGS/XORLOGS/pdsxor.${cell1}.${data1}.${cell2}.${data2}.log";
  my $xor1tree0file = "$PDSLOGS/XORLOGS/${cell1}.tree0_cell1";
  my $xor1tree1file = "$PDSLOGS/XORLOGS/${cell1}.tree1_cell1";
  my $xor1tree2file = "$PDSLOGS/XORLOGS/${cell1}.tree2_cell1";
  my $xor2tree0file = "$PDSLOGS/XORLOGS/${cell1}.tree0_cell2";
  my $xor2tree1file = "$PDSLOGS/XORLOGS/${cell1}.tree1_cell2";
  my $xor2tree2file = "$PDSLOGS/XORLOGS/${cell1}.tree2_cell2";
  my @xorfiles;
  my $run_is_dirty = 0;

  @xorfiles = ($xorstatsfile, $xorsumfile, $xorabortfile, $xorlogfile, $xor1tree0file);
  @xorfiles = (@xorfiles, $xor1tree1file, $xor1tree2file, $xor2tree0file, $xor2tree1file);
  @xorfiles = (@xorfiles, $xor2tree2file);

  &DeleteFiles(@xorfiles);

  system("$DA_UTILS/lv/pdsxor -cell1 $cell1 -cell2 $cell2 -data1 $data1 -data2 $data2 @remaining_options >& /dev/null");

  # Confirm sum file was created
  if (-e $xorabortfile ) {
    die &Log('QE', "PDSXOR run aborted.",
	     "See $xorabortfile");
  }
  open (XORSUM, $xorsumfile) or die &Log('QE', "Could not open $xorsumfile for reading");
  while (<XORSUM>) {
    if (/^\s*(DIRTY|clean|Cell Processed:|(.+)XOR MISMATCH|(.+)xor ERRORS)/) {
      chomp;
      if (/DIRTY/) {
	$run_is_dirty = 1;
      }
      &Log('QI', "PDSXOR: $_");
    }
  }
  close (XORSUM);
  return $run_is_dirty;
}



sub GenerateExplodeList {

  my $explode_record_ref = shift;
  my $explodelist = shift;

  open (EXPLODELIST, ">$explodelist") or die &Log('QE', "Could not open $explodelist for writing\n");
  foreach my $directive (sort keys %{ $explode_record_ref }) {
    foreach my $cell (sort keys %{ $$explode_record_ref{$directive} }) {
      print EXPLODELIST "${directive}=${cell}\n";
    }
  }
  close (EXPLODELIST);
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












