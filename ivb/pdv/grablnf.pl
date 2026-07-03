#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use File::Copy;
use File::Path;
use File::Basename;
use IO::Dir;
use IO::File;
use Env;

my $celllogfile = shift;
my $targetdir = shift;
my $keepstd = shift;
unless (-f $celllogfile) {
  die "Input cell.log file not found: $celllogfile\n";
}

unless (-d $targetdir) {
  die "Target directory does not exist: $targetdir\n";
}

chmod 0755, $targetdir;
my @timeinfo = localtime;
my $year = $timeinfo[5] + 1900;
my $month = $timeinfo[4] + 1;
if (length($month) == 1) {
  $month = "0${month}";
}
my $day = $timeinfo[3];
my $tag = "${year}_${month}_${day}_$$";

my $targetfh = IO::File->new;
$targetfh->open($celllogfile);
my $block;

my $goodcellfile = 0;
my $issin_count = 0;
my $firstlnf = 1;
my $copied_count = 0;
my $skipped_count = 0;
while (<$targetfh>) {
  $_ =~ s/NO_VER//;
  if (/CONVERTED CELL INFORMATION/) {
    $goodcellfile = 1;
  }
  if (/Total number of cells processed:\s+(\d+)/) {
    $issin_count = $1;
  }
  if (/^\s*Top Cell\s+\.+\s+(\S+)\s*$/) {
    my $topblock = $1;
    $targetdir = "${targetdir}/${topblock}_${tag}";
  }
  if (/^\s*\S+\s+(\S+)\s+\S+\s+(lnf|LNF)\s+(\S+)\s*$/) {
    if ($firstlnf) {
      unless (-d $targetdir) {
	mkpath($targetdir, 0, 0755);
	unless (-d $targetdir) {
	  die "Unable to create new targetdir: $targetdir\n";
	}
      }
      my $celllogfile_base = basename($celllogfile);
      my $ok = copy($celllogfile, "${targetdir}/${celllogfile_base}");
      unless ($ok) {
	die "Could not copy file to target directory.\nSource->($celllogfile)\nTarget->(${targetdir}/${celllogfile_base})\n";
      }
      print "Input cell.log file->(${celllogfile})\n";
      print "Target directory->(${targetdir})\n";
      $firstlnf = 0;
    }
    my $cell = $1;
    my $lnffile = $3;
    unless ($goodcellfile) {
      die "Input file is not a cell.log file: $celllogfile\n";
    }
    if ($cell =~ /^(ai0|ai3|ai7|an4|a80|axx|ax0|ivb_|glbdrv$|basic_glbdrv$)/) {
      unless ($keepstd) {
	$skipped_count++;
	next;
      }
    }
    my $targetfile = "${targetdir}/${cell}.lnf";
    my $ok = copy($lnffile, $targetfile);
    $copied_count++;
    unless ($ok) {
      die "Could not copy file to target directory.\nSource->(${lnffile})\nTarget->(${targetfile})\n";
    }
    chmod 0755, $targetfile;
  }
}
$targetfh->close;
my $total_lnfs_found = $copied_count + $skipped_count;
print "Total cells copied->(${copied_count})\n";
print "Total std cells not copied->($skipped_count)\n";
print "Total cells found during parsing->(${total_lnfs_found})\n";
print "Total cells processed by ISSIN->(${issin_count})\n";


unless ($goodcellfile) {
  die "Input file is not a cell.log file: $celllogfile\n";
}
