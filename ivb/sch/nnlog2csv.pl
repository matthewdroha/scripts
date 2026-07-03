#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

my $netlistlogdir = cwd();
my $netlistlogdirfh = IO::Dir->new;
$netlistlogdirfh->open($netlistlogdir) or die "Could not open directory for reading: $netlistlogdir\n";
my @files = grep /__cdba_to\S+nike_netlister\.log$/, $netlistlogdirfh->read;
$netlistlogdirfh->close;
unless (@files) {
  print "No CDBA nike_netlister.log files found in current directory\n";
  exit;
}
print "top block,cell,view,version,library\n";
foreach my $file (@files) {
  my $targetfh = IO::File->new;
  $targetfh->open($file);
  my $block;
  ($block) = split (/__/, $file);
  while (<$targetfh>) {
    if (/^\s*\-I\-CdbaBuilder- Building Cell:\s+(\S+),\s+library:\s+(\S+),\s+(\S+)\.\s+version:\s+(\S+)\s*$/) {
      my $cell = $1;
      my $lib = $2;
      my $view = $3;
      my $version = $4;
      my $row = join(',', $block,$cell,$view,$version,$lib);
      print "${row}\n";
    }
  }
}
