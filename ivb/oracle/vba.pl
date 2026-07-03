#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

my $curdir = cwd();
my $curdirfh = IO::Dir->new;
$curdirfh->open($curdir) or die "Could not open directory for reading: $curdir\n";
my @files = grep /\.(cls|bas)$/, $curdirfh->read;
$curdirfh->close;
unless (@files) {
  print "No .cls or .bas files found in current directory\n";
  exit;
}
#print "class name,total lines,code lines,comment lines,blank lines\n";
print "class name,function,lines\n";
foreach my $file (@files) {
  my $targetfh = IO::File->new;
  $targetfh->open($file);
  my $total_lines = 0;
  my $physical_code_lines = 0;
  my $comment_lines = 0;
  my $blank_lines = 0;
  my $function_lines = 0;
  my $function = '';
  while (<$targetfh>) {
    $total_lines++;
    if (/^\s*\'/) {
      $comment_lines++;
    }
    elsif (/\w+/) {
      $physical_code_lines++;
      if ($function) {
	$function_lines++;
      }
    } else {
      $blank_lines++;
    }
    if (/^\s*(Private|Public)?\s*(Sub|Property\s+Get|Property\s+Let|Function)\s+(\S+)/) {
      $function = $3;
      $function =~ s/(\(|\))//g;
    }
    if (/^\s*End\s+(Property|Function|Sub)/) {
      my $function_line = join(',', $file, $function, $function_lines);
      print "$function_line\n";
      $function = '';
      $function_lines = 0;
    }
  }
  $targetfh->close;
  my $line = join(',', $file,$total_lines,$physical_code_lines,$comment_lines,$blank_lines);
  #print "$line\n";
}
