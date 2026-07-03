#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: fakeleaf.pl,v 1.1 2010/01/08 19:57:03 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: fakeleaf.pl,v 1.1 2010/01/08 19:57:03 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: fakeleaf.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: Creates fake log file for carmel_leaf ATF

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
usage:  $exe_name  [--help] [--verbose] [--debug]

flag descriptions:

--debug             Run flow in debug mode. Temporary files are not deleted and
                    additional data is placed in log file.

--verbose           Will add status messages to STDOUT.

--help              This usage message will appear.


example: $exe_name

Files that result from this run:

\$WORK/carmel/log/CheckLogOfPV_extRes.log

EOD


# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
                            "debug",
                            "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}


Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help;
my @required_flag_list = ();
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


# Variables to start log file
our ($basefile, $logfh);
$basefile = "${exe_prefix}";
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


# Generate the empty file needed for the carmel_leafs ATF

my $base_leaf_log = "CheckLogOfPV_extRes.log";
my $leaf_log = "${WORK}/carmel/log/${base_leaf_log}";

if (-e $leaf_log) {
  ManipFile($logfh, 'copy', "${WORK}/carmel/log", $base_leaf_log, "${base_leaf_log}.".time());
}
my $leaf_logfh = IO::File->new;
$leaf_logfh->open(">$leaf_log") or die $logfh->fatalq("Could not open output PV log file for leaf ATF");
my $date = `/bin/date`;
$leaf_logfh->print("$date\n\n");
$leaf_logfh->print("$leaf_log\n\n");
$leaf_logfh->print("Cell name              <cell>.carmel_ext.log             Result            SPF(%)\n");
$leaf_logfh->print("---------------------------------------------------------------------------------\n");
$leaf_logfh->close;

DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$logfh->info("Script completion date: $stop_date");
$logfh->info("$exe_name run complete");
