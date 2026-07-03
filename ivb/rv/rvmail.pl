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




# Open the target dir, get file names
my $dir = "/usr/users/home2/mroha/spine_rv";
my $dir_h = IO::Dir->new;
$dir_h->open($dir) or die "Directory could not be opened: $dir\n";
my @files = grep /\.mail/, $dir_h->read;
print "FUB,RUN TYPE,CHECK,SUBCATEGORY,ERROR COUNT\n";
foreach my $file (@files) {
  my $fub;
  my $category;
  my $subcat;
  my $signal_val;
  my $power_val;
  my $run_type;
  # For each target file
  my $file_h = IO::File->new;
  $file_h->open("${dir}/${file}") or die "Could not open file for reading: $file\n";
  if ($file =~ /mytheri/) {
    $run_type = "SPINE";
  } else {
    $run_type = "FUB";
  }
  while(<$file_h>) {
    # Get the fub name
    # FUB-NAME             : llcdatclkspine00
    if (/FUB\-NAME\s+:\s+(\w+)/) {
      $fub = $1;
    }
    # RV Summary
    # | SH  | 0       | 0      |
    if (/^\s*\|\s+(\w+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s*$/) {
      $category = $1;
      $signal_val = $2;
      $power_val = $3;
      print "${fub},${run_type},${category},SIGNAL,$signal_val\n";
      print "${fub},${run_type},${category},POWER,$power_val\n";
    }
    # DCC Summary
    # | vcc   | 74    |
    if (/^\s*\|\s+(\w+)\s+\|\s+(\d+)\s+\|\s*$/) {
      $category = 'DCC';
      $subcat = uc($1);
      $power_val = $2;
      print "${fub},${run_type},${category},$subcat,$power_val\n";
    }
    # Hotspots
    # Number HotSpots      : 0 
    if (/Number\s+HotSpots\s+:\s+(\d+)/) {
      $category = 'HOTSPOTS';
      $subcat = 'HOTSPOTS';
      $power_val = $1;
      print "${fub},${run_type},${category},$subcat,$power_val\n";
    }
    # Terminate on  DETAILS:
    if (/DETAILS:/) {
      last;
    }
  }
}
