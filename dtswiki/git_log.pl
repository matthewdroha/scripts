#!/usr/intel/bin/perl

use IO::File;

my $type;
print qq(Type\tDate\tSummary\n);
while (<>) {
  my ($date,$time,$mt,$summary) = split(/\s+/,$_,4);
  $type = 'Unknown';
  $dt = qq($date $time);
  if (/\s*Style:/) {$type = q(Style);}
  if (/\s*New:/) {$type = q(New);}
  if (/\s*Improved:/) {$type = q(Improved);}
  if (/\s*Fixed:/) {$type = q(Fixed);}
  if (/\s*Revert/) {$type = q(Revert);}
  #my $summary = $_;
  $summary =~ s/\s*(Style|New|Improved|Fixed):\s*//;
  print qq(${type}\t${dt}\t$summary);
}

