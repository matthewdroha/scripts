#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

my $grepre = shift;
my $pdsdir = cwd();
my $pdsdirfh = IO::Dir->new;
$pdsdirfh->open($pdsdir) or die "Could not open directory for reading\n";
my @files = grep /\.sum$/, $pdsdirfh->read;
$pdsdirfh->close;
unless (@files) {
  print "No .sum files found in current directory\n";
  exit;
}
foreach my $file (@files) {
  my $targetfh = IO::File->new;
  $targetfh->open($file);
  my $cell;
  ($cell) = split(/\./, $file);
  while (<$targetfh>) {
    if (/${grepre}/) {
      printf "%40s: %s", ${file}, $_;
    }
  }
}
