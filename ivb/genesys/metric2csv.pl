#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;

my $currentdir = cwd();
my $currentdirfh = new IO::Dir;
$currentdirfh->open($currentdir) or die "Could not open directory for reading\n";
my @files = grep /\.genesysmaster\.genesyslog/, $currentdirfh->read();
$currentdirfh->close();

my %origin_hash;

foreach my $file (@files) {
  my $targetfh = new IO::File;
  $targetfh->open($file);
  print "Opening target file->($file)\n";
  while (<$targetfh>) {
    if (/getCellMetricsByCell:\s+(\S+)\s+(\S+)\:(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/) {
      my $cell = $1;
      my $lowerleftx = $2;
      my $lowerlefty = $3;
      my $width = $4;
      my $height = $5;
      my $devcount = $6;
      $origin_hash{$cell}{'YG CELL NAME'} = $cell;
      $origin_hash{$cell}{'YG NOMINAL CELL NAME'} = '';
      $origin_hash{$cell}{'YG LOWERLEFT_X'} = $lowerleftx;
      $origin_hash{$cell}{'YG LOWERLEFT_Y'} = $lowerlefty;
      $origin_hash{$cell}{'YG HEIGHT'} = $height;
      $origin_hash{$cell}{'YG WIDTH'} = $width;
      $origin_hash{$cell}{'YG DEVCOUNT'} = $devcount;
    } 
  }
  $targetfh->close();
}

foreach my $cell (sort keys %origin_hash) {
  my @nomcell_chars = split(//, $cell);
  $nomcell_chars[8] = $nomcell_chars[9] = 'n';
  my $nomcell = join("", @nomcell_chars);
  if (exists $origin_hash{$nomcell}) {
    $origin_hash{$cell}{'YG NOMINAL CELL NAME'} = $nomcell;
  }
}

my @fields = ('YG CELL NAME', 'YG NOMINAL CELL NAME', 'YG WIDTH', 'YG HEIGHT', 'YG DEVCOUNT');
my $fieldstring = join(",", @fields);
print "$fieldstring\n";
foreach my $cell (sort keys %origin_hash) {
  my @values = ();
  foreach my $field (@fields) {
    push @values, $origin_hash{$cell}{$field};
  }
  my $entry = join(",", @values);
  print "$entry\n";
}
