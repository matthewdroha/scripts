#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: paradecsv.pl,v 1.1 2010/01/08 19:57:13 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: paradecsv.pl,v 1.1 2010/01/08 19:57:13 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: schdev.pl
Project: Sandy Bridge
Original Author: Matthew Roha

Functional Description: This script will generate (or read) an SNSCH file and 
generate a report file on the following information for each master
  - Hierarchy level
  - Number of custom devices
  - Number of devices in std cells
  - Number of instances

=cut




BEGIN {
  use IO::Dir
  my %homedir;
  my $homeproject = "snb";
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'EC_SITE'}) {
    my $targetdirname = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new($targetdirname);
    my @dirs = grep /\w+/, $dir->read();
    foreach my $item (@dirs) {
      if (-d "${targetdirname}/${item}") {
	push @INC, "${targetdirname}/${item}";
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
usage:  $EXE_NAME -writenetscsv <nets list> -cell <master cell name>
                  [-env 'VAR=VALUE']
                  [-help] [-verbose] [-debug]

flag descriptions:

-writenetcsv      Required. Argument is file containing list of nets seperated by
                  whitespace.  Output file name is <cell>.nets.csv

-cell             Required with -writecsv. Master cell name.

-env              Optional. Set env var at start of execution. Can have more than
                  one -env flag.

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -help
         $EXE_NAME -writecsv \$WORK/nets.list -cell rarepd

Files that result from this run:

\$WORK/<cell>.${EXE_PREFIX}.log
\$WORK/<cell>.${EXE_PREFIX}.writecsv.csv

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_cell, $opt_writenetcsv, @opt_env);
our ($opt_help, $opt_debug, $opt_verbose);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "writenetcsv=s",
			     "env=s@",
			     "ignorecmp",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell', '-writenetcsv');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####


# Capture initial environment variables
our ($HOME, $WORK_AREA_ROOT_DIR);
my @env_list = ('HOME', 'WORK_AREA_ROOT_DIR');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
my $cell_lc = lc($opt_cell);

our ($BASEFILE, $MAINLOG, $WORK);
$WORK = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${EXE_PREFIX}";
$MAINLOG = LogFile->new("${WORK}/${BASEFILE}.log");
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

my @net_list;
if ($opt_writenetcsv) {
  my $stage = 1;
  $MAINLOG->newline;
  $MAINLOG->info("***** Stage $stage: Parse Input Nets File *****");
  my $netfh = new IO::File;
  $netfh->open($opt_writenetcsv) or die $MAINLOG->fatalq("Cound not open input nets file for reading: $opt_writenetcsv");
  my @record;
  my $prefix;
  my $vector;
  my $unrolled_vector = '';
  while (<$netfh>) {
    @record = split;
    foreach my $net (@record) {
      if ($net =~ /\[\d+:\d+\]/) {
	($prefix) = split(/\[/, $net);
	$vector = $net;
	$vector =~ s/$prefix//;
	$vector =~ s/\[|\]/ /g;
	$vector =~ s/^\s+//;
	$vector =~ s/\s+$//;
	&UnrollVectorizedNets($MAINLOG, \@net_list, $prefix, $vector, $unrolled_vector);
      } else {
	push @net_list, lc($net);
      }
    }
  }
  $netfh->close;


  $stage++;
  $MAINLOG->newline;
  $MAINLOG->info("***** Stage $stage: Write Nets .csv File *****");
  my $outfile = "${WORK}/${BASEFILE}.writenetcsv.csv";
  my $csvfh = new IO::File;
  $csvfh->open($outfile, ">") or die $MAINLOG->fatalq("Could not open output file for writing: $outfile");
  select $csvfh;
  print "IDs,Objs,Name\n\n\n";
  foreach my $net (@net_list) {
    print "${cell_lc}\;${net},node,${net}\n";
  }
  $csvfh->close;
}


&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");


##### Start subroutine definitions #####

sub UnrollVectorizedNets {

  my $loghandle = shift;
  my $net_list_ref = shift;
  my $prefix = shift;
  my $vector = shift;
  my $unrolled_vector = shift;

  my $target_vector;
  my $remaining_vector;
  my $low;
  my $high;

  ($target_vector, $remaining_vector) = split(/\s+/, $vector, 2);
  unless (defined $remaining_vector) {
    $remaining_vector = '';
  }
  $loghandle->infod("Target Vector->($target_vector)  Remaining Vector->($remaining_vector)  Unrolled Vector->($unrolled_vector)") if $opt_debug;
  if ($target_vector =~ /(\d+):(\d+)/) {
    if ($1 <= $2) {
      $low = $1;
      $high = $2;
    } else {
      $low = $2;
      $high = $1;
    }
  }
  elsif ($target_vector =~ /(\d+)/) {
    $low = $high = $1;
  } else {
    $loghandle->fatalp("Vector information problem with prefix->($prefix)");
    exit 1;
  }
  for (my $i=$low; $i <= $high; $i++) {
    if ($remaining_vector ne '') {
      my $adjusted_unrolled_vector = $unrolled_vector;
      if ($adjusted_unrolled_vector ne '') {
	$adjusted_unrolled_vector = join(" ", $adjusted_unrolled_vector, $i);
      } else {
	$adjusted_unrolled_vector = $i;
      }
      &UnrollVectorizedNets($loghandle, $net_list_ref, $prefix, $remaining_vector, $adjusted_unrolled_vector); 
    } else {
      my $built_vector = '';
      my @record;
      @record = split(/\s+/, $unrolled_vector);
      foreach my $bit (@record, $i) {
	$built_vector.= "[${bit}]";
      }
      $loghandle->infod("Built Vector->(${built_vector})");
      push @{$net_list_ref}, "${prefix}${built_vector}";
    }
  }  
}
