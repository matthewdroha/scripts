#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: dcc_histo.pl,v 1.1 2007/09/13 18:00:47 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: dcc_histo.pl,v 1.1 2007/09/13 18:00:47 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: dcc_histo.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: This script reads the abs ir drop file and cereal log file as input
and generates an xgraph distribution based on script input

Script inputs:
  - Bucket size (mV)
  - Max abs ir drop (mV)

=cut


BEGIN {
  if (defined $ENV{'DA_OVR'}) {
    push @INC, $ENV{'DA_OVR'};
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
use FileHandle;
use Env;
use Cwd;
use Cwd 'abs_path';
use DAStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Get the site
our $SITE = &GetSite();

# Defaults
my $bucketsize = 2;
my $maxirdrop = 250;


# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
                  [-vcclimit <vcc ir drop limit in mV>]
                  [-vsslimit <vcc ir drop limit in mV>]
                  [-xgraph]
                  [-bucketsize <bucket size in mV>]
                  [-maxirdrop  <max ir drop bucket>]
                  [-ward <override RV run work area>]
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input fub name.

-vcclimit         Vcc absolute irdrop limit at VT

-vsslimit         Vss absolute irdrop limit at VT

-xgraph           Script will start xgraph session for each distribution

-bucketsize       Optional. Bucket size in mV for distribution. Default is $bucketsize mV

-maxirdrop        Optional. Maximum absolute bucket. All irdrop values higher than this value are
                  placed in this bucket. Default is $maxirdrop mV

-ward             Optional. Override work area for RV files. By default flow will look
                  in RV archive

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend -bucketsize 3 -maxirdrop 250

Files that result from this run:

\$WORK/<cell>.${EXE_PREFIX}.xgraph

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_cell, $opt_bucketsize, $opt_maxirdrop, $opt_ward, $opt_vcclimit, $opt_vsslimit, $opt_xgraph);
our ($opt_help, $opt_debug, $opt_verbose);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "vcclimit=i",
			     "vsslimit=i",
			     "xgraph",
                             "maxirdrop=i",
			     "bucketsize=i",
			     "ward=s",
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


if (defined $opt_maxirdrop) {
  $maxirdrop = $opt_maxirdrop;
}

if (defined $opt_bucketsize) {
  $bucketsize = $opt_bucketsize;
}


##### Main Program #####


# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');


foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
my $cell_lc = lc($opt_cell);

our ($BASEFILE, $MAINLOG);
$BASEFILE = "${cell_lc}.${EXE_PREFIX}";
$MAINLOG = LogFile->new("${BASEFILE}.log");
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

# A0
# my $rv_archive = "/nfs/fm/proj/pnr/fm_rv02/rv/a0/fubs";

# B0
my $rv_archive = "/p/pnr/proc/common/utils/tool_utils/rv/pnrb/a0_archive/fubs";

my $ward;
if ($opt_ward) {
  $ward = $opt_ward;
} else {
  $ward = "${rv_archive}/${cell_lc}";
}

$ward = abs_path($ward);
unless (-d $ward) {
  die $MAINLOG->fatalq("Could not find RV working directory: $ward");
}

my @rails = ('vcc', 'vss');
my %limit_table;


my $stage= 1;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Reading Cereal Log File  *****");
my $rvlogs = "${ward}/rv/log";
unless (-d $rvlogs) {
  die $MAINLOG->fatalq("Could not find rvlogs directory: $rvlogs");
}
my $cereal_log = "${rvlogs}/${cell_lc}.cereal.log";
my $cereal_fh = new FileHandle "$cereal_log";
my $layout_tag = 'NO TAG';
if (defined $cereal_fh) {
  my $found_tag = 0;
  my $found_irtable = 0;
  my $current_rail;
  while (<$cereal_fh>) {
    if (/LAYOUT AND LIBRARY TAGS BELOW :/) {
      $found_tag = 1;
    }
    if (/Fub\s+\w+\s+Rail (vcc|vss)/) {
      $current_rail = $1;
      $found_irtable = 1;
    }
    if (($found_tag) and (/_lay/)) {
      my @record = split;
      $layout_tag = pop(@record);
      $found_tag = 0;
    }
    if (($found_irtable) and (/^\s+VT\s+\d+/)) {
      chomp;
      my @record = split;
      $limit_table{$current_rail} = int(pop(@record));
      $found_irtable = 0;
    } 
  }
} else {
  die $MAINLOG->fatalq("Could not open cereal log for reading: $cereal_log");
}
$cereal_fh->close;

if (defined $opt_vcclimit) {
  $MAINLOG->warnp("Command line override for vcc ir drop limit. Cereal->($limit_table{'vcc'})  -vcclimit->($opt_vcclimit)");
  $limit_table{'vcc'} = $opt_vcclimit;
}
if (defined $opt_vsslimit) {
  $MAINLOG->warnp("Command line override for vss ir drop limit. Cereal->($limit_table{'vss'})  -vcclimit->($opt_vsslimit)");
  $limit_table{'vss'} = $opt_vsslimit;
}

if ($bucketsize < 1) {
  die $MAINLOG->fatalq("-bucketsize needs to be an integer greater than 1 mV");
} else {
  $MAINLOG->info("Bucket Size (mV): $bucketsize");
}

if ($maxirdrop < 1) {
  die $MAINLOG->fatalq("-maxirdrop needs to be an integer greater than 1 mV");
}

foreach my $rail (@rails) {
  if ($maxirdrop <= $limit_table{$rail}) {
    die $MAINLOG->fatalq("The max bucket catagory needs to be greater than -${rail}limit");
  } else {
    $MAINLOG->info("IR Drop Limit $rail (mV): $limit_table{$rail}");
  }
}
$MAINLOG->info("Max bucket value (mV): $maxirdrop");




my %ir_abs_data;
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Reading IR Drop Files  *****");
my $viewfiles = "${ward}/rv/dcc/viewfiles";
unless (-d $viewfiles) {
  die $MAINLOG->fatalq("Could not find viewfiles directory: $viewfiles");
}
foreach my $rail ('vcc', 'vss') {
  my $ir_abs_file = "${viewfiles}/${cell_lc}.rv_${rail}_ir_abs_dcc_VT.gz";
  unless (-f $ir_abs_file) {
    die $MAINLOG->fatalq("Could not open ir abs file for reading: $ir_abs_file");
  }
  $MAINLOG->info("Reading: $ir_abs_file");
  my $irhandle = new FileHandle "/usr/intel/bin/gunzip -c $ir_abs_file |";
  if (defined $irhandle) {
    while (<$irhandle>) {
      if (/\d+\s+(VCC|VSS)/) {
	my @record = split;
	push(@{ $ir_abs_data{$rail} }, $record[4]);
      }
    }
  } else {
    $MAINLOG->fatalq("Could not open irdrop file for reading: $ir_abs_file");
  }
  my $datacount = scalar @{ $ir_abs_data{$rail} };
  @{ $ir_abs_data{$rail} } = sort numerically @{ $ir_abs_data{$rail} };
  $MAINLOG->info("IR drop values read from file: $datacount");
  $irhandle->close;
}

$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Bucketizing Data  *****");
if ($opt_debug) {
  foreach my $rail (@rails) {
    my $csvfile = "sorted_${rail}.csv";
    my $fh = new FileHandle "> $csvfile";
    if (defined $fh) {
      foreach my $value (@{ $ir_abs_data{$rail} }) {
	printf $fh "%.3f\n", $value;
      }
    } else {
      $MAINLOG->fatalq("Could not open csv file for writing: $csvfile");
    }
    $fh->close;
  }
}

my %buckets;
foreach my $rail (@rails) {
  my $irdrop_limit = $limit_table{$rail};
  my $bucket = $irdrop_limit;
  my $next_bucket = $bucket + $bucketsize;
  if ($next_bucket > $maxirdrop) {
    $next_bucket = $maxirdrop;
  }
  $buckets{$rail}{$bucket} += 0;
  while (@{ $ir_abs_data{$rail} }) {
    my $current_value = shift (@{ $ir_abs_data{$rail} });
    if ($current_value < $irdrop_limit) {
      next;
    }
    if (($current_value >= $bucket) and ($current_value < $next_bucket)) {
      $buckets{$rail}{$bucket}++;
    } else {
      unshift(@{ $ir_abs_data{$rail} }, $current_value);
      $bucket = $next_bucket;
      $next_bucket = $bucket + $bucketsize;
      $buckets{$rail}{$bucket} += 0;
      if ($next_bucket > $maxirdrop) {
	$next_bucket = $maxirdrop;
      }
      if ($bucket == $maxirdrop) {
	$buckets{$rail}{$bucket} = scalar @{ $ir_abs_data{$rail} };
	last;
      }
    }
  }
}

my %totals;
foreach my $rail (@rails) {
  $totals{$rail} += 0;
  $MAINLOG->info("Rail: $rail");
  foreach my $bin (sort numerically keys %{ $buckets{$rail} }) {
    $MAINLOG->info("Bin->($bin)   Count->($buckets{$rail}{$bin})");
    $totals{$rail} += $buckets{$rail}{$bin};
  }
}



my $x_axis_high = $maxirdrop;
my $x_axis_low = $maxirdrop;
foreach my $rail (@rails) {
  if ($x_axis_low > $limit_table{$rail}) {
    $x_axis_low = $limit_table{$rail};
  }
}
$x_axis_low -= $bucketsize;
my %window; 
$window{'vcc'} = '=1050x440+86+3';
$window{'vss'} = '=1050x440+86+472';


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Writing xgraph files *****");
foreach my $rail (@rails) {
  my $xgraph_file = "${BASEFILE}.${rail}.xgraph";
  my $csvfile = "${BASEFILE}.${rail}.csv";
  my $xg_fh = new FileHandle ">$xgraph_file";
  my $csv_fh = new FileHandle ">$csvfile";
  if (defined $xg_fh) {
    $MAINLOG->info("Writing: $xgraph_file");
    select ($xg_fh);
    my $rail_uc = uc($rail);
    my $cell_uc = uc($cell_lc);
    print "TitleText: $cell_uc $rail_uc Abs IR Drop Failure Distribution @ VT (Limit = $limit_table{$rail} mV)\n";
    print "BarGraph: 1\n";
    print "BarWidth: 1\n";
    print "NoLines: 1\n";
    print "Background: Black\n";
    print "Foreground: White\n";
    print "0.Color: Blue\n";
    print "XUnitText: Abs IR Drop (mV)\n";
    print "YUnitText: Count (Total = $totals{$rail})\n";
    print "XLowLimit: $x_axis_low\n";
    print "XHighLimit: $maxirdrop\n";
    print "\"$layout_tag\"\n";
    unless (defined $csv_fh) {
       die $MAINLOG->fatalq("Could not open csv file for writing: $csvfile");
     }
    foreach my $bin (sort numerically keys %{ $buckets{$rail} }) {
      if ($bin == $maxirdrop) {
	print "\n";
	print "\">=${maxirdrop} mV\"\n";
	print "1.Color: Red\n";
	print "$bin $buckets{$rail}{$bin}\n";
      }
      print "$bin $buckets{$rail}{$bin}\n";
      print $csv_fh "${bin},$buckets{$rail}{$bin}\n";
    }
    select (STDOUT);
    $xg_fh->close;
    $csv_fh->close;
    chmod 0775, $xgraph_file;
    chmod 0775, $csvfile;
    if ($opt_xgraph) {
      my $xgraph_cmd = "/usr/intel/bin/xgraph $window{$rail} $xgraph_file &";
      unless (&Tcsh($MAINLOG, $xgraph_cmd)) {
	die $MAINLOG->fatalq("Could not start xgraph: $xgraph_cmd");
      }
    }
  } else {
    die $MAINLOG->fatalq("Could not open xgraph file for writing: $xgraph_file");
  }
}


&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");




##### Start subroutine definitions #####

sub numerically {$a <=> $b};
