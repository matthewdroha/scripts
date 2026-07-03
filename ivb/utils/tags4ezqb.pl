#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: tags4ezqb.pl,v 1.1 2011/06/09 23:22:31 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: tags4ezqb.pl,v 1.1 2011/06/09 23:22:31 mroha Exp $

(C) Copyright Intel Corporation, 2010
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: tags4ezqb.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description:
Requires <fub>_lay_model and <fub>_ckt_model to be populated with the correct
_sch and _lay tags, respectively.
This script will print a .cfg list containing the library-tag pairs from the
<fub>_lay_model libraries, then overwrite the _lay libs with the tags in the
<fub>_ckt_model libraries.

=cut


BEGIN {
  use IO::Dir
  my %homedir;
  my $homeproject = "ivb";
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  # Patch for non-eclogin people
  $ENV{'EC_SITE'} = 'fm';
  if (defined $ENV{'EC_SITE'}) {
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new;
    $dir->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $dir->read();
    if (-d "$ENV{'HOME'}/override") {
      push @INC, "$ENV{'HOME'}/override";
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
use Getopt::Long;
use Time::Local;
use IO::File;
use Env;
use File::Path;
use File::Basename;
use Env;
use Cwd 'abs_path';
use DAStd;
use Logfile;
use UE;

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
usage:  $exe_name --fub <input fub>
                  [--env 'VAR=VALUE']
                  [--help] [--verbose] [--debug]

flag descriptions:

--fub               Fub name.  Script will verify that <fub>_lay_model and <fub>_ckt_model exists
                    in the current $DA_PROJECTS/$PROJECT area.

--env               Optional. Set env var at start of execution. Can provide more than
                    one --env flag.  Format is VAR=VALUE

--debug             Run flow in debug mode. Temporary files are not deleted and
                    additional data is placed in log file.

--verbose           Will add status messages to STDOUT.

--help              This usage message will appear.


example: $exe_name --fub fmmgend

Files that result from this run:

\$WORK/<fub>.${exe_prefix}.log
\$WORK/<fub>.cfg.YYYY_MM_DD

EOD


# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $exe_name: No command line parameters. Use --help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_fub);
our (@opt_env, $opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
                            "fub=s",
                            "sn=s",
                            "env=s@",
                            "debug",
                            "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help;
my @required_flag_list = ('--fub');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Begin Main Program #####


# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');
foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
my $fub_lc = lc($opt_fub);
our ($basefile, $logfh);
$basefile = "${fub_lc}.${exe_prefix}";
$logfh = Logfile->new("${WORK}/${basefile}.log");
$logfh->flowname($exe_name);
$logfh->verbose($opt_verbose);
$logfh->debug($opt_debug);
my $machine_info = `uname -a`;
chomp $machine_info;
$logfh->info("Script command: $exe_name $command_line");
$logfh->info("Script start date: $start_date");
$logfh->info("System info: $machine_info");


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
      $logfh->infoq("--env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $logfh->fatalq("Invalid value for switch --env: $setting");
    }
  }
}


# Intialize stage number for log file
my $stage = 0;


#  Check that fub_lay_model and fub_ckt_model exist in current module
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Verify that fub_lay_model and fub_ckt_model exist in current module");

my $fub_lay_model = "${DA_PROJECTS}/${PROJECT}/${PROJECT}.${fub_lc}_lay_model.cfg";
my $fub_ckt_model = "${DA_PROJECTS}/${PROJECT}/${PROJECT}.${fub_lc}_ckt_model.cfg";
unless (-f $fub_lay_model) {
    die $logfh->fatalq("${fub_lc}_lay_model does not exist in module->(${PROJECT})");
}
unless (-f $fub_ckt_model) {
    die $logfh->fatalq("${fub_lc}_ckt_model does not exist in module->(${PROJECT})");
}
$logfh->info("fub_lay_model and fub_ckt_model exist in $PROJECT");


# Generate CDSLIB file for fub_lay_model and fub_ckt_model
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Generate new CDSLIB files for each fub model file");
my $laydmspath = "${WORK}/${basefile}.lay_model.dms.pth";
my $cktdmspath = "${WORK}/${basefile}.ckt_model.dms.pth";
my $laycdslib = "${WORK}/${basefile}.lay_model.cds.lib";
my $cktcdslib = "${WORK}/${basefile}.ckt_model.cds.lib";
push (@tmplist, $laydmspath, $cktdmspath, $laycdslib, $cktcdslib, "${laydmspath}.modes", "${cktdmspath}.modes"); 
RecompileDmspath($logfh, $fub_lc, "${fub_lc}_lay_model", '', $laydmspath, $laycdslib);
RecompileDmspath($logfh, $fub_lc, "${fub_lc}_ckt_model", '', $cktdmspath, $cktcdslib);


# Parse the fub_lay_model cdslib output for all libraries
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Parse CDSLIB files");
my %tag_hash;
my $laycdslibfh = IO::File->new;
$laycdslibfh->open($laycdslib) or die $logfh->fatalq("Could not open fub_lay_model cdslib for reading: $laycdslib");
while (<$laycdslibfh>) {
  if (/^\s*DEFINE\s+(\S+)\s+(\S+)/) {
    my $lib = $1;
    my $libpath = $2;
    my @libpathdirs = split ('/', $libpath);
    pop @libpathdirs;
    my $tag = pop @libpathdirs;
    $tag =~ s/work/LATEST/;
    unless ($lib =~ /_(ctl|net)$/) {
      $tag_hash{$lib} = $tag;
    }
  }
}
$laycdslibfh->close;
my $libcount = keys %tag_hash;
$logfh->info("$libcount library-tag pairs captured from ${fub_lc}_lay_model");


# Parse the fub_ckt_model cdslib for only _lay libraries and replace the _lay_model tags for those libs
my $cktcdslibfh = IO::File->new;
$cktcdslibfh->open($cktcdslib) or die $logfh->fatalq("Could not open fub_ckt_model cdslib for reading: $cktcdslib");
my $laytagcount = 0;
while (<$cktcdslibfh>) {
  if (/^\s*DEFINE\s+(\S+)\s+(\S+)/) {
    my $lib = $1;
    my $libpath = $2;
    my @libpathdirs = split ('/', $libpath);
    pop @libpathdirs;
    my $tag = pop @libpathdirs;
    $tag =~ s/work/LATEST/;
    if ($lib =~ /_lay$/) {
      $tag_hash{$lib} = $tag;
      $laytagcount++;
    }
  }
}
$cktcdslibfh->close;
$logfh->info("$laytagcount _lay tags captured in ${fub_lc}_ckt_model");


# Open cfg file
$stage++;
$logfh->newline;
$logfh->info("***** Stage $stage: Write output .cfg file");
my @timelist = localtime($start_time);
my $year = $timelist[5] + 1900;
my $month = $timelist[4] + 1;
if (length($month) == 1) {
  $month = "0$month";
} 
my $day = $timelist[3];
my $cfgout = "${WORK}/${fub_lc}.cfg.${year}_${month}_${day}";
my $cfgoutfh = IO::File->new;
$cfgoutfh->open(">$cfgout") or die $logfh->fatalq("Could not open output cfg file for reading: $cfgout");
foreach my $lib (sort keys %tag_hash) {
  $cfgoutfh->printf("%-30s %s\n", $lib, $tag_hash{$lib});
}
$cfgoutfh->close;


DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$logfh->info("Script completion date: $stop_date");
$logfh->info("$exe_name run complete for cell: $fub_lc");
