#!/usr/intel/pkgs/perl/5.26.1/bin/perl

use v5.26.1;
use strict;
use warnings;
use English;
use IO::File;
use IO::Dir;

my $cellfile = shift(@ARGV);
my $stddir = shift(@ARGV);

my $cellfile_h = IO::File->new;
$cellfile_h->open($cellfile) or die qq(Could not open cellfile for reading: $cellfile\n);

my %cellhash;
while (<$cellfile_h>) {
  if (/^\s*\-E\-\s+(\S+)\s+/) {
    my $cell = $1;
    $cellhash{$cell} = 1;
  }
}

if (-d $stddir) {
  foreach my $cell (sort keys %cellhash) {
    my $found_match = 0;
    my $cmd = qq(grep --count $cell ${stddir}/group/*);
    my $grepcount = `$cmd`;
    my @record = split(/\s+/, $grepcount);
    foreach my $line (@record) {
      if ($line =~ /:(\d+)\s*$/) {
        if ($1 > 0) {
          $found_match = 1;
          last;
        }
      }
    }
    if ($found_match) {
      say qq($cell FOUND $stddir);
    } else {
      say qq($cell NOTFOUND);
    }
  }
} else {
  die qq(Could not open stddir: $stddir\n);
}

