#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

my $celllog = shift;
my $prefix = shift;
unless ($prefix) {
  die "No prefix value given\n";
}
my $targetfh = IO::File->new;
$targetfh->open($celllog) or die "Could not open cell.log for reading: $celllog\n";
my $block;
($block) = split (/\./, $celllog);
while (<$targetfh>) {
  if (/^(\w+)\s+(\w+)\s+\S+(\s+\S+)?\s+lnf\s+\S+\s*$/) {
    my $cell = $2;
    if ($cell !~ /^(ai0|ai3|ai7|an4|a80|axx|ax0|ivb_|glbdrv$|basic_glbdrv$)/) {
      print "$cell ${prefix}${cell}\n";
    }
  }
}
