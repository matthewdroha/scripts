#!/usr/intel/pkgs/perl/5.6.1/bin/perl

use strict;
use warnings;
use Time::Local;


open (LOGFILE, $ARGV[0]) or die;

my $flow;
my $month_string;
my $day;
my $hoursminsec;
my $hours;
my $min;
my $sec;
my $year;
my $month;
my %time_record;
my $stage;
my $run_died = 0;
my @stat_list;

while (<LOGFILE>) {
  if (/^(.+)((started at:)|(finished at:))\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
    chomp;
    #print "$_\n";
    $flow = $1;
    chop($flow);
    $month_string = $6;
    $day = $7;
    $hoursminsec = $8;
    $year = $10;
    ($hours, $min, $sec) = split(/:/, $hoursminsec);
    $month = &ConvertMonthStringToInt($month_string);
    if (/started/) {
      $stage = 'START';
    } else {
      $stage = 'FINISH';
    }
    $time_record{$flow}{$stage} = timelocal($sec, $min, $hours, $day, $month, $year);
  }
  if (/Aborting/) {
    $run_died = 1;
  } 
}

close (LOGFILE);

my $elapsed_seconds;
my $end_time;
my $start_time;
my $days;
my $status;
my %reportmap;
foreach $flow (sort by_mig_stage keys %time_record) {
  if (exists $time_record{$flow}{'START'}) {
    $start_time = $time_record{$flow}{'START'};
  } else {
    die "Problem: Found flow: $flow but did not register a start time\n";
  }
  if ((exists $time_record{$flow}{'FINISH'})) {
    $end_time = $time_record{$flow}{'FINISH'};
    $status = '';
  } else {
    if ($run_died) {
      @stat_list = stat($ARGV[0]);
      $end_time= $stat_list[9];
      $status = 'DIED ';
    } else {
      $end_time = time();
      $status = 'RUNNING ';
    }
  }
  $elapsed_seconds = $end_time - $start_time;
  ($days, $hours, $min, $sec) = &ConvertEpochSecondsToElapsedTime($elapsed_seconds);
  print "${status}($flow) elapsed run time: $days days  $hours hours  $min minutes  $sec seconds\n";
}


sub by_mig_stage { &GetFlowWeight($a) <=> &GetFlowWeight($b) }

sub GetFlowWeight {

  my $flow = shift;
  my %flow_weight;

  $flow_weight{'SC run'} = 0;
  $flow_weight{'Finish run'} = 2;
  $flow_weight{'Run'} = 3;
  $flow_weight{'Xgridding run'} = 1;

  if (exists $flow_weight{$flow}) {
    return $flow_weight{$flow};
  } else {
    return 4;
  }
}



sub ConvertEpochSecondsToElapsedTime {

  my $elapsed_seconds = shift;
  my $remainder = $elapsed_seconds;

  my $days = int($remainder / 86400);
  $remainder = int($remainder % 86400);
  my $hours = int($remainder / 3600);
  $remainder = int($remainder % 3600);
  my $minutes = int($remainder / 60);
  my $seconds = int($remainder % 60);
  
  return ($days, $hours, $minutes, $seconds);
}



sub ConvertMonthStringToInt {

  my $month_string = shift;
  my %MONTH;

  $month_string = lc($month_string);

  $MONTH{'jan'} = 0;
  $MONTH{'feb'} = 1;
  $MONTH{'mar'} = 2;
  $MONTH{'apr'} = 3;
  $MONTH{'may'} = 4;
  $MONTH{'jun'} = 5;  
  $MONTH{'jul'} = 6;  
  $MONTH{'aug'} = 7;
  $MONTH{'sep'} = 8;
  $MONTH{'oct'} = 9;
  $MONTH{'nov'} = 10;
  $MONTH{'dec'} = 11;

  if (exists ($MONTH{$month_string})) {
    return $MONTH{$month_string}
  } else {
    die "ConvertMonthStringToInt: Input month not matched\n";
  }
}
