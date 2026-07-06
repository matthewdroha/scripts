#!/usr/intel/pkgs/perl/5.40.1/bin/perl

# kajson.pl
# (C) Copyright Intel Corporation, 2025, Matthew Roha, matthew.d.roha@intel.com
#

use v5.40.1;
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Copy;
use File::Find;
use Time::Local;
use IO::File;
use IO::Dir;
use Cwd;
use Env;
use Carp;
use JSON;
use Data::Dumper;
use Text::CSV_XS;
use Date::Calc qw(Week_of_Year);
use Intel::CDISLookup;

my @file_list;
find ( sub {
  return unless -f;         # Must be a file
  return unless /\.json$/;  # Must end with `.json` suffix
  push @file_list, $File::Find::name;
}, '/nfs/site/disks/mroha_wa_01/copilot_feedback_pilot');

my @redacted_files;

my $outlist = qq(redacted_file_list.txt);
my $outlisth = IO::File->new;
$outlisth->open(">$outlist") or die qq(-E- Could not open outfile for writing: $outlist\n);


my $find = q("system_user_name":\s+"\w+");
my $replace = q("system_user_name": "REDACTED"); 

foreach my $file (@file_list) {
  unless (-s $file) {next}

  my @record = split(/\//,$file);
  my $site = $record[6];
  my $system = $record[7];
  my $record_type = $record[8];
  my $tool = $record[9];

  if ($system eq "wa") {next}
  if ($record_type eq "system") {next}
  if ($tool =~ /^(pt|fc)$/) {next}


  say qq($file);
  my $redacted_file = ${file} . ".redacted";
  my $fileh = IO::File->new;
  $fileh->open($file) or die qq(-E- Could not open infile for reading: $file\n);
  my $redacted_fh = IO::File->new;
  $redacted_fh->open(">$redacted_file") or die qq(-E- Could not open outfile for writing: $redacted_file\n);
  
  while (<$fileh>) {
    if (/system_user_name/) {
      s/$find/$replace/;
    }
    print $redacted_fh $_;
  }
  $fileh->close();

  $redacted_fh->close();
  $outlisth->print("$redacted_file\n");
}

$outlisth->close();
