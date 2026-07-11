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

B<ProveUtils.pm> Generic utilities for prove based IP testing

=cut

package ProveUtils;

use v5.26.1;
use strict;
use warnings;
use English;
use IPC::Open3;
use IO::File;
use IO::Dir;
use File::Basename;
use File::Path;
use File::Spec;
use Test::More;
use Excel::Writer::XLSX;

BEGIN {
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw(open_handles test_commands get_commands_from_string write_prove_summary_and_xlsx get_intel_datetime duplicate_tests_in_testrules tests_not_in_testrules);
}

sub get_commands_from_string {
  my $command_string = shift;

  my @commands = split(/\n/, $command_string);
  my @clean_commands;
  foreach my $command (@commands) {
    if ($command =~ /^\s*\#/) { next };
    if ($command =~ /\w+/) { push @clean_commands, $command };
  }
  return @clean_commands;
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


sub open_handles {
  my $tfile = shift;
  my $logfileh_ref = shift;

  my ($tname, $tdir, $suffix) = fileparse($tfile);
  my $logdir = qq(${tdir}/logs);
  create_dir_trees($logdir) or BAIL_OUT("Could not create dir: $logdir");
  my $logfile = qq(${logdir}/${tname}.log);
  $$logfileh_ref = new IO::File;
  $$logfileh_ref->open(">$logfile") or BAIL_OUT("Could not open file for writing: $logfile");
  $$logfileh_ref->autoflush(1);
}


sub test_commands {
  my $tfile = shift;
  my $commands_ref = shift;
  my $ip_root = shift;
  my $logfileh = shift;
  my $todo_string = shift;

  my $command_num = 1;
  my $testprefix = basename($tfile, '.t');

  my $command_alias;
  my $final_command;
  foreach my $input_command (@{$commands_ref}) {
    if ($command_num == 1) {
      $command_alias = qq(${testprefix});
    } else {
      $command_alias = sprintf("%s_cmd%01d", $testprefix, $command_num);
    }
    if ($input_command =~ /^\s*(simbuild|febe)/) {
      $final_command = qq($input_command -logprefix $command_alias -ver $ip_root);
    } else {
      $final_command = $input_command;
    }
    #diag($final_command);
    if ($todo_string) {
      TODO: {
        local $TODO = $todo_string;
        is(run_test($command_alias, $final_command, $logfileh), 0, $command_alias);
      }
    } else {
      is(run_test($command_alias, $final_command, $logfileh), 0, $command_alias);
    }
    $command_num++;
  }
}

sub run_test {
  my $command_alias = shift;
  my $command = shift;
  my $logfileh = shift;

  my $pid = open3(*CMD_IN, *CMD_OUT, 0, $command) or die ("Command not found or invalid: $command\n");
  close (CMD_IN);
  my @outlines = <CMD_OUT>;
  close (CMD_OUT);
  waitpid($pid, 0);
  my $return_value = $?;
  foreach my $line (@outlines) {
    $logfileh->print($line);
  }

  return $return_value;
}

sub write_prove_summary_and_xlsx {
  my $tfile = shift;
  my $dut = shift;

  my @rowdata;

  my ($tname, $tdir, $suffix) = fileparse($tfile, '.t');
  my $infile = ${tdir} . qq(${dut}.prove.log);
  my $simbuildlog = ${tdir} . qq(logs/simbuild_doa.t.log);
  my $sumfile  = ${tdir} . qq(${dut}.prove.sum);
  my $xlsxfile = ${tdir} . qq(${dut}.prove.xlsx);
  my $sumfileh = new IO::File;
  $sumfileh->open(">$sumfile") or die "Could not open file for writing: $sumfile\n";
  my $workbook = Excel::Writer::XLSX->new($xlsxfile);
  my $timersheet = $workbook->add_worksheet("prove.timer");
  my $sumsheet = $workbook->add_worksheet("prove.summary");
  my $rownum = 1;

  my $simbuildlogh = new IO::File;
  my %onecfg_values;
  $simbuildlogh->open($simbuildlog) or die "Could not open file for reading: $simbuildlog\n";
  while (<$simbuildlogh>) {
    if (/^\s*(ONECFG_\w+)=(\S+)\s*$/) {
      $onecfg_values{$1} = $2;
    }
  }
  $simbuildlogh->close;

  foreach my $varvalue (qw(ONECFG_dut ONECFG_toolset ONECFG_process ONECFG_dot_process ONECFG_STDLIB_TYPE)) {
    die "Value not found for env var $varvalue\n" unless exists $onecfg_values{$varvalue};
  }
  my $fullprocessname = qq($onecfg_values{ONECFG_process}$onecfg_values{ONECFG_dot_process});
  my @onecfgvars = ($onecfg_values{ONECFG_dut},$onecfg_values{ONECFG_toolset},$fullprocessname,$onecfg_values{ONECFG_STDLIB_TYPE});
  
  my $infileh = new IO::File;
  $infileh->open($infile) or die "Could not open file for reading: $infile\n";
  my $testfail = 0;
  my ($dots, $provestarttime, $provefinishtime, $testfinishtime, $test, $elapsed_time_in_sec);
  $provestarttime = $provefinishtime = q(NA);
  while (<$infileh>) {
    if (/\# prove_start\s+(.+)\s*$/) {
      $provestarttime = $1;
      $sumfileh->print("prove start time: $provestarttime\n");
    }
    elsif (/\# prove_finish\s+(.+)\s*$/) {
      $provefinishtime = $1;
      $sumfileh->print("prove finish time: $provefinishtime\n");
    }
    elsif (/^\[(\d+\:\d+\:\d+)\]\s+(\S+)\s+(\.+)\s+ok\s+(\d+)\s+ms\s+/) {
      $testfinishtime = $1;
      $test = $2;
      $dots = $3;
      $elapsed_time_in_sec = int($4 / 1000);
      my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(int($elapsed_time_in_sec));
      my $elapsed_time_string = sprintf("Elapsed time: %2d days, %2d hours, %2d minutes, %2d seconds", $yday, $hour, $min, $sec);
      @rowdata = (@onecfgvars,$rownum,$test,q(0),$testfinishtime,$elapsed_time_in_sec,$elapsed_time_string);
      $timersheet->write_row($rownum, 0, \@rowdata);
      my $sumstring = sprintf("%s %s ok %9s s   %s\n", $test, $dots, $elapsed_time_in_sec, $elapsed_time_string);
      $sumfileh->print($sumstring);
      $rownum++;
    }
    elsif (/^\[(\d+\:\d+\:\d+)\]\s+(\S+)\s+(\.+)\s*$/) {
      $testfinishtime = $1;
      $test = $2;
      $dots = $3;
      $testfail = 1;
    }
    elsif ((/Dubious\, test returned\s+\d+\s+\(wstat\s+(\d+)\,/) and ($testfail)) {
      my $return_value = $1;
      @rowdata = (@onecfgvars,$rownum,$test,$return_value,$testfinishtime, q(FAIL),q(FAIL));
      $timersheet->write_row($rownum, 0, \@rowdata);
      my $sumstring = sprintf("%s %s **FAIL** return_value=%s\n", $test, $dots, $return_value);
      $sumfileh->print($sumstring);
      $rownum++;
      $testfail = 0;
    }
    elsif (/^Files=(\d+), Tests=(\d+), (\d+) wallclock secs/) {
      $elapsed_time_in_sec = $3;
      my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(int($elapsed_time_in_sec));
      my $elapsed_time_string = sprintf("Elapsed time: %2d days, %2d hours, %2d minutes, %2d seconds", $yday, $hour, $min, $sec);
      @rowdata = (@rowdata,$1,$2,$provestarttime,$provefinishtime,$elapsed_time_in_sec,$elapsed_time_string);
      $sumsheet->write_row(1, 0, \@rowdata);
      $sumsheet->add_table(0, 0, 1, 9,
        {
          columns => [
            { header => 'dut' },
            { header => 'toolset' },
            { header => 'process' },
            { header => 'STDLIB_TYPE' },
            { header => 'files' },
            { header => 'tests' },
            { header => 'prove_start'},
            { header => 'prove_finish'},
            { header => 'elapsed_time (sec)' },
            { header => 'elapsed_time (string)'},
          ]
        }
      );
      my $sumstring = sprintf("Files=%s Tests=%s %s s  elapsed_time_string=%s\n", $1, $2, $elapsed_time_in_sec,$elapsed_time_string);
      $sumfileh->print($sumstring);
      last;
    }
  }
  if ($provefinishtime eq 'NA') {
    $sumfileh->print("No finish time found for prove run (Killed)\n");
  }
  $timersheet->add_table(0, 0, $rownum-1, 9,
    {
      columns => [
        { header => 'dut' },
        { header => 'toolset' },
        { header => 'process' },
        { header => 'STDLIB_TYPE' },
        { header => 'testnum' },
        { header => 'test' },
        { header => 'exit_status' },
        { header => 'test_finish'},
        { header => 'elapsed_time (sec)' },
        { header => 'elapsed_time (string)'},
      ]
    }
  );
  $infileh->close;
  $sumfileh->close;
  $timersheet->activate;
  $workbook->close;
}

sub get_intel_datetime {
  my $label = shift;
  unless ($label) {$label = ""};

  my $date_command = q(echo "`/usr/intel/bin/workweek -f '%a %b %d %T %Z %Y'` `/usr/intel/bin/workweek -f 'WW%02IW' 'now-1*day'`.`/usr/intel/bin/workweek -f '%u'`");
  my $datestring = ${label}." ".`$date_command`;

  return $datestring;
}

sub create_dir_trees {
  my @targetdirs = @_;

  foreach my $dir (@targetdirs) {
    unless (-d $dir) {
      mkpath($dir, 0, 0755);
      unless (-d $dir) {
        return 0;
      }
    }
  }
  return scalar @targetdirs;
}


sub duplicate_tests_in_testrules {

  my $file = shift;

  my $filedir = dirname($file);
  my $testrules = ${filedir} . q(/testrules.yml);
  my $testrulesh = new IO::File;
  $testrulesh->open($testrules) or die "Could not open file for reading: $testrules\n";
  
  my %rules;
  while (<$testrulesh>) {
    if (/(\w+\.t)/) {
      say $1;
      $rules{$1}++;
    }
  }
  $testrulesh->close;

  my $failcount = 0;
  foreach my $rule (sort keys %rules) {
    if ($rules{$rule} > 1) {
      $failcount++;
      diag("Test declared in testrules.yml more than once: $rule $rules{$rule}")
    }
  }
  return $failcount;
}


sub tests_not_in_testrules {

  my $file = shift;

  my $filedir = dirname($file);
  my $testrules = ${filedir} . q(/testrules.yml);
  my $testrulesh = new IO::File;
  $testrulesh->open($testrules) or die "Could not open file for reading: $testrules\n";
  
  my %rules;
  while (<$testrulesh>) {
    if (/(\w+\.t)/) {
      say $1;
      $rules{$1}++;
    }
  }
  $testrulesh->close;

  my $filedirh = new IO::Dir;
  $filedirh->open($filedir) or die "Could not open directory for reading: $filedir\n";
  my @tfiles = grep /^\w+\.t$/, $filedirh->read;
  $filedirh->close;
  my $failcount = 0;
  foreach my $tfile (@tfiles) {
    unless (exists $rules{$tfile}) {
      $failcount++;
      diag("Test is missing from testrules.yml: $tfile")
    }
  }
  return $failcount;
}

1;
