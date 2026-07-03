#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: scxyCGI.pl,v 1.1 2005/08/15 22:22:41 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: scxyCGI.pl,v 1.1 2005/08/15 22:22:41 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: scxyCGI.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Generate html from migstat.pl scaling XY output

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

my $www_data = '/www/htdocs/fdc_da/pd/migstat';
my $ps2_scxy_csv = "${www_data}/migstat.pshift2_scxy.csv";
unless (-e $ps2_scxy_csv) {
  die "Could not find status table in web area: $ps2_scxy_csv";
}

my @csv_data;
open (STATUS, $ps2_scxy_csv) or die "Could not open status table in web area: $ps2_scxy_csv";
while (<STATUS>) {
  chomp;
  push (@csv_data, $_);
} 
close (STATUS);

my $q = new CGI;
print $q->header(-type => "text/html", -expires => "-1d" );

print "<html>\n";
print "<head>\n<title>Pshift2 vs Pshift1 Fub Scale Factors</title>\n";
print "</head>\n";
print "<body>\n";
print "<font face=verdana size=4>\n";
print "<b>Pshift2 vs Pshift1 Fub Scale Factors</b><br><br>\n";

print "<font face=verdana size=2>\n";

print "Fub Sizing CSV Report (Excel Loadable): <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat/migstat.pshift2_scale.csv\">click here</a><br>\n";
print "Fubs Pshift Scaling Directives: <a href=\"http://www-fmec.fm.intel.com/fdc_da/pd/migstat/ctl/fubs.scale_directives\">click here</a><br><br>\n";

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
    my $align = '';
    if ($value eq 'no') {
      $bg_cell = 'bgcolor=Red';
    }
    elsif ($value =~ /^yes$/) {
      $bg_cell = 'bgcolor=Lime';
    }
    elsif ($value eq 'hold') {
      $bg_cell = 'bgcolor=orange';
    }
    elsif ($value eq 'n/a') {
      $bg_cell = 'bgcolor=Silver';
    }
    if ($value =~ /^\-?\d*\.?\d+$/) {
      $align = 'align=right';
    }
    print "<td $align $bg_cell><font size=2>$value</td>\n";
  }
  $row_number++;
}
print "</table></font></body></html>";


&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();


##### Start subroutine definitions #####







