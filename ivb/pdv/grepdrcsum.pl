#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

my $cell;
my $min;
my $fraction;
while (<>) {
  
  if (/Cell Processed:\s+(\S+)/) {
    $cell = $1;
  }
  elsif (/Wallclock Time:/) {
    my @record = split;
    $min = $record[6];
    $fraction = $record[9]/60;
    $min = $min + $fraction;
  }
  elsif (/^\S+\s+drcd\s+(\d+)/) {
    my $drcd = $1;
    printf "%s,%.3f,%s\n", $cell, $min, $drcd;
  }
}
