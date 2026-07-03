#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: mapiif.pl,v 1.1 2010/01/08 19:57:25 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: mapiif.pl,v 1.1 2010/01/08 19:57:25 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: mapiif.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: 

This script yg0->ai0 mapping of iif and isp files

=cut

BEGIN {
  use IO::Dir;
  my $homeproject = 'ivb';
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

my $code_dir = GetCodeDir('ivb');
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
usage:  $exe_name --cell <cell name> [--help] [--verbose] [--debug]

flag descriptions:

--cell             Top level cell name

--debug            Run flow in debug mode. Temporary files are not deleted and
                   additional data is placed in log file.

--verbose          Will add status messages to STDOUT.

--help             This usage message will appear. 


example: $exe_name

Files that result from this run:

${exe_name}.<cell>.log
Mapped .iif/.isp files

EOD

# Get command line options. GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our (@opt_env);
our ($opt_debug, $opt_verbose, $opt_help);
our ($opt_cell);
my $options_ok = GetOptions("help",
			    "cell=s",
			    "debug",
			    "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use -help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 
my @required_flag_list = ("--cell");
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

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

# Open log file and add header
our ($basefile, $logfh);
$basefile = "${exe_prefix}";
$logfh = Logfile->new("${basefile}.log");
$logfh->flowname($exe_name);
$logfh->verbose($opt_verbose);
$logfh->debug($opt_debug);
my $machine_info = `uname -a`;
chomp $machine_info;
$logfh->info("Script command: $exe_name $command_line");
$logfh->info("Script start date: $start_date");
$logfh->info("Machine Type: $machine_info");

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


### Start Main Flow ###

# Check for iif/isp existance
my $stage = 1;
$logfh->info("***** Stage $stage: Check for top level iif/isp  *****");
my $cell = $opt_cell;
my $netcvs_dir = "${WORK}/netlists/netcvs";
unless (-f "${netcvs_dir}/${cell}.iif") {
  die $logfh->fatalq("Could not file top level iif file in netlists/netcvs: ${netcvs_dir}/${cell}.iif");
}
unless (-f "${netcvs_dir}/${cell}.isp") {
  die $logfh->fatalq("Could not file top level isp file in netlists/netcvs: ${netcvs_dir}/${cell}.isp");
}


# Read yg->ai name mapping file (whitespace delimited, no field headers)
$stage++;
$logfh->info("***** Stage $stage: Read yg->ai map file  *****");
my %ai_map;
my $home_area = $HOME;
my %map_table;
my $aimap = "${code_dir}/ctl/ivb_yg_ai.map";
my $aimapfh = IO::File->new;
$aimapfh->open($aimap) or die $logfh->fatalq("Could not open file for reading: $aimap");
while (<$aimapfh>) {
  if (/^(\S+)\s+(\S+)/) {
    my $ygcell = $1;
    my $aicell = $2;
    if (exists $map_table{$ygcell}) {
      die $logfh->fatalq("Found duplicate yg cell in map file->($ygcell)");
    } else {
      $map_table{$ygcell} = $aicell;
      unless (exists $ai_map{$aicell}) {
        @{ $ai_map{$aicell} } = ();
      }
      push @{ $ai_map{$aicell} }, $ygcell;
    }
  }
}
$aimapfh->close;


$stage++;
$logfh->info("***** Stage $stage: Apply mapping to iif/isp files *****");
# Create output area
my $mapped_dir = "${netcvs_dir}/${exe_prefix}_mapped";
unless (-d $mapped_dir) {
  CreateDirTrees($mapped_dir);
}
unless (-d $mapped_dir) {
  die $logfh->fatalq("Could not create snapshot directory for original iif/isp files: $mapped_dir");
}
# Get list of iif/isp files
my $netcvs_dirfh = new IO::Dir;
$netcvs_dirfh->open($netcvs_dir) or die $logfh->fatalq("Could not open directory for reading: $netcvs_dir");
my @ispiif_files = grep /\S+\.(isp|iif)$/, $netcvs_dirfh->read;
# For each isp file
foreach my $file (@ispiif_files) {
  # Generate new file
  my $origfh = new IO::File;
  $origfh->open("${netcvs_dir}/${file}") or die $logfh->fatalq("Could not open source file for reading: ${netcvs_dir}/${file}");
  my $outfile = "${mapped_dir}/${file}";
  my $outfilefh = new IO::File;
  $outfilefh->open(">${outfile}") or die $logfh->fatalq("Could not open source file for writing: ${outfile}");
  while (<$origfh>) {
    if ((/\.MACRO\s+(\S+)/) or (/\.INCLUDE\s+(\S+)/) or (/\@\S+\s+(\S+)/)) {
      my $ygcell = $1;
      if (exists ($map_table{$ygcell})) {
	s/$ygcell/$map_table{$ygcell}/;
      }
    }
    $outfilefh->print($_);
  }
  $origfh->close;
  $outfilefh->close;
}

$logfh->newline;
DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$logfh->info("Script completion date: $stop_date");
$logfh->info("$exe_name run complete");


##### Start subroutine definitions #####

