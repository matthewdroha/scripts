#!/usr/intel/pkgs/perl/5.26.1/bin/perl

=pod

=head1 COPYRIGHT

(C) Copyright Intel Corporation, 2019
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: duttest.pl
Domain: sip
Author: Matthew Roha

=cut

=head1 DESCRIPTION

B<dut.t> Generic prove test template

Instructions:
- Copy to t/ dir under repo.
- Rename to "<dut>.t" for running the test

Input: <dut>.t.jobs file as input in same directory as <dut>.t

Output: <dut>.t.log, <dut>.t.xlsx

=cut

use v5.26.1;
use strict;
use warnings;
use English;
use IPC::Open3;
use IO::File;
use File::Basename;
use File::Spec;
use Excel::Writer::XLSX;
use Test::More;

our ($jobfile, $logfile, $xlsxfile, $logfileh, $testcount, @stage_commands, $cellsheet, $rownum, $colnum);

# This 
BEGIN {
  my $tfile = File::Spec->rel2abs( __FILE__ );
  diag($tfile);
  $jobfile = ${tfile} . q(.jobs);
  diag("JOBFILE: $jobfile");
  $logfile = ${tfile} . q(.log);
  diag("LOGFILE: $logfile");
  $xlsxfile = ${tfile} . q(.xlsx);
  diag("XLSX: $xlsxfile");
  $logfileh = new IO::File;
  $logfileh->open(">$logfile") or die "Could not open file for writing: $logfile\n";
  $logfileh->autoflush(1);
}

main();

sub main {

  $testcount = read_file_to_list($jobfile, \@stage_commands);

  plan tests => $testcount + 2;

  is(exists $ENV{'CFG_PROJECT'}, 1, 'CFG_PROJECT set') or BAIL_OUT('$CFG_PROJECT not set');
  is(exists $ENV{'IP_ROOT'}, 1, 'IP_ROOT set') or BAIL_OUT('$IP_ROOT not set');


  my $stage_num = 1;
  my $basefilename = basename(__FILE__);
  my $workbook = Excel::Writer::XLSX->new($xlsxfile);
  $cellsheet = $workbook->add_worksheet($basefilename);
  $rownum = 1;
  $colnum = 0;
  foreach my $stage_command (@stage_commands) {
    my $stage_name;
    if ($stage_command =~ /\-logprefix\s+(\w+)\s*/) {
      $stage_name = $1;
    } else {
      $stage_name = qq(unnamed_stage_${stage_num});
    }
    is(run_stage_test($stage_name, $stage_command), 0, $stage_name);
    $stage_num++;
  }

  $cellsheet->add_table(0, 0, $rownum-1, $colnum-1,
                        {
                          columns => [
                            { header => 'stage' },
                            { header => 'exit_status' },
                            { header => 'elapsed_time (sec)' },
                            { header => 'elapsed_time (string)'},
                          ]
                        }
  );
  $cellsheet->activate;
  $workbook->close;
  $logfileh->close;
}


sub read_file_to_list {
  my $infile = shift;
  my $output_list_ref = shift;

  my $infilefh = new IO::File;
  $infilefh->open($infile) or die "Could not open file for reading: $infile\n";
  my $item_count = 0;
  while (<$infilefh>) {
    if (/^\s*\#/) {
      next;
    }
    elsif (/^\s*\S+/) {
      chomp;
      push @{ $output_list_ref }, $_;
      $item_count++;
    }
  }
  diag(qq($item_count items read from file->($infile)));
  $infilefh->close;
  return $item_count;
}


sub run_stage_test {
  my $stage_name = shift;
  my $stage_command = shift;
 
  my $cmd = qq(/usr/intel/bin/gtime -f elapsed_time_in_seconds:%e $stage_command);
  my $pid = open3(*SSH_IN, *SSH_OUT, 0, $cmd);
  my @outlines = <SSH_OUT>;
  close (SSH_IN);
  close (SSH_OUT);
  waitpid($pid, 0);
  my $elapsed_time_in_sec = 0;
  my $return_value = $?;
  foreach my $line (@outlines) {
    $logfileh->print($line);
    if ($line =~ /elapsed_time_in_seconds:(\S+)/) {
      #note("Found elapsed $1");
      $elapsed_time_in_sec = $1;
    }
  }
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(int($elapsed_time_in_sec));
  my $elapsed_time_string = sprintf("Elapsed time: %2d days, %2d hours, %2d minutes, %2d seconds\n", $yday, $hour, $min, $sec);

  $colnum = 0;
  foreach my $celldata ($stage_name, $return_value, $elapsed_time_in_sec, $elapsed_time_string) {
    $cellsheet->write_string($rownum, $colnum, $celldata);
    $colnum++;
  }
  $rownum++;

  return $return_value;
}
