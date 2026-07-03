#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;

my @infile_list = @ARGV;

if (scalar @infile_list > 2) {
  die "More than two files passed as arguments. Don't support 3 as of yet.\n"
}

my %entry_table;

foreach my $infile (@infile_list) {
  open (INFILE, $infile) or die "Could not open file $infile\n";
  while (<INFILE>) {
    my ($entry) = split;
    if ($entry) {
      $entry = lc($entry);
      $entry_table{$infile}{$entry} += 1;
    }
  }
  close (INFILE);
}

for (my $i = 0; $i <= $#infile_list; $i++) {
  print "file${i} -> $infile_list[$i]\n";
}

# Report duplicate entries
for (my $i = 0; $i <= $#infile_list; $i++) {
  foreach my $entry0 (sort keys %{ $entry_table{$infile_list[$i]} }) {
    if ($entry_table{$infile_list[$i]}{$entry0} > 1) {
      print "Duplicate entries in file${i}: entry: ($entry0)  count: ($entry_table{$infile_list[$i]}{$entry0})\n";
    }
  }
  if (defined $infile_list[$i+1]) {
    foreach my $entry0 (sort keys %{ $entry_table{$infile_list[$i]} }) {
      if (exists $entry_table{$infile_list[$i+1]}{$entry0}) {
	print "($entry0) exists in file${i} AND in file", $i+1, "\n";
      } else {
	print "($entry0) exists in file${i} but NOT in file", ${i}+1, "\n";
      }
    }
    foreach my $entry1 (sort keys %{ $entry_table{$infile_list[$i+1] } }) {
      unless (exists $entry_table{$infile_list[$i]}{$entry1}) {
	print "($entry1) exists in file", $i+1," but NOT in file${i}\n";
      }
    }
  }
}
