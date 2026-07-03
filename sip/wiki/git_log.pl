#!/usr/intel/pkgs/perl/5.26.1/bin/perl

use IO::File;

my $type;
print qq(Toolset\tType\tDate\tSummary\n);
while (<>) {
  my ($date,$time,$mt,$summary) = split(/\s+/,$_,4);
  $type = 'Unknown';
  $dt = qq($date $time);
  if (/\s*New:/) {$type = q(New);}
  if (/\s*Improved:/) {$type = q(Improved);}
  if (/\s*Fixed:/) {$type = q(Fixed);}
  if (/\s*Test:/) {$type = q(Fixed);}
  if (/\s*Refactor:/) {$type = q(Fixed);}
  if (/\s*Revert:/) {$type = q(Revert);}
  #my $summary = $_;
  $summary =~ s/^\s*(\w+):\s*//;
  my @toolsets = ( $summary =~ /\@toolset\((\S+)\)/g );
  push @toolsets, q(Unknown) unless scalar @toolsets;
  foreach my $toolset (@toolsets) {
    print qq(${toolset}\t${type}\t${date}\t$summary);
  }
}

