#!/usr/intel/pkgs/perl/5.12.2/bin/perl -w

=pod
=head1 COPYRIGHT

$Id: libstat.pl,v 1.1 2010/01/08 19:57:32 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to othjjers except in accordance with the terms and conditions
of that agreement.

Filename: libstat.pl
Project: coe75
Original Author: Matthew Roha

Functional Description: 

Reports the last checkin date and user for each library provided in the
target library list 

=cut

BEGIN {
  use IO::Dir;
  my $homeproject = 'coe75';
  my %homedir;
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'EC_SITE'}) {
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new;
    $dir->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $dir->read();
    if (-d "$ENV{'HOME'}/ovrd") {
      push @INC, "$ENV{'HOME'}/ovrd";
    }
    foreach my $item (@dirs) {
      if (-d "${code_dir}/${item}") {
	push @INC, "${code_dir}/${item}";
      }
    } 
  } else {
    die "Environment var EC_SITE is not defined. Please make your environment eclogin compliant\n";
  } 
}


use strict;
use warnings;
use English;
use IO::File;
use IO::Dir;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';
use DAStd;
use UE;
use Logfile;

my $code_dir = GetCodeDir('coe75');
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
usage:  $exe_name --libfile <path to libfile>
                  [--env VAR=VALUE]
                  [--help] [--verbose] [--debug]

flag descriptions:

--cdslib          Path to modified cdslib file
                  File format is DEFINE <lib> <path>

--env             Optional. Set env var at start of execution. Can provide more than
                  one --env flag.  Format is VAR=VALUE

--debug           Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

--verbose         Will add status messages to STDOUT.

--help            This usage message will appear. 


example: $exe_name --libfile cdslib.temp

Files that result from this run:

${exe_name}.csv

EOD



# Get command line options. GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (' ', @mailargv);
our ($opt_cdslib, @opt_env);
our ($opt_debug, $opt_verbose, $opt_help);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
			    "cdslib=s",
                            "env=s@",
			    "debug",
			    "verbose");
# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('--cdslib');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####



# Capture initial environment variables
our ($HOME, $USER);
my @env_list = ('HOME', 'USER');
foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
our ($logfh);
my $basefile = "${exe_prefix}";
$logfh = Logfile->new("${WORK}/${basefile}.log");
$logfh->flowname($exe_name);
$logfh->verbose($opt_verbose);
$logfh->debug($opt_debug);
my $machine_info = `uname -a`;
chomp $machine_info;
$logfh->info("Script command: $exe_name $command_line");
$logfh->info("Script start date: $start_date");
$logfh->info("System info: $machine_info");


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @tmplist = ();


# Set any command line env vars
if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $logfh->infoq("-env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $logfh->fatalq("Invalid value for switch -env: $setting");
    }
  }
}
my $home_area = "/usr/users/home2/mroha";

# Intialize stage number for log file
my $stage = 0;


# Read target library list
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Open/read cdslib file *****");
my $target_cdslib_fileh = IO::File->new;
my %lib_hash;
my $line_count;
$target_cdslib_fileh->open($opt_cdslib) or die $logfh->fatalq("Could not open target library file for reading: $opt_cdslib");
while (<$target_cdslib_fileh>) {
  if (/^\s*\#/) {
    next;
  }
  if (/^\s*DEFINE\s+(\S+)\s+(\S+)\s*$/) {
    $_ = lc($_);
    my $library = $1;
    my $path = $2;
    $lib_hash{$library} = $path;
    $line_count++;
  }
}
$target_cdslib_fileh->close;
my $lib_count = scalar keys %lib_hash;
$logfh->info("Lines read from target lib file->$line_count");
$logfh->info("Libraries read from target lib file->$lib_count");


# Validate target library list and hash paths
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Validate target library file *****");
my %targetpath_hash;
foreach my $library (sort keys %lib_hash) {
  my @record = split(/_/, $library);
  if (scalar @record != 3) {
    $logfh->errorp("Library->($library) has unexpected naming format, expect 3 underscore naming.  Skipping...");
    next;
  }
  my $target_lib_path = $lib_hash{$library};
  if (-e $target_lib_path) {
    $targetpath_hash{$library} = abs_path($target_lib_path);
    $logfh->info("Library base directory found lib->(${library}) abs_path->($targetpath_hash{$library}");
  } else {
    $logfh->errorp("Library->($library) could not be found in expected directory: $target_lib_path.  Skipping...");
  }
}


