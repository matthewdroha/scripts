#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: rungenesys.pl,v 1.1 2010/01/08 19:57:06 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: rungenesys.pl,v 1.1 2010/01/08 19:57:06 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: rungenesys.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: This script accepts one or more master names
and runs the specified Genesys macro on the input hierarchy

=cut


BEGIN {
  use IO::Dir;
  my $homeproject = 'ivb';
  my %homedir;
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'EC_SITE'}) {
    my $CODE_DIR = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new($CODE_DIR);
    my @dirs = grep /\w+/, $dir->read();
    if (-d "$ENV{'HOME'}/ovrd") {
      push @INC, "$ENV{'HOME'}/ovrd";
    }
    foreach my $item (@dirs) {
      if (-d "${CODE_DIR}/${item}") {
	push @INC, "${CODE_DIR}/${item}";
      }
    } 
  } else {
    print "Environment var EC_SITE is not defined. Please make your environment eclogin compliant\n";
    exit;
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
use DAStd;
use Logfile;
use UE;
use Genesys;

my $CODE_DIR = GetCodeDir('ivb');
my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = GetDate();

# Get the site
our $SITE = GetSite();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME --cell <input cell> | --listfile <input list file>
                  --command <Genesys macro name>
                  --tcl <.tcl file>
                  [--env 'VAR=VALUE']
                  [--help] [--verbose] [--debug]

flag descriptions:

--cell            Input cell name to run macro on.

OR

--listfile        List of input cell names seperated by whitespace. These cells will
                  all be ran within the same Genesys session, seperated by a Discard All

--command         Genesys console command ran for each cell. More than one --command flag
                  is allowed.

--tcl             Source TCL file argument before command execution. Can have more than one --tcl
                  flag

--skipread        Skip reading LNF (assumes tcl command will load DB)

--env             Optional. Set env var at start of execution. Can have more than one --env
                  flag

--debug           Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file

--verbose         Will add status messages to STDOUT

--help            This usage message will appear


example: $EXE_NAME --cell yg0inn00nnc0 --commamd ::flow::checkcell 
 
Files that result from this run:

\$WORK/genesys/<cell>.${EXE_PREFIX}.log
\$WORK/genesys/<listfile>.${EXE_PREFIX}.log

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use --help to list input flags.\n";
}


# Get command line options. GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_cell, $opt_listfile, @opt_command, $opt_skipread, @opt_tcl);
our ($opt_help, $opt_debug, $opt_verbose, @opt_env);
my $options_ok = GetOptions("help",
			    "cell=s",
			    "listfile=s",
			    "command=s@",
			    "skipread",
			    "tcl=s@",
			    "env=s@",
			    "debug",
			    "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('--cell:--listfile', '--command');
my @argv_snapshot = @MAILARGV;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);



##### Main Program #####


# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}

our ($TRANSIENT_PSE_DB, $ATF_LOCKED);
Env::import('TRANSIENT_PSE_DB', 'ATF_LOCKED');

# Variables to start log file
my $cell;
if ($opt_cell) {
  $cell = $opt_cell;
}
elsif ($opt_listfile) {
  ($cell) = split(/\./, fileparse($opt_listfile));
} else {
  die "-F- $EXE_NAME: Unexpected error, neither -cell or -listfile are defined.";
}


our ($BASEFILE, $MAINLOG);
$BASEFILE = "${cell}.${EXE_PREFIX}";
$MAINLOG = Logfile->new("${WORK}/${BASEFILE}.log");
$MAINLOG->flowname($EXE_NAME);
$MAINLOG->verbose($opt_verbose);
$MAINLOG->debug($opt_debug);

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
$ATF_LOCKED = 'YES';

# Set the working directory to WORK
chdir ($WORK) or die "-E- $EXE_NAME: Could not change script working dir to $WORK\n";

my @cell_list;
if ($opt_cell) {
  push @cell_list, $cell;
}
elsif ($opt_listfile) {
  ReadListFile($MAINLOG, $opt_listfile, \@cell_list);
} else {
  die "-F- $EXE_NAME: Unexpected error, neither -cell or -listfile are defined.";
}


my $stage = 1;
$MAINLOG->info("***** Stage $stage: Start Genesys Session  *****");

# Disable the undo stack
$TRANSIENT_PSE_DB = 1;

# Define tcl modules
my @tcl_modules_list;
my $genesys_code_dir = "${CODE_DIR}/genesys";
my $dir_h = IO::Dir->new($genesys_code_dir);
my @dirs = grep /\.tcl$/, $dir_h->read();
foreach my $file (@dirs) {
  push @tcl_modules_list, "${genesys_code_dir}/${file}";
}
if (@opt_tcl) {
  foreach my $file (@opt_tcl) {
    if (-e $file) {
      my $target_file = abs_path($file);
      push @tcl_modules_list, $target_file;
    }
  }
}


# Open Genesys session
my $genesyslog = "${WORK}/${BASEFILE}.genesyslog";
my $genesysfh = GenesysOpenSession($MAINLOG, $genesyslog);
GenesysLoadModules($MAINLOG, $genesysfh, \@tcl_modules_list);
foreach my $cell (@cell_list) {
  my $readonly = 1;
  GenesysOpenCell($MAINLOG, $cell, 'lnf', '', $readonly, $genesysfh) unless $opt_skipread;
  foreach my $command_string (@opt_command) {
    my $command = $command_string;
    $command =~ s/\{CELL\}/$cell/g;
    GenesysCommandLine($MAINLOG, $genesysfh, $command);
  }
  GenesysCommandLine($MAINLOG, $genesysfh, 'DiscardAll -noask');
}
GenesysCloseSession($MAINLOG, $genesysfh);
CheckGenesysRun($MAINLOG, \@TMPFILES, $genesyslog);

DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for: $cell");



##### Start subroutine definitions #####

sub CheckGenesysRun {

  my $logfh = shift;
  my $tmpfiles_ref = shift;
  my $genesyslog = shift;

  my $parent_flow = $logfh->flowname('CheckGenesysPreProcess');

  open (GENESYSLOG, $genesyslog) or die $logfh->fatalq("Could not open $genesyslog for reading");
  
  while (<GENESYSLOG>) {
    if (/(invalid command name(.+)Baa)|(Could not open)/) {
      chomp;
      $logfh->infoq($_);
      die $logfh->fatalq("Problem occurred during LNF processing. See Genesys log file:", $genesyslog);
    }
  }
  close (GENESYSLOG);
  
  $logfh->flowname($parent_flow);
}
