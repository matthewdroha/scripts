#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: laymodel.pl,v 1.1 2010/01/08 19:57:39 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: laymodel.pl,v 1.1 2010/01/08 19:57:39 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: laymodel.pl
Project: Sandy Bridge
Original Author: Matthew Roha

Functional Description: This script will search the lay_model model
file for all snb modules to locate lay_model tag information.

=cut


BEGIN {
  use IO::Dir
  my %homedir;
  my $homeproject = "snb";
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'UESITE'}) {
    my $targetdirname = "$homedir{$ENV{'UESITE'}}/${homeproject}";
    my $dir = IO::Dir->new($targetdirname);
    my @dirs = grep /\w+/, $dir->read();
    foreach my $item (@dirs) {
      if (-d "${targetdirname}/${item}") {
	push @INC, "${targetdirname}/${item}";
      }
    }
  } else {
    print "-E- Env variable \$UESITE not set. Please run script in UE.\n";
    exit 1;
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
usage:  $EXE_NAME -fub <input fub>
                  [-help] [-verbose] [-debug]

flag descriptions:

-fub              Input fub name

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -fub fmmgend

Files that result from this run:

\$WORK/<cell>.${EXE_PREFIX}.log

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_fub);
our ($opt_help, $opt_debug, $opt_verbose);
my $options_ok = &GetOptions("help",
			     "fub=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-fub');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

##### Main Program #####


# Capture initial environment variables
our ($HOME, $WORK_AREA_ROOT_DIR);
my @env_list = ('HOME', 'WORK_AREA_ROOT_DIR');

our ($DA_PROJECTS);
@env_list = (@env_list, 'DA_PROJECTS');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
my $cell_lc = lc($opt_fub);

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
$MAINLOG->info("System info: $machine_info");

# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @TMPFILES = ();


my $stage = 1;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Searching model files for fub *****");
my @modules = ('gsrcore', 'gsrllcbo', 'gsrsa4cg', 'gsrio4cg');
my $found_fub = 0;
foreach my $module (@modules) {
  $MAINLOG->info("Searching lay_model model file for module->(${module})");
  my $model_file = "${DA_PROJECTS}/${module}/${module}.lay_model.cfg";
  my $cfg_h = new IO::File;
  $cfg_h->open("< $model_file") or die $MAINLOG->fatalq("Could not open file for reading: $model_file");
  while (<$cfg_h>) {
    if (/^\s*${cell_lc}_${module}/) {
      unless ($found_fub) {
	 $MAINLOG->infop("Found fub in file->(${model_file})");
	 $found_fub = 1;
      }
      chomp;
      $MAINLOG->infop("$_");
    }
  }
  if ($found_fub) {
    exit;
  }
}
unless ($found_fub) {
  $MAINLOG->warnp("Could not find fub->(${cell_lc}) in any lay_model model file");
} 