# Iterate through libraries and collect cell/cellview DB information
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Scan target libraries *****");
my %cell_table;
my @csvdata;
my @master_field_list = ('LIBRARY', 'CELL', 'CELLVIEW', 'VERSION', 'VERSION TAGS', 'CHECKIN DATE', 'AUTHOR');
# Foreach library
foreach my $library (sort keys %targetpath_hash) {
  my @record = split (/_/, $library);
  my $libtype = pop @record;
  #unless ($libtype eq 'sch') {
  #  next;
  #}
  $logfh->infod("Scanning Library->(${library})");
  my $targetlibdir = $targetpath_hash{$library};
  my $targetlibdirh = IO::Dir->new;
  $targetlibdirh->open($targetlibdir) or die $logfh->fatalq("Could not open library for reading: $targetlibdir");
  my @cells = grep /^\w+$/, $targetlibdirh->read;
  # For each cell in the latest tag, get file for DSSC query and capture information
  foreach my $cell (@cells) {
    $logfh->infod("Scanning Cell->(${cell})");
    my $targetfile;
    my $cellview = 'layout';
    $targetfile = "${targetlibdir}/${cell}/layout/layout.oa";
    print "($targetfile)\n";
    InitializeTableEntry($logfh, \@master_field_list, $library, $cell, $cellview, \%cell_table);
    $cell_table{$library}{$cell}{$cellview}{'LIBRARY'} = $library;
    $cell_table{$library}{$cell}{$cellview}{'CELL'} = $cell;
    $cell_table{$library}{$cell}{$cellview}{'CELLVIEW'} = $cellview;
    my $dsscquery = "${SYNC_DIR}/bin/dssc vhistory $targetfile";
    my $dsscqueryfh = new IO::File;
    $dsscqueryfh->open("$dsscquery |") or die $logfh->fatalq("Could not open DSSC query:", $dsscquery);
    my (@record, $version, $version_tags, $raw_date, $author, $year, $time, $mday, $month_name, $day_of_week_name);
    $version_tags = '';
    while (<$dsscqueryfh>) {
      chomp;
      if (/Version:\s+(\S+)\s*$/) {
	$version = "v${1}";
      }
      elsif (/Version tags:\s+(.+)\s*$/) {
	$version_tags = $1;
	$version_tags =~ s/\s*\,\s*/ /g;
      }
      elsif (/Date:\s+(.+)\s*$/) {
	$raw_date = $1;
	@record = split(/\s+/, $raw_date);
	$day_of_week_name = shift(@record);
	$month_name = shift(@record);
	$mday = shift(@record);
	$time = shift(@record);
	$year = pop(@record);
      }
      elsif (/Author:\s+(\S+)\s*$/) {
	$author = $1;
	my $month = ConvertMonthStringToInt($month_name) + 1;
	my $checkin_date = "${year}-${month}-${mday} $time";
	push(@csvdata, join(',',$library, $cell, $cellview, $version, $version_tags, $checkin_date, $author));
	$version_tags = '';
	$cell_table{$library}{$cell}{$cellview}{'VERSION'} = "v${version}";
	$cell_table{$library}{$cell}{$cellview}{'VERSION TAGS'} = $version_tags;
	$cell_table{$library}{$cell}{$cellview}{'CHECKIN DATE'} = $checkin_date;
	$cell_table{$library}{$cell}{$cellview}{'AUTHOR'} = $author;
      }
    }
  }
}


# Generate csv file
my $libcsv = "${HOME}/${exe_prefix}.status.csv";
my $libcsvfh = new IO::File;
$libcsvfh->open(">$libcsv") or die $logfh->fatalq("Could not open output csv file for writing: $libcsv");
$libcsvfh->printf("%s\n", join(',', @master_field_list));
foreach my $record(@csvdata) {
  $libcsvfh->printf("%s\n", join(',', $record));
}
#foreach my $library (sort keys %cell_table) {
#  foreach my $cell (sort keys %{ $cell_table{$library} }) {
#    foreach my $cellview (sort keys %{ $cell_table{$library}{$cell} }) {
#      my @record;
#      foreach my $field (@master_field_list) {
#	$logfh->infod("library->(${library}) cell->(${cell}) cellview->(${cellview}) field->(${field})");
#	push (@record, $cell_table{$library}{$cell}{$cellview}{$field});
#      }
#      $libcsvfh->printf("%s\n", join(',', @record)); 
#    }
#  }
#}
$libcsvfh->close;


# Close out run and add footer
$logfh->newline;
DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$logfh->info("Script completion date: $stop_date");
$logfh->info("$exe_name run complete");



##### Start subroutine definitions #####

sub InitializeTableEntry {

  my $loghandle = shift;
  my $field_list_ref = shift;
  my $library = shift;
  my $cell = shift;
  my $cellview = shift;
  my $cell_table_ref = shift;
  
  foreach my $field (@{ $field_list_ref }) {
    $$cell_table_ref{$library}{$cell}{$cellview}{$field} = '';
  }
}
