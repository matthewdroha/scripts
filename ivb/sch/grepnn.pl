#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

my $grepre = shift;
my $logdir = cwd();
my $logdirfh = IO::Dir->new;
$logdirfh->open($logdir) or die "Could not open directory for reading: $logdir\n";
my @files = grep /\.log$/, $logdirfh->read;
$pdsdirfh->close;
unless (@files) {
  print "No .sum files found in current directory\n";
  exit;
}
foreach my $file (@files) {
  my $targetfh = IO::File->new;
  $targetfh->open($file);
  my $cell;
  ($cell) = split(/__/, $file);
  while (<$targetfh>) {
    if (/${grepre}/) {
      print "${cell}: $_";
    }
  }
}
