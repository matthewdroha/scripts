#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

my $pdsdir = cwd();
my $pdsdirfh = IO::Dir->new;
$pdsdirfh->open($pdsdir) or die "Could not open directory for reading\n";
my @files = grep /trclvs\.cell\.log$/, $pdsdirfh->read;
$pdsdirfh->close;
unless (@files) {
  print "No cell.log files found in current directory\n";
  exit;
}
print "cell,top block,library\n";
foreach my $file (@files) {
  my $targetfh = IO::File->new;
  $targetfh->open($file);
  my $block;
  ($block) = split (/\./, $file);
  while (<$targetfh>) {
    if (/^(\w+)\s+(\w+)\s+(\S+)\s+(\S+)\s*$/) {
      my $lib = $1;
      my $cell = $2;
      my $version = $3;
      my $row = join(',', $cell,$block,$lib,$version);
      print "${row}\n";
    }
  }
}
