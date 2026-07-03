#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w
#
# $Id: lintnb.pl,v 1.1 2015/12/23 02:54:40 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: lintnb.pl,v 1.1 2015/12/23 02:54:40 mroha Exp $

Filename: lintnb.pl
Project: ihdk
Author: Matthew Roha

Functional Description: Script lints incoming .csv files before import into SQL server

=cut


BEGIN {
  use IO::Dir
  my %homedir;
  my $homeproject = "ihdk";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  # Patch for non-eclogin people
  $ENV{'EC_SITE'} = 'fm';
  if (defined $ENV{'EC_SITE'}) {
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new;
    $dir->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $dir->read();
    if (-d "$homedir{$ENV{'EC_SITE'}}/override") {
      push @INC, "$ENV{'HOME'}/override";
    }
    if (-d "$homedir{$ENV{'EC_SITE'}}/Excel-Writer-XLSX-0.77/lib") {
      push @INC, "$homedir{$ENV{'EC_SITE'}}/Excel-Writer-XLSX-0.77/lib";
    }
    foreach my $item (@dirs) {
      if (-d "${code_dir}/${item}") {
        push @INC, "${code_dir}/${item}";
      }
    }
  } else {
    print "Environment var EC_SITE is not defined. Please make your environment eclogin compliant\n";
    exit;
  }
}

use strict;
use warnings;
use English;
use Carp;
use Getopt::Long;
use Time::Local;
use IO::File;
use Text::CSV;
use Env;
use File::Path;
use File::Basename;
use File::Temp;
use Cwd 'abs_path';
use Logfile;
use DAStd;


my $code_dir = GetCodeDir('ihdk');
my $exe_name;
my $exe_prefix;
($exe_name, $exe_prefix) = GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = GetDate();

 # Get the site
our $site = GetSite();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $exe_name --incsv <path to input .csv file>
                  --outcsv <path to output .csv file>
                  [--env 'VAR=VALUE']
                  [--help] [--verbose] [--debug]

flag descriptions:

--incsv             Input csv file.

--outcsv            Output csv file.

--env               Optional. Set env var at start of execution. Can provide more than
                    one --env flag.  Format is VAR=VALUE

--debug             Run flow in debug mode. Temporary files are not deleted and
                    additional data is placed in log file.

--verbose           Will add status messages to STDOUT.

--help              This usage message will appear. 


example: $exe_name --incsv input.csv --outcsv output.csv

Files that result from this run:

\${exe_prefix}.log

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $exe_name: No command line parameters. Use --help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_incsv, $opt_outcsv);
our (@opt_env);
our ($opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
		            "incsv=s",
			    "outcsv=s",
			    "env=s@",
			    "debug",
			    "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help;
my @required_flag_list = ('--incsv', '--outcsv');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');
foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your shell session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
our ($basefile, $log);
$basefile = "${exe_prefix}";
$log = Logfile->new("${basefile}.log");
$log->flowname($exe_name);
$log->verbose($opt_verbose);
$log->debug($opt_debug);
my $machine_info = `uname -a`;
chomp $machine_info;
$log->info("Script command: $exe_name $command_line");
$log->info("Script start date: $start_date");
$log->info("System info: $machine_info");


# Global temporary files list. Any file or directort added to this list
# will be deleted after execution is complete, unless --debug is used.
our @tmplist = ();


# Set any command line env vars
if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $log->infoq("--env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $log->fatalq("Invalid value for switch --env: $setting");
    }
  }
}


# Intialize stage number for log file
my $stage = 0;

# Parse
my $incsv = abs_path($opt_incsv);
unless (-f $incsv) {
  croak $log->fatalq("Input CSV does not exist: $incsv");
}
$log->info("CSV->(${incsv})");
my $incsvfh = IO::File->new($incsv) or croak $log->fatalq("Input csv file could not be opened for reading->($incsv)");

my $outcsv = abs_path($opt_outcsv);
my $outCsvFh = IO::File->new("> $outcsv") or croak $log->fatalq("Output csv file coult not be opened for writing->($outcsv)");
my @dateFields = ("1", "2", "3", "4");
my $writtenRowCount = 0;
my $cmdLength = 0;
my @fieldHeaders;
my %maxStringLengthCounts;
while (<$incsvfh>) {
  if ($. == 1) {
    s/Fullid/FullId/;
    s/Cmdname/CmdName/;
    s/starttime\-iterationsubmittime/StartTimeMinusSubmitTime/;
    s/finishtime\-starttime/FinishTimeMinusStartTime/;
    s/Cmdline/CmdLine/;
    s/DemandDriver_ID/DemandDriverID/;
    s/DemandDriver_Group/DemandDriverGroup/;
  }
  my @record = split(',', $_);
  chomp @record;
  my $writeRecord = 0;
  if ($. == 1) {
    $writeRecord = 1;
    @fieldHeaders = split(',', $_);
    chomp(@fieldHeaders);
    my $fieldNumber = 0;
    foreach my $fieldName (@record) {
      $maxStringLengthCounts{$fieldNumber} = 0;
      $fieldNumber++
    }
  }
  elsif (scalar @record != 25) {
    my $fieldCount = scalar @record;
    $log->info("Field Count Problem: Field Count->(${fieldCount}) Line $.->($_)");
    if ($opt_debug) {
      my $count = 0;
      foreach my $field (@record) {
	$log->infod("Field->($count) Value->($field)");
	$count++;
      }
    }
      
  } else {
    if (length($record[13]) > 900) {
      my $logString = sprintf("%s%s%s", "Very Long Command Line: Length->(", 
			      length($record[13]), ") Line $.->($_)");
      $log->infod($logString);
    }
    my $fieldNumber = 0;
    foreach my $field (@record) {
      if (defined $record[$fieldNumber] and (length($record[$fieldNumber]) > $maxStringLengthCounts{$fieldNumber})) { 
	$maxStringLengthCounts{$fieldNumber} = length($record[$fieldNumber]);
      }
      $fieldNumber++;
    }
    foreach my $field (@dateFields) {
      if ($record[${field}] eq '') {
	next;
      }
      elsif ($record[${field}] !~ /\d{4}\-\d{2}\-\d{2}/) {
	$log->info("Unexpected Date Format: Line $.->($_)");
	next;
      }
      elsif ($record[${field}] =~ /(\d{4})\-(\d{2})\-(\d{2})\s+(\d{2})\:(\d{2})\:(\d{2})\.\d+\s*$/) {
	#my $month = $1;
	#my $day = $2;
	#my $year = $3;
	#my $hour = $4;
	#my $min = $5;
	#my $sec = $6;
	#$record[${field}] = "${year}-${month}-${day} ${hour}:${min}:${sec}.000";
	$writeRecord = 1;
      } else {
	croak $log->fatalq("Unexpected date-time format: Line $.->($_)");
      }
    }
  }
  if ($writeRecord) {
    my $outRecord = join(',', @record);
    $outCsvFh->print("${outRecord}\n");
    $writtenRowCount++;
  }
}

my $rowCount = $.;
$incsvfh->close;
$outCsvFh->close;
my $fieldNumber = 0;
foreach my $fieldName (@fieldHeaders) {
  my $flag = '';
  if ($maxStringLengthCounts{$fieldNumber} > 50) {
    $flag = ' ***';
  }
  $log->info("Max String Size: $fieldName->($maxStringLengthCounts{$fieldNumber})${flag}");
  $fieldNumber++;
}
$log->info("Total Row Count->($rowCount)");
$log->info("Written Row Count->($writtenRowCount)");

DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$log->info("Script completion date: $stop_date");
$log->info("$exe_name run complete");
$log->close;
