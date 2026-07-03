#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use IO::File;
use IO::Dir;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';


my $target_dir = shift;
die "No valid target directory given\n" unless $target_dir;
my $source_dir = cwd;
my $sourcefh = IO::Dir->new;
$sourcefh->open($source_dir) or die "Directory could not be opened: $source_dir";
my @files = grep /\.lnf$/, $sourcefh->read;
foreach my $file (@files) {
  print "cp $file $target_dir\n";
}
