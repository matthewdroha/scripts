#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: migstat3CGI.pl,v 1.2 2006/02/17 09:16:05 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: migstat3CGI.pl,v 1.2 2006/02/17 09:16:05 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: migstat3CGI.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Generate html from migstat3.pl output

=cut


# Will redefine when we get a permanant UE friendly setup for 1266 and migration
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
use Getopt::Long;
use CGI;
use DAStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME  [-help] [-verbose] [-debug]

flag descriptions:

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


Files that result from this run:

EOD




# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
my $options_ok = &GetOptions("help",
			     "debug",
			     "verbose");

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 



##### Main Program #####

# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @TMPFILES = ();

my $www_data = '/www/htdocs/fdc_da/pd/migstat3';
my $ps3_status_csv = "${www_data}/migstat3.pshift3_status.csv";
unless (-e $ps3_status_csv) {
  die "Could not find status table in web area: $ps3_status_csv";
}

my @csv_data;
open (STATUS, $ps3_status_csv) or die "Could not open status table in web area: $ps3_status_csv";
while (<STATUS>) {
  chomp;
  push (@csv_data, $_);
} 
close (STATUS);

my $ps3_release_sum = "${www_data}/migstat3.pshift3_release.summary";
open (REL, $ps3_release_sum) or die "Could not open status table in web area: $ps3_release_sum";
my $report_gen;
my @release_list;
my @status_list;
while (<REL>) {
  chomp;
  if (/Report Generated:/) {
    $report_gen = $_;
  }
  if (/^(.+):\s+\((\d+)\)\s+of\s+\((\d+)\)\s*$/) {
    my $field = $1;
    my $num1  = $2;
    my $num2 = $3;
    $field =~ s/\s+$//;   # have no idea why chomp won't work
    my $key = join(':', $field, $num1, $num2);
    push (@release_list, $key);
  }
  if (/^(Total number of pshift3 fubs)(.+):\s+\((\d+)\)\s*$/) {
    my $field = "${1}${2}";
    chomp $field;
    my $key = join(':', $field, $3);
    push (@status_list, $key);
  }
}
close (REL);



my $q = new CGI;
print $q->header(-type => "text/html", -expires => "-1d" );

print "<html>\n";
print "<head>\n<title>Pshift3 Migration Status</title>\n";
print "</head>\n";
print "<body>\n";
print "<font face=verdana size=4>\n";
print "<b>Pshift3 Migration Status</b><br><br>\n";

print "<font face=verdana size=2>\n";

print "<b>$report_gen</b><br><br>\n";

print "Full CSV Report (Excel Loadable): <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_all.csv\">click here</a><br>\n";
print "Pshift3 Release Summary: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_release.summary\">click here</a><br>\n";
print "Pshift3 Fubs With ISS Ready LNF: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_issin_ok.table\">click here</a><br>\n";
print "Fubs Being Ignored For Pshift3: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/ctl/fubs.ignore\">click here</a><br>\n";
print "Migstat Log File (Contains ISSIN Errors) : <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.log\">click here</a><br>\n";
print "Pshift3 To-Do List: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_todo.table\">click here</a><br><br>\n";
print "Fubs With Tag But The Pre-Pshift3 Tag Is Missing: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_nopretag.table\">click here</a><br>\n";
print "Fubs With Tag But LNF Is Missing: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_missinglnf.table\">click here</a><br>\n";
print "Fubs Missing From Pshift3 Model (-m pshift3): <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_missingmodel.table\">click here</a><br>\n";
print "Fubs With Dirty ISSIN Run: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat3/migstat3.pshift3_badiss.table\">click here</a><br><br>\n";

print "<table border=0 cellpadding=2 cellspacing=0>\n";
foreach my $entry (@release_list) {
  print "<tr>";
  my @record = split(/:/, $entry);
  print "<td><font size=2>$record[0]</td>";
  print "<td><font size=2>:</td>";
  print "<td><font size=2><b>$record[1]</b></td>";
  print "<td><font size=2>of</td>";
  print "<td><font size=2><b>$record[2]</b></td>";
}
print "</table><br>";


print "<table border=0 cellpadding=2 cellspacing=0>\n";
foreach my $entry (@status_list) {
  print "<tr>";
  my @record = split(/:/, $entry);
  print "<td><font size=2>$record[0]</td>";
  print "<td><font size=2>:</td>";
  print "<td><font size=2><b>$record[1]</b></td>";
}
print "</table><br><br>";


print "<table border=1 cellpadding=3 cellspacing=0>\n";

my $row_number;
foreach my $row (@csv_data) {
  my @values = split(',', $row);
  print "<tr>";
  if ($row_number) {
    print "<tr>";
  } else {
    print "<tr bgcolor=yellow>";
  }
  my $col_number;
  foreach my $value (@values) {
    unless ($value) {
      $value = '-';
    }
    my $bg_cell = '';
    if ($value =~ /^(no|no_ps3_tag)$/) {
      $bg_cell = 'bgcolor=Red';
    }
    elsif ($value =~ /^(yes|ok|pnr_pshift3\S*)$/) {
      $bg_cell = 'bgcolor=Lime';
    }
    elsif ($value =~ /^(ar|pnr_pre_ps3\S*)$/) {
      $bg_cell = 'bgcolor=orange';
    }
    elsif ($value eq 'n/a') {
      $bg_cell = 'bgcolor=Silver';
    }
    print "<td $bg_cell><font size=2>$value</td>\n";
  }
  $row_number++;
}
print "</table></font></body></html>";


&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();


##### Start subroutine definitions #####







