#!/usr/intel/pkgs/perl/5.26.1/bin/perl

# check_scan_audit_log.pl
# (C) Copyright Intel Corporation, 2019, Matthew Roha, matthew.d.roha@intel.com

use v5.26.1;
use strict;
use warnings;
use English;
use Env;

my $infile = shift @ARGV;
my $reference_value = shift @ARGV;

# For die calls
die "** FAIL Reference value not a positive decimal\n" unless ($reference_value and $reference_value =~ /\d+\.?\d*/);
my $infileh = new IO::File;
$infileh->open($infile) or die "Could not open file for reading: $infile";
my $test_value;
while (<$infileh>) {
  if (/\-I\-\:\s+stuckat coverage\s+(\d+\.?\d*)\s+/) {
    $test_value = $1;
    last;
  }
}
$infileh->close;
die "** FAIL Test value not a positive decimal\n" unless ($test_value and $test_value =~ /\d+\.?\d*/);
my $percent_drift_allowed = 0.02;
my $percent_drift_measured = sprintf("%.2f", $test_value - $reference_value);
say qq(Infile = $infile);
say qq(Reference stuckat coverage = $reference_value);
say qq(Test stuckat coverage = $test_value);
say qq(Percentage drift allowed = (-) $percent_drift_allowed);
say qq(Percentage drift measured = $percent_drift_measured);

# Can't text compare, coverage can fluctuate slightly with same RTL
# This check is "ok" if scan coverage of test run is better than reference run
if ($test_value >= $reference_value - $percent_drift_allowed) {
  say qq(PASS);
  exit 0;
} else {
  die "** FAIL: Test value not within allowable drift range of reference value. \n";
}
