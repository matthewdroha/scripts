#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: getxy.pl,v 1.2 2005/09/08 19:17:02 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: getxy.pl,v 1.2 2005/09/08 19:17:02 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: getxy.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Loads LNF in Genesys and extracts cell size

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

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

#our $SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
                  [-dbb <dbb name>] [-uemodel <model name>]
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input cell name

-dbb              Override for DBB name. In regular mode, the DBB is the -cell value.
                  With -nofub, the default is 'none'

-uemodel          MODEL to use when running with -nofub switch. Default is whatever the UE default
                  is.

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend
         $EXE_NAME -cell ifdatabankld -dbb ifdatad

Files that result from this run:

<cell>.xy file

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
our ($opt_cell, $opt_dbb, $opt_uemodel);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "dbb=s",
			     "uemodel=s",
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
our ($HOME, $WORK_AREA_ROOT_DIR, $DBB, $MODEL, $DMSPATH, $GENESYS_DIR);
our ($CDSLIB, $CAD_ROOT, $GENESYS, $GENESYSSCRIPTS, $GENESYS_VER, $PROJECT);
my @env_list = ('WORK_AREA_ROOT_DIR', 'HOME', 'DBB', 'MODEL', 'DMSPATH', 'GENESYS_DIR');
@env_list = (@env_list, 'CDSLIB', 'CAD_ROOT', 'GENESYS', 'GENESYSSCRIPTS', 'GENESYS_VER');
@env_list = (@env_list, 'PROJECT');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
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


my $orig_dmspath = $DMSPATH;
my $orig_cdslib = $CDSLIB;
my $orig_model = $MODEL;
my $orig_dbb = $DBB;
my $dbb;
my $uemodel;
if ($opt_dbb) {
  $dbb = $opt_dbb;
} else {
  $dbb = $cell_lc;
}
if ($opt_uemodel) {
  $uemodel = $opt_uemodel;
} else {
  $uemodel = $MODEL;
}

# Hack DMSPATH for specific fub
$MAINLOG->infoq("Compiling dmspath...");
$MAINLOG->infoq("DBB:($dbb)");
$MAINLOG->infoq("MODEL:($uemodel)");
my $newdmspath = "${WARD}/${BASEFILE}.dms.pth";
push(@TMPFILES, $newdmspath);
my $newdmsmodes = "${WORK_AREA_ROOT_DIR}/${BASEFILE}.dms.pth.modes";
push(@TMPFILES, $newdmsmodes);
my $newcdslib = "${WARD}/${BASEFILE}.cds.lib";
push(@TMPFILES, $newcdslib);
  
&RecompileDmspath($MAINLOG, $dbb, $uemodel, $newdmspath, $newcdslib);
$DMSPATH = $newdmspath;
$CDSLIB = $newcdslib;

$MAINLOG->infoq("Calling Genesys...");

my $fubxy = "${WORK_AREA_ROOT_DIR}/${BASEFILE}.xy";
&DeleteFiles($fubxy);

# Disable the undo stack
$ENV{'TRANSIENT_PSE_DB'} = 1;

# Open Genesys session
my $genesyslog = "${WARD}/${BASEFILE}.genesyslog";
&DeleteFiles($genesyslog);
my $genesysfh = &GenesysOpenSession($genesyslog);

# Minimize the amount of data in the run area
&GenesysCommandLine($genesysfh, 'set cvm [::boo::CellViewMgr_getCellViewMgr]');
&GenesysCommandLine($genesysfh, '$cvm setSaveBackups 0');

# Preprocess LNF files
my $readonly = 1;
&GenesysCommandLine($genesysfh, 'lnf SetDepth 0');
&GenesysOpenCell($cell_lc, 'lnf', '', $readonly, $genesysfh);
&GenesysLoadModules(\@mig_tcl_modules_list, $genesysfh);
&GenesysCommandLine($genesysfh, '::mig::getCellHeightWidth');

# Close session and check output (open3... someday)
&GenesysCloseSession($genesysfh);

my $x = '';
my $y = '';
open (GENESYSLOG, $genesyslog) or die $MAINLOG->fatalq("Could not open genesys log for reading: $genesyslog");
while (<GENESYSLOG>) {
  if (/getCellHeightWidth: Cell X Width:\s+(\S+)/) {
    $x = $1;
  }
  if (/getCellHeightWidth: Cell Y Height:\s+(\S+)/) {
    $y = $1;
  }
}
close (GENESYSLOG);

if ($x and $y) {
  open (FUBXY, ">$fubxy") or die $MAINLOG->fatalq("Could not open fub xy file for reading");
  print FUBXY "PROJ=${PROJECT}\n";
  print FUBXY "DBB=$dbb\n";
  print FUBXY "MODEL=$uemodel\n";
  print FUBXY "X=$x\n";
  print FUBXY "Y=$y\n";
  close (FUBXY);
}

unless (-e $fubxy) {
  die $MAINLOG->fatalq("fub xy file not generated: $fubxy");
}

$MAINLOG->newline;
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






