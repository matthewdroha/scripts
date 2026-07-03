#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: sum2csv.pl,v 1.1.1.1 2007/07/25 21:19:25 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: sum2csv.pl,v 1.1.1.1 2007/07/25 21:19:25 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: sum2csv.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Parses PDS sum files and writes output to csv format. Also can
be used to filter results and write additional reports for
the filters

=cut

# Will redefine when we get a permanant UE friendly setup for 1266 and migration

BEGIN {
  if (defined $ENV{'DA_OVR'}) {
    push @INC, $ENV{'DA_OVR'};
  } else {
    if (defined $ENV{'LAY_UTILS_ROOT'}) {
      push @INC, "$ENV{'LAY_UTILS_ROOT'}/../include/perl";
    } else {
      die "\n-E- sum2csv.pl: Something is wrong with UE session: \$LAY_UTILS_ROOT not defined\n";
    }
  }
}

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd 'abs_path';
use DAStdLib;
use PdsStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();


my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME  [-sumfile <sumfile or directory>]
                   [-sumre <regex filter for PDS sum file names>]
                   [-filtercsv <.csv file containing filter spec>]
                   [-writeplayerr]
                   [-flowre <regex filter for -filtercsv reports>]
                   [-help] [-debug] [-verbose]

flag descriptions:

-sumfile          Argument is .sum file which will be used as input
                  For multiple files, one -sumfile flag should be
                  called for each file.
                  If an entry is a directory, then all sumfiles
                  in that directory will be processed
                  If this flag is not specified, it will assume
                  the directory will be \$PDSLOGS

-sumre            Takes a regex as input. Will only process PDS
                  sumfiles that match that regex. Is case sensitive.
                  Output filter files will contain word characters in
                  this spec as prefix

-filtercsv        Argument will be a .csv file which contains filtering
                  directives for various error codes. One .<filter>.filter
                  file will be written for each filter column in the .csv.
                  For each playerr, layerr, herr, and pherr file listed in
                  the sum file, all non-filtered error codes will be written
                  to a pruned version of the file. Full path of err files
                  will be stripped, seach will be conducted in \$PDSERRFILES
                  Format of err files: <cell>_<flow>_<filter>.<type>

-flowre           Takes regex as input. For use with -filtercsv. The
                  filtered report files will only report the ISS flows
                  that match this regex.

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -sumfile pbctrsn.drcd.iss.log.sum -sumfile iecrud.drcd.iss.log.sum
example: $EXE_NAME -sumfile . -filtercsv ~/filter.csv -flowre 'drcd|fillable'

Files that result from this run:


EOD
  
# Parse command line parameters, check if input files exist, etc...

# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_help, $opt_debug, $opt_verbose);
our (@opt_sumfile, $opt_filtercsv, $opt_flowre, $opt_sumre);
my $options_ok = &GetOptions("help",
			     "sumfile=s@",
			     "sumre=s",
			     "filtercsv=s",
			     "flowre=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help;

my @required_flag_list = ('');
my @argv_snapshot = @MAILARGV;
#&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

if (($opt_flowre) and (!$opt_filtercsv)) {
  die "-F- $EXE_NAME: Must use -filtercsv with -flowre option\n";
}

##### Main Program #####

#our ();
my @env_list = ();

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


our ($BASEFILE, $MAINLOG, $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = ${EXE_PREFIX};

# Set a file prefix if -sumre is used
my $file_prefix;
if ($opt_sumre) {
  $file_prefix = $opt_sumre;
  $file_prefix =~ s/(\W+)//g;
  if ($file_prefix !~ /\w/) {
    $file_prefix = "_NOWORDCHARS_";
  }
  $file_prefix .= ".${EXE_PREFIX}";
} else {
  $file_prefix = $EXE_PREFIX;
}

unless (scalar @opt_sumfile) {
  push (@opt_sumfile, $PDSLOGS);
}


$MAINLOG = LogFile->new("${file_prefix}.log");
$MAINLOG->flowname($EXE_NAME);
$MAINLOG->verbose($opt_verbose);

my $machine_info = `uname -a`;
chomp $machine_info;
$MAINLOG->info("Script command: $EXE_NAME $COMMAND_LINE");
$MAINLOG->info("Script start date: $start_date");
$MAINLOG->info("Machine Type: $machine_info");


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @TMPFILES = ();

my $sumre;
if ($opt_sumre) {
  $sumre = $opt_sumre;
  $MAINLOG->info("-sumre detected. Only PDS sumfiles matching to $sumre will be processed");
} else {
  $sumre = '.';
}
  

my @sumfile_list; 
# For each sumfile
foreach my $entry (@opt_sumfile) {
  if (-d $entry) {
    $MAINLOG->info("Directory detected. Will harvest all iss.log.sum files from area: $entry");
    opendir (SUMDIR, $entry) or die $MAINLOG->fatalq("Could not open directory for reading: $entry");
    my @temp_sumfile_list = grep /.iss.log.sum$/, readdir(SUMDIR);
    foreach my $temp_sumfile (@temp_sumfile_list) {
      push (@sumfile_list, "${entry}/${temp_sumfile}");
    }
  } else {
    push (@sumfile_list, $entry);
  }
}


my %data_table;
my %duplicate_code_record;
my @resolved_sumfile_list;
foreach my $sumfile (@sumfile_list) {
  if ($sumfile =~ /$sumre/) {
    my ($name,$path,$suffix)  = fileparse($sumfile);
    my $resolved_path = abs_path($path);
    my $resolved_sumfile = join('', "${resolved_path}/", $name);
    $MAINLOG->infoq("Resolved sumfile path: $resolved_sumfile");
    $MAINLOG->info("Parsing PDS sumfile: $sumfile");
    push (@resolved_sumfile_list, $resolved_sumfile);
    &ReadPdsSumFile($MAINLOG, $resolved_sumfile, \%data_table, \%duplicate_code_record, $opt_debug);
  }
}
my $sumfile_count = scalar(@resolved_sumfile_list);
$MAINLOG->info("$sumfile_count sumfiles were processed");

if ($opt_debug) {
  foreach my $sumfile (sort keys %data_table) {
    $MAINLOG->infod("AFTERSUMREAD: $sumfile");
    foreach my $flow (sort keys %{ $data_table{$sumfile} }) {
      foreach my $code (sort keys %{ $data_table{$sumfile}{$flow} }) {
	foreach my $key (sort keys %{ $data_table{$sumfile}{$flow}{$code} }) {
	  $MAINLOG->infod("AFTERSUMREAD:$sumfile Flow:$flow Code:$code Key:$key Value: $data_table{$sumfile}{$flow}{$code}{$key}\n");
	}
      }
    }
  }
}


# Generate a list of flow-error code pairs that is the union of all data
my %merged_codes_table;
&GenerateFlowCodePairs(\%data_table, \%merged_codes_table);


# Print output csv file
my $csvoutfile = "${file_prefix}.csv";
&WriteSumCsv($MAINLOG, $csvoutfile, \@resolved_sumfile_list, \%data_table, \%merged_codes_table);


if ($opt_debug) {
  foreach my $sumfile (sort keys %data_table) {
    $MAINLOG->infod("AFTERCSVWRITE: $sumfile");
    foreach my $flow (sort keys %{ $data_table{$sumfile} }) {
      foreach my $code (sort keys %{ $data_table{$sumfile}{$flow} }) {
	foreach my $key (sort keys %{ $data_table{$sumfile}{$flow}{$code} }) {
	  $MAINLOG->infod("AFTERCSVWRITE:$sumfile Flow:$flow Code:$code Key:$key Value: $data_table{$sumfile}{$flow}{$code}{$key}\n");
	}
      }
    }
  }
}



if ($opt_filtercsv) {
  my %filter_table;
  &ReadFilterCsv($MAINLOG, $opt_filtercsv, \%filter_table);
  my $flowre;
  if ($opt_flowre) {
    $flowre = $opt_flowre;
  } else {
    $flowre = '.';
  }
    
  &WriteSumReports($MAINLOG, $file_prefix, \@resolved_sumfile_list, \%data_table, \%filter_table, $flowre);
  &WriteErrFiles($MAINLOG, \@resolved_sumfile_list, \%data_table, \%filter_table, $flowre);
} 



$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete");



########## Begin subroutine definitions ##########

