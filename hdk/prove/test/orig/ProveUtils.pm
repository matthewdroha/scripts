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

B<ProveUtils.pm> Generic prove utils

=cut

package ProveUtils;

use v5.26.1;
use strict;
use warnings;
use English;
use IPC::Open3;
use IO::File;
use File::Basename;
use File::Spec;
use Test::More;
use Excel::Writer::XLSX;

BEGIN {
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw(prep_handles test_commands run_test);
}

our ($logfile, $xlsxfile, $logfileh, $testcount, @commands, $cellsheet, $rownum, $colnum);


=head2

sub main {

  my $stage_num = 1;
  my $basefilename = basename(__FILE__);
  my $workbook = Excel::Writer::XLSX->new($xlsxfile);
  $cellsheet = $workbook->add_worksheet($basefilename);
  $rownum = 1;
  $colnum = 0;
  foreach my $command (@commands) {
    my $command_alias;
    if ($command =~ /\-logprefix\s+(\w+)\s*/) {
      $command_alias = $1;
    } else {
      $command_alias = qq(unnamed_stage_${stage_num});
    }
    is(run_stage_test($command_alias, $command), 0, $command_alias);
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

=cut


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


sub prep_handles {
  my $tfile = shift;
  my $logfileh_ref = shift;
  my $csvfileh_ref = shift;

  #diag("\n$tfile");
  my $logfile = ${tfile} . q(.log);
  #diag("LOGFILE: $logfile");
  my $csvfile = ${tfile} . q(.csv);
  #diag("CSV: $csvfile");
  $$logfileh_ref = new IO::File;
  $$logfileh_ref->open(">$logfile") or die "Could not open file for writing: $logfile\n";
  $$logfileh_ref->autoflush(1);
  $$csvfileh_ref = new IO::File;
  $$csvfileh_ref->open(">$csvfile") or die "Count not open csvfile for writing: $csvfile\n";
}

sub test_commands {
  my $tfile = shift;
  my $commands_ref = shift;
  my $ip_root = shift;
  my $logfileh = shift;
  my $csvfileh = shift;

  my $command_num = 1;
  my $testprefix = split(/\./, basename($tfile));

  foreach my $command (@{$commands_ref}) {
    my $command_alias;
    if ($command =~ /\-logprefix\s+(\w+)\s*/) {
      $command_alias = $1;
    } else {
      $command_alias = qq(unnamed_stage_${testprefix}_${command_num});
    }
    my $command_ver;
    if ($command =~ /^\s*(simbuild|febe)/) {
      $command_ver = qq($command -ver $ip_root);
    } else {
      $command_ver = $command;
    }
    #diag($command_ver);
    is(run_test($command_alias, $command_ver, $logfileh, $csvfileh), 0, $command_alias);
    $command_num++;
  }
}

sub run_test {
  my $command_alias = shift;
  my $command = shift;
  my $logfileh = shift;
  my $csvfileh = shift;
 
  my $cmd = qq(/usr/intel/bin/gtime -f elapsed_time_in_seconds:%e $command);
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
  my $elapsed_time_string = sprintf("Elapsed time: %2d days, %2d hours, %2d minutes, %2d seconds", $yday, $hour, $min, $sec);

  #$colnum = 0;
  #foreach my $celldata ($command_alias, $return_value, $elapsed_time_in_sec, $elapsed_time_string) {
  #  $cellsheet->write_string($rownum, $colnum, $celldata);
  #  $colnum++;
  #}
  #$rownum++;

  my $csvstring = join(',', $command_alias, $return_value, $elapsed_time_in_sec, $elapsed_time_string);
  $csvfileh->print("${csvstring}\n");

  return $return_value;
}

1;
