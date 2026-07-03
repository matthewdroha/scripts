#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd 'abs_path';

our ($WORK_AREA_ROOT_DIR, $PDSLOGS, $PDSERRFILES);
opendir (PDSLOGS, $PDSLOGS) or die;
my @data_files = grep /\.data\.log$/, readdir (PDSLOGS);
closedir (PDSLOGS);
chdir $PDSLOGS or die;
my %stats_table;
foreach my $file (@data_files) {
  my $cell = $file;
  $cell =~ s/\.data\.log//;
  open (DATAFILE, $file) or die;
  $stats_table{$cell}{'cell'} = $cell;
  $stats_table{$cell}{'masters'} = 0;
  while (<DATAFILE>) {
    if (/^\s*\S+\(\d+\)\s+/) {
      $stats_table{$cell}{'masters'}++;
    }
  }
  close (DATAFILE);
}


chdir $WORK_AREA_ROOT_DIR or die;
foreach my $cell (keys %stats_table) {
  open (LOG, "${cell}.issrel.lnf.migstats.log") or die;
  #print "${cell}.issrel.lnf.migstats.log\n";
  while (<LOG>) {
    if (/run complete for cell:\s+(\S+)\s+\((\S+)\)/) {
      $stats_table{$1}{'stage'} = $2;
    }
  }
  close (LOG);
}

chdir $PDSERRFILES;
foreach my $cell (keys %stats_table) {
  my $errfile = "${cell}.migstats.err";
  open (ERR, $errfile) or die "Could not open $errfile\n";
  my $density_section = 0;
  my $flow;
  while (<ERR>) {
    if (/ERR_DENSITY/) {
      $density_section = 1;
    }
    if (/DENSITY\s+(\S+)\s+\{/) {
      $flow = $1;
    }
    if (($density_section) and (/^\s*${cell}/)) {
      my @record = split;
      if ($record[5] =~ /\d+\.\d+/) {
	#print "cell: $cell  flow: $flow  value: $record[5]\n";
	$stats_table{$cell}{$flow} = $record[5];	
      }
      $density_section = 0;
    }
  }
  close (ERR);
}
my @field_list = ('cell', 'stage', 'masters', 'alldiff', 'metal2', 'metal3', 'metal4');
print join(',', @field_list) . "\n";
foreach my $cell (keys %stats_table) {
  my @record = ();
  foreach my $item (@field_list) {
    push (@record, $stats_table{$cell}{$item});
  }
  my $record_string = join(',', @record);
  print "$record_string\n";
}
