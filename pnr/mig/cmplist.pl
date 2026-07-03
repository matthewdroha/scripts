#!/usr/intel/bin/perl

open (WANTFILE, $ARGV[0]) or die;
open (HAVEFILE, $ARGV[1]) or die;

while (<WANTFILE>) {
  ($fub) = split;
  $want_hash{$fub} = 1;
}
while (<HAVEFILE>) {
  ($fub) = split;
  $have_hash{$fub} = 1;
}

foreach $fub (sort keys %want_hash) {
  if ($have_hash{$fub}) {
    print "$fub found\n";
  }
}
