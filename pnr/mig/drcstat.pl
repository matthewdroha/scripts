#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: drcstat.pl,v 1.5 2005/08/15 22:27:53 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: drcstat.pl,v 1.5 2005/08/15 22:27:53 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: drcstat.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Queries migration release area and Merom SQL DB and generates several reports on migration
execution status

=cut


# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
  if (defined $ENV{'MIG_OVR'}) {
    push @INC, $ENV{'MIG_OVR'};
  } else {
    push @INC, "/nfs/iil/disks/home10/mroha/pnr/mig", "/usr/users/home2/mroha/pnr/mig";
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
use DAStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE;

$SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME [-help] [-verbose]
                  [-debug]

flag descriptions:

-laydev           Optional. Uses provided layout devices as input, otherwise searches
                  archive for log files, and then uses Merom SQL database as last resort.

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME

Files that result from this run:

EOD

# Parse command line parameters, check if input files exist, etc...
#if (@ARGV == 0) {
#  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
#}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
our ($opt_laydev);
my $options_ok = &GetOptions("help",
			     "laydev=i",
			     "debug",
			     "verbose");

# Check options
if (!$options_ok) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ();
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

# Stop 'strict' from complaining. May need later.
my $debug = $opt_debug;
my $verbose = $opt_verbose;



our ($BASEFILE);
$BASEFILE = "${EXE_PREFIX}";

my @filter_report_list = @ARGV;

my %migstat_dir;
$migstat_dir{'iil'} = '/nfs/iil/disks/home10/mroha/migstat';
$migstat_dir{'fm'} = '/usr/users/home2/mroha/migstat';

my $migstat_scale_report = "$migstat_dir{$SITE}/migstat.scale_report";
my %migstat_table;
open (MIGREPORT, $migstat_scale_report) or die "${EXE_NAME}: Could not open migstat file for reading: $migstat_scale_report\n";
while (<MIGREPORT>) {
  if (/^\s*\d+_\d+_\d+_\S+\s+(\S+)\s+\S+\s+(\d+)/) {
    $migstat_table{$1} = $2;
  }
}
close (MIGREPORT);


my $cell;
my %report_table;
foreach my $report (@filter_report_list) {
  open (FILTERREPORT, $report) or die "${EXE_NAME}: Could not open filter report: $report\n";
  while (<FILTERREPORT>) {
    if (/\#\s+Cell:\s+(\S+)/) {
      $cell = $1;
    }
    if (/Sum of filtered errors:.+flow\->\((\S+)\)\s+total\->\((\d+)\)/) {
      push (@{ $report_table{$cell}{'FLOW'} }, $1);
      push (@{ $report_table{$cell}{'TOTAL'} }, $2);
    }
  }
  close (FILTERREPORT);
}
print "\n";

# Run query for device count in case other sources do not exist
my %migutils_dir;
$migutils_dir{'iil'} = '/nfs/iil/disks/home10/mroha/pnr/mig';
$migutils_dir{'fm'} = '/usr/users/home2/mroha/pnr/mig';
$migutils_dir{'sc'} = '/nfs/user/home/mroha/pnr/mig';

my $laydev_query = "$migutils_dir{$SITE}/dev_count_lay.mco";
my %laydev_lookup;
open (DEVQUERY, "$laydev_query |") or die "${EXE_NAME}: Could not open layd4ev query: $laydev_query\n";
while (<DEVQUERY>) {
  if (/^\s*(\w+)\s+(\d+)\s*$/) {
    $laydev_lookup{$1} = $2;
  }
}
close (DEVQUERY);

foreach my $cell (sort keys %report_table) {
  my $laydev = 'NO VALUE';
  if (defined $opt_laydev) {
    if ($opt_laydev > 0) {
      $laydev = $opt_laydev;
    } else {
      die "${EXE_NAME}:-laydev has to be passed an integer greater than 0\n";
    }
  }
  elsif (exists $migstat_table{$cell}) {
    $laydev = $migstat_table{$cell};
  }
  elsif ((exists ($laydev_lookup{$cell})) and ($laydev_lookup{$cell} > 0)) {
    $laydev = $laydev_lookup{$cell};
  }

  if (scalar @{ $report_table{$cell}{'FLOW'} }) {
    my $flow_string = join(' + ',  @{ $report_table{$cell}{'FLOW'} });
    my $sum_string = join(' + ',  @{ $report_table{$cell}{'TOTAL'} });
    my $total = 0;
    foreach my $value (@{ $report_table{$cell}{'TOTAL'} }) {
      $total += $value;
    }
    my $total_div_4 = int(${total}/4);
    my $drc_percentage;
    if ($laydev =~ /\d+/) {
      $drc_percentage = (${total_div_4}/${laydev}) * 100;
    } else {
      $drc_percentage = "NO LAYDEV";
    }
    print "##### Cell: $cell #####\n";
    print "Laydev: $laydev\n";
    print " Flows: (${flow_string})\n";
    print "   Sum: (${sum_string}) = $total\n";
    print "  Div4: $total_div_4\n";
    if ($drc_percentage eq "NO LAYDEV") {
      print " DRC %: $drc_percentage\n";
    } else {
      printf " %-s: %.2f\n", 'DRC %', $drc_percentage;
    }
    print "\n";
  }
}




##### Start subroutine definitions #####


# Fub is assumed to be the proper case (in this case, lower case)





