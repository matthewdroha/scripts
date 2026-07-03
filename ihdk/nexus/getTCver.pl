#!/usr/intel/pkgs/perl/5.20.1-threads/bin/perl
# $Id: getTCver.pl,v 1.3 2016/06/16 04:38:02 mroha Exp $

=pod

=head1 COPYRIGHT

$Id: getTCver.pl,v 1.3 2016/06/16 04:38:02 mroha Exp $

 (C) Copyright Intel Corporation, 2016
 Licensed material -- Program property of Intel Corporation
 All Rights Reserved

 This program is the property of Intel Corporation and is furnished
 pursuant to a written license agreement. It may not be used, reproduced,
 or disclosed to others except in accordance with the terms and conditions
 of that agreement.

 Filename: getTCver.pl
 Project: ihdk
 Original Author: Matthew Roha

=cut


=head1 DESCRIPTION

B<getTCver.pl> prints out collateral versions for a given UE session. Input is a tool configuration or list of configurations. Output is a .csv file. Script works over dot process names and is useful when there is a need to collect information on large number of configs.

=cut


BEGIN {
  use IO::Dir
  my %homedir;
  my %cpandir;
  my $homeproject = "ihdk";
  my $perlver = "5.14.1";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  $cpandir{'fm'} = "$homedir{'fm'}/CPAN/${perlver}";
  # Patch for non-eclogin people
  if (defined $ENV{'EC_SITE'}) {
    if (-d "$homedir{$ENV{'EC_SITE'}}/override") {
      push @INC, "$ENV{'HOME'}/override";
    }
    if (-d "$cpandir{$ENV{'EC_SITE'}}/Excel-Writer-XLSX-0.88/lib") {
      push @INC, "$cpandir{$ENV{'EC_SITE'}}/Excel-Writer-XLSX-0.88/lib";
    }
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $code_dir_h = IO::Dir->new;
    $code_dir_h->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $code_dir_h->read();
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


use v5.20.1;
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;
use Time::Local;
use IO::File;
use IO::Dir;
use IO::Pipe;
use Proc::Fork;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Path;
use File::Basename;
use File::Temp;
use File::Find;
use Env;
use Cwd qw(abs_path);
use Cwd;
use DAStd;
use Logfile;

use constant {
  false => 0,
  true => 1
};

my $code_dir = GetCodeDir('ihdk');
my $exe_name;
my $exe_prefix;
($exe_name, $exe_prefix) = GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = GetDate();

# Get the site
our $site = GetSite();

# Prepare the usage string.

=head1 SYNOPSIS

=over 20

=item getTCver.pl

 --config <Setproj configuration name>
 --n <UE -n switch>
 [--skipheader] [--skipreportorder] [--skipcadscan]
 [--run-name <logfile prefix>]
 [--env 'VAR=VALUE']
 [--help] [--verbose] [--debug]

=back

flag descriptions:

=over 15

=item B<--config>

MIG tool collateral configuration name (example: mig74p0cnl1b0polo)

=item B<--ov>

Determines where toolsetup will run. Default is $cwd/getTCVer

=item B<--skipheader>

Do not print csv first row labels. Handy if concatenating files.

=item B<--skipreportorder>

Skip adding first field which contains original report order.  Makes it easier to filter duplicates in Excel.

=item B<--skipcadscan>

Skip scan of cad tree files

=item B<--run-name>

Optional.  String label prefix for output files only.

=item B<--env>

Optional. Set env var at start of execution. Can provide more than one --env flag.  Format is 'VAR=VALUE' for each --env flag.

=item B<--debug>

Run flow in debug mode. Temporary files are not deleted and additional data is placed in log file.

=item B<--verbose>

Will add status messages to STDOUT.

=item B<--help>

This usage message will appear.

=item B<example:>

$exe_name --config mig74p0latest

=item B<Files that result from this run:>

=back

<CONFIG>.getTCver.log
<CONFIG>.getTCver.csv

=cut




# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $exe_name: No command line parameters. Use --help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_config, $opt_skipheader, $opt_skipreportorder, $opt_skipcadscan, $opt_ov, $opt_run_name);
our (@opt_env, $opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
                            "config=s",
			    "ov=s" => \$opt_ov,
			    "skipheader",
			    "skipreportorder",
			    "skipcadscan",
                            "run-name=s" => \$opt_run_name,
                            "env=s@",
                            "debug",
                            "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  pod2usage("-F- $exe_name: One or more command line parameters incorrect. Use --help switch.");
}

if ($opt_help) {
  pod2usage( { -message => '-I- $exe_name: Help flag specified. Printing usage information.',
               -exitval => 1,
               -verbose => 99,
	       -sections => qw(SYNOPSIS)} );
}

my @required_flag_list = ('--config');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');
foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your shell session:", "\$$env_var is not defined.\n";
  }
}

# Set run area
my $uework;
my $dash_n = 'none';
my $cwd = cwd();
if (defined $opt_ov) {
  $uework = $opt_ov;
} else {
  $uework = "${cwd}/${exe_prefix}";
}
unless ($uework =~ /\w+/) {
  die "Something wrong, target UE directory needs to have word characters->(${uework})";
}


# Variables to start log file
our ($basefile, $log);

if ($opt_run_name) {
  $basefile = "${opt_run_name}.${opt_config}.${exe_prefix}";
} else {
  $basefile = "${opt_config}.${exe_prefix}";
}
$log = Logfile->new("${basefile}.log");
$log->flowname($exe_name);
$log->verbose($opt_verbose);
$log->debug($opt_debug);
$log->info("Script command: $exe_name $command_line");
$log->info("Script start date: $start_date");
my $machine_info = `uname --all`;
chomp $machine_info;
$log->info("System info: $machine_info");
if (-f '/etc/SuSE-release') {
  my $suse_version = `cat /etc/SuSE-release`;
  my @record = split("\n", $suse_version);
  foreach my $line (@record) {
    $log->info("System info: $line");
  }
  $log->info("");
}


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

# Begin Main Program

=head1 PROGRAM FLOW

=head2 Inputs

=head2 Flow

- Stage 1: Run setproj and check if config is valid.
- Stage 2: Run mig ihdk setup to build session tool/collateral list
- Stage 3: Parse tool/collateral list history with release comments. Make note of current config.
- Stage 4: For each tool version, get date installed in HDK CAD tree
- Stage 5: Build .csv file.

=cut


=head1 CSV FIELDS

REPORT_ORDER              -> Original record order in case engineer wants to restore original order after Excel filtering
SCRIPT_START_DATE         -> Date and time script execution started
SCRIPT_FINISH_DATE        -> Date and time script execution finished
YYYYWW                    -> Intel workweek when event occurred
YYYYWW_REPEAT             -> Same as YYYYWW, but put on last column to guarentee last column fully populated (useful in Excel)
DATETIME                  -> YYYY/MM/DD HH:MM:SS format for event
EVENT_COUNT_FOR_WW        -> Total number of events (rows) recorded in given workweek. 0 is a placeholder
EVENT_TYPE                -> The nature of the event (see below for possible values)
EVENT_DATE                -> Date and time of event
TOOL_COLLATERAL)TYPE      -> The type of tool or collateral (see below for possible values)
PROCESS                   -> Process technology
CONFIGURATION             -> MIG tool collateral configuration name
TOOL COLLATERAL           -> Tool or collateral name
VERSION                   -> Tool or collateral version name
DATATYPE                  -> Data type extracted for given event (see below for possible values)
DATAVALUE                 -> Value for given data type
FRESHNESS                 -> Relative age between the rows for a given EVENT and DATATYPE
COMMENT                   -> Comment field with additional detail for given DATATYPE

=cut


use constant {
  CSV_REPORT_ORDER => 'REPORT ORDER',
  CSV_SCRIPT_START_DATE => 'SCRIPT START DATE',
  CSV_SCRIPT_FINISH_DATE => 'SCRIPT FINISH DATE',
  CSV_YYYYWW => 'YYYYWW',
  CSV_YYYYWW_REPEAT => 'YYYYWW COPY',
  CSV_DATETIME => 'YYYYMMYY',
  CSV_EVENT_COUNT_FOR_WW => 'EVENT COUNT FOR WW',
  CSV_EVENT_TYPE => 'EVENT TYPE',
  CSV_EVENT_DATE => 'EVENT DATE',
  CSV_TOOL_COLLATERAL_TYPE => 'TOOL COLLATERAL TYPE',
  CSV_PROCESS => 'PROCESS',
  CSV_CONFIGURATION => 'CONFIGURATION',
  CSV_TOOL_COLLATERAL => 'TOOL COLLATERAL NAME',
  CSV_VERSION => 'VERSION',
  CSV_DATATYPE => 'DATATYPE',
  CSV_DATAVALUE => 'DATAVALUE',
  CSV_FRESHNESS => 'FRESHNESS',
  CSV_COMMENT => 'COMMENT'
};


=head1 EVENT TYPE CONSTANTS

EVENT_CONFIG_VERSION_CHANGE                        -> Tool collateral version released to configuration
EVENT_CAD_VERSION_DIR_DATE                         -> Unix datetime for tool collateral version directory in CAD tree
EVENT_CAD_FILES_TOUCHED_BEFORE_CONFIG_RELEASE_DATE -> Files in CAD tree touched before the version was released to target configuration
EVENT_CAD_FILES_TOUCHED_AFTER_CONFIG_RELEASE_DATE  -> Files in CAD tree touched after the version was released to target configuration
EVENT_CAD_FILES_TOUCHED_VERSION_NOT_USED_BY_CONFIG -> Files in CAD tree touched but version is not ever used by configuration
EVENT_NO_EVENT_IN_WW                               -> PLACEHOLDER FOR WORKWEEKS WITH NO EVENTS TO MAINTAIN PIVOT CONTINUITY.
EVENT_WW_FILL                                      -> PLACEHOLDER FOR EVERY WORKWEEK TO MAINTAIN PIVOT CONTINUITY.

=cut


use constant {
  EVENT_CONFIG_VERSION_CHANGE => 'CONFIG VERSION CHANGE',
  EVENT_CAD_VERSION_DIR_DATE => 'HDK CAD VERSION DIR DATE',
  EVENT_CAD_FILES_TOUCHED_BEFORE_CONFIG_RELEASE_DATE => 'HDK CAD FILE TOUCHED BEFORE CONFIG RELEASE (USED BY CONFIG)',
  EVENT_CAD_FILES_TOUCHED_AFTER_CONFIG_RELEASE_DATE => 'HDK CAD FILE TOUCHED AFTER CONFIG RELEASE (USED BY CONFIG)',
  EVENT_CAD_FILES_TOUCHED_VERSION_NOT_USED_BY_CONFIG => 'HDK CAD FILE TOUCHED (NOT USED BY CONFIG - 90 DAY WINDOW)',
  EVENT_CAD_VERSION_TOUCHED => 'HDK CAD VERSION CONTENTS TOUCHED',
  EVENT_NO_EVENT_IN_WW => 'NO EVENT IN WW FOR CONFIG',
  EVENT_WW_FILL => 'WW FILL'
};


=head1 TOOL COLLATERAL TYPE CONSTANTS

TOOL                      -> CAD TOOL
COLLATERAL                -> TECHNOLOGY COLLATERAL

=cut

use constant {
  TC_TYPE_TOOL => 'TOOL',
  TC_TYPE_COLLATERAL => 'COLLATERAL',
};


=head1 DATA TYPE CONSTANTS

DATA_TYPE_CHANGE_NUMBER                  -> INDEX WHICH SHOWS THE NUMBER OF TIMES A REVISION CHANGED FOR A CONFIG_VERSION_CHANGE TRANSATION TYPE
DATA_TYPE_VERSION_UPDATE_OCCURED         -> SET TO "1" TO MARK TOOL VERSION CHANGE OCCURRED FOR THE GIVEN DATE
DATA_TYPE_NUM_FILES_TOUCHED_ON_THIS_DATE -> THE NUMBER OF FILES TOUCHED FOR A GIVEN TC VERSION ON GIVEN DATE FOR A EVENT_CAD_VERSION_TOUCHED EVENT TYPE.  FOR ANY GIVEN TC VERSION, THE SOME OF THESE ENTRIES EQUALS THE TOTAL NUMBER OF FILES FOR THAT VERSION AT THE TIME WHERE THE SCRIPT WAS RUN.

=cut

use constant {
  DATA_TYPE_CHANGE_NUMBER => 'CHANGE NUMBER',
  DATA_TYPE_VERSION_UPDATE_OCCURRED => 'UPDATE OCCURRED',
  DATA_TYPE_NUM_FILES_TOUCHED_ON_THIS_DATE => 'NUM FILES TOUCHED ON DATE',
};


# Other constants
use constant {
  EMPTY_WW => 'EMPTY WW',
  KEEP_VERSION => 'KEEP VERSION'
};


# Stage 1: Quick rejection: run setproj and tool setup
$stage++;
$log->newline;
$log->info("***** Stage $stage : Run setproj and tool setup *****\n");

my $base_process;
my $dot_process;
if ($opt_config =~ /^\w+(\d{2})p(\d)\w+$/) {
  $base_process = "12${1}";
  $dot_process = "p${base_process}.${2}";
} else {
  die $log->warnp("Input configuration name ->($opt_config) had unfamliar naming format.  process being set to unknown");
}

$log->infod("$base_process $dot_process\n");

my @toolcollaterallist = (
"PROCESS_VER",
"issrunsets${base_process}",
"extractRC_util",
"stdcells/e8lib",
"stdcells/e8libana",
"stdcells/e8libidv",
"stdcells/e8libtic",
# "stdcells/e8libtsv",   # library cancelled for 10nm
"stdcells/e9prim",
"stdcells/ec0",
"stdcells/ec0hs",
"stdcells/ec0migalpha",
"stdcells/ec0glbclk",
# "stdcells/ec0alpha",   # no longer reported by TM0
"stdcells/e05",
"stdcells/ip10xadtshr",
"layshrall",
# "process/${dot_process}_collateral",  # retired
"process/${dot_process}_sim",
"stdcells/cnldfm",
"stdcells/cnlfcl",
"techfiles",
);

our %toolcollateralindex = map { $toolcollaterallist[$_] => $_ } reverse 0 .. $#toolcollaterallist;
$toolcollateralindex{+EMPTY_WW} = $#toolcollaterallist + 1;
foreach my $toolcollateral (keys %toolcollateralindex) {
  $log->infod("Tool Collateral Sort Order: TC->($toolcollateral) ORDER->($toolcollateralindex{$toolcollateral})");
}

my %toolcollateralhash;
foreach my $toolcollateral (@toolcollaterallist) {
  $toolcollateralhash{$toolcollateral}{'TARGET'} = $toolcollateral;
}
my %toolcollateralversionused;
my %timewheel;

# create on the fly shell script script to extract ue information
my $gettv_script = "${cwd}/${basefile}.csh";
my $gettv_script_h = IO::File->new;
$gettv_script_h->open(">$gettv_script") or die $log->fatalq("could not open gettv script for write: $gettv_script");
$gettv_script_h->print("\#!/usr/intel/bin/tcsh\n");
foreach my $toolcollateral (@toolcollaterallist) {
  $gettv_script_h->print("printf \"tool=${toolcollateral} \" ; getTv -v ${toolcollateral}\n");
}
our ($DA_PROJECTS, $TOOL_CFG, $SETUP_HOSTYPE, $SETUP_SESSION_TOOLS);
my @envvars = ('DA_PROJECTS', 'TOOL_CFG', 'SETUP_HOSTYPE', 'SETUP_SESSION_TOOLS');
my $envvars_regex = join('|', @envvars);
foreach my $envvar (@envvars) {
  $gettv_script_h->print("printf \"${envvar}=\$${envvar}\\n\"\n");
}
my $END_TOKEN = 'END_UE_CALL';
$gettv_script_h->print("printf \"${END_TOKEN}\\n\"\n");
$gettv_script_h->close;
chmod 0755, $gettv_script;

autoflush STDOUT 1;
autoflush STDERR 1;
my $setproj_pipe = IO::Pipe->new();
my $wash = q(-wash 'coe73lay coeenv hdk10nm hdk10nmproc hdk22nmproc soc');
my $ue_cmd = "/p/hdk/bin/setproj $wash -p ihdk -cfg $opt_config -cmd \'setup -t hip -b all -ov $uework -n $dash_n -cmd ${gettv_script}\'";


run_fork {
  child {
    $setproj_pipe->writer();
    open STDOUT, '>&', $setproj_pipe or die "Can't redirect STDOUT: $!";
    open STDERR, '>&STDOUT'  or die "Can't redirect STDOUT: $!";
    $log->info("Executing UE command->(${ue_cmd})");
    exec($ue_cmd) or print STDERR "Couldn't exec ue command: $!";
  }
  parent {
    my $child_pid = shift;
    $setproj_pipe->reader();
    waitpid $child_pid, 0;
    my $toolcollateral;
    my $version;
    my $version_change_count;
    while (<$setproj_pipe>) {
      chomp;
      $log->infod($_);
      if (/\-E\- toolsetup\.pl/) {
	chomp;
	die $log->fatalq("Error thrown by setproj/toolsetup: $_");
      }
      elsif (/^tool=(\S+)\s+/) {
	$toolcollateral = $1;
	if (/NoToolVer/) {
	  $version = 'NoToolVer';
	  $version_change_count = 0;
	  $log->infod("NoToolVer found: $toolcollateral");
	}
	elsif (/TOOL_CFG LIST FILE\((\d+)\)/) {
	  $version_change_count = $1;
	  my @record = split;
	  $version = $record[4];
	  $log->infod("Version found: $toolcollateral $version $version_change_count");
	} else {
	  die $log->fatalq("Found unrecognized row from gettv_process: $_");
	}
	$toolcollateralhash{$toolcollateral}{'GETTV_NAME'} = $toolcollateral;
	$toolcollateralhash{$toolcollateral}{'GETTV_VERSION'} = $version;
	$toolcollateralhash{$toolcollateral}{'GETTV_CHANGE_COUNT'} = $version_change_count;
      }
      elsif (/(${envvars_regex})=(\S+)$/) {
	my $varname = $1;
	my $varvalue = $2;
	my $eval_string = "\$${varname} = \"$varvalue\"";
	eval $eval_string;
	$log->infod("Eval string ran->($eval_string)");
      }
      elsif (/$END_TOKEN/) {
	foreach my $envvar (@envvars) {
	  my $varvalue = eval "\$${envvar}";
	  die $log->fatalq("Environment variable value not captured for \$${envvar}") unless $varvalue;
	  $log->infod("\$${envvar} = $varvalue\n");
	}
        # stage 2: parse setup session tools
	$stage++;
	$log->newline;
	$log->info("***** Stage $stage : Parse setup session tools file and extract config version history *****\n");
	my $current_tool_cfg = "${DA_PROJECTS}/ihdk/config/ihdk.${TOOL_CFG}.tools.${SETUP_HOSTYPE}";
	# Order important here
	my @tool_version_files = ($SETUP_SESSION_TOOLS, $current_tool_cfg);
	foreach my $tool_version_file (@tool_version_files) {
	  my $tool_version_file_h = IO::File->new;
	  $log->infoq("Parsing setup session tools file->($tool_version_file)");
	  $tool_version_file_h->open($tool_version_file) or die $log->fatalq("Could not open tool version file for reading->($tool_version_file)");
	  while(<$tool_version_file_h>) {
	    chomp;
	    $log->infod("TOOL VERSION FILE LINE: $_");
	    if (/^\s*(\S+)\s+(\S+)\s+\#\s+(\w+)\s+(\d{4})\/(\d{2})\/(\d{2})\s+(\d{2})\:(\d{2})\:(\d{2})/) {
	      $log->infod("FOUND TOOL LINE");
	      my $toolcollateral = $1;
	      my $version = $2;
	      my $user = $3;
	      my $year = $4;
	      my $month = $5;
	      my $day = $6;
	      my $hour = $7;
	      my $minute = $8;
	      my $second = $9;
	      my @workweek_output;
	      my $yyyyww;
	      my $datetime = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $minute, $second);
	      my $workweek_cmd = "/usr/intel/bin/workweek ${month}/${day}/${year}";
	      unless (Pipe($log, $workweek_cmd, '', \@workweek_output)) {
		foreach my $line (@workweek_output) {
		  $log->infoq($line);
		}
		die $log->fatalq("Error while executing command: $workweek_cmd");
	      }
	      foreach my $workweek_result (@workweek_output) {
		$log->infod("WORKWEEK RETURN: $workweek_result","");
		if ($workweek_result =~ /\s+WW(\w{2})\s+/) {
		  $yyyyww = "${year}${1}";
		} else {
		  die $log->fatalq("Workweek call return did not have WW match\n");
		}
	      }
	      if (exists $toolcollateralhash{$toolcollateral}) {
		my $rev;
		$log->infod("Found target tool: $toolcollateral $version $user $year $month $day $hour $minute $second");
		if (exists $toolcollateralhash{$toolcollateral}{'ACTIVE_REVISION'}) {
		  my $lastrev = $toolcollateralhash{$toolcollateral}{'ACTIVE_REVISION'};
		  $toolcollateralhash{$toolcollateral}{'ACTIVE_REVISION'}++;
		  $rev = $toolcollateralhash{$toolcollateral}{'ACTIVE_REVISION'};
		  if ($lastrev == 1) {
		    $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$lastrev}{+CSV_FRESHNESS} = 'EARLIEST';
		  } else {
		    $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$lastrev}{+CSV_FRESHNESS} = 'NOT EARLIEST OR LATEST';
		  }
		} else {
		  $rev = $toolcollateralhash{$toolcollateral}{'ACTIVE_REVISION'} = 1;
		}
		$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_VERSION} = $version;
		$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_FRESHNESS} = 'LATEST';
		$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{'USER'} = $user;
		$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_DATETIME} = $datetime;
		$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_YYYYWW} = $yyyyww;
		$toolcollateralversionused{$toolcollateral}{$version} = $datetime;
	      }
	    }
	  }
	}
      }
    }
  }
};

# stage 3 parse setup session tools
$stage++;
$log->newline;
$log->info("***** Stage $stage : Build time wheel view of config version history *****\n");

# original order, process, config, tool, version, latest?, config update date, config update
foreach my $toolcollateral (@toolcollaterallist) {
  if (exists $toolcollateralhash{$toolcollateral}{'REVISIONS'}) {
    foreach my $rev (sort numerically keys %{ $toolcollateralhash{$toolcollateral}{'REVISIONS'} }) {
      my $revision_freshness = $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_FRESHNESS};
      my $version = $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_VERSION};
      my $yyyyww = $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_YYYYWW};
      my $datetime = $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_DATETIME};
      my $user = $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{'USER'};
      $log->infod("TC->($toolcollateral) REV->($rev) FRESHNESS->($revision_freshness) VER->($version) WW->($yyyyww) DATETIME->($datetime)");
      my $entry = join(',', $dot_process,$opt_config, EVENT_CONFIG_VERSION_CHANGE, $datetime, TC_TYPE_COLLATERAL, $toolcollateral, $version, DATA_TYPE_CHANGE_NUMBER, $rev, $revision_freshness, $user);
      push(@{ $timewheel{$toolcollateral}{$yyyyww}{$datetime} }, $entry);
      $entry = join(',', $dot_process,$opt_config, EVENT_CONFIG_VERSION_CHANGE, $datetime, TC_TYPE_COLLATERAL, $toolcollateral, $version, DATA_TYPE_VERSION_UPDATE_OCCURRED, "1", "NA", $user);
      push(@{ $timewheel{$toolcollateral}{$yyyyww}{$datetime} }, $entry);
    }
  }
}

my @stdcellfamilies = (
  "stdcells/e8lib",
  "stdcells/e8libana",
  "stdcells/e8libidv",
  "stdcells/e8libtic",
#  "stdcells/e8libtsv",
  "stdcells/e9prim",
  "stdcells/ec0",
  "stdcells/ec0hs",
  "stdcells/ec0migalpha",
#  "stdcells/ec0alpha",
  "stdcells/ec0glbclk",
  "stdcells/e05",
  "stdcells/ip10xadtshr",
  "stdcells/cnldfm",
  "stdcells/cnlfcl"
);


my %caddir;
my $issrunsetsprocess = $dot_process;
$issrunsetsprocess =~ s/p//;

$caddir{'HDK'} = {
    "PROCESS_VER" => '',
    "issrunsets${base_process}" => "/p/hdk/cad",
    "extractRC_util" => "/p/hdk/pu_tu/prd",
#    "process/${dot_process}_collateral" => "/p/hdk/cad",    # retired
    "process/${dot_process}_sim" => "/p/hdk/cad",
    "layshrall" => "/p/hdk/pu_tu/prd",
    "techfiles" => "/p/hdk/cad",
};


foreach my $stdcellfamily (@stdcellfamilies) {
  $caddir{'HDK'}{$stdcellfamily} = '/p/hdk/cad';
}

our %touchtally;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);


# Stage 4 Index MIG and HDK CAD trees
$stage++;
$log->newline;
$log->info("***** Stage $stage : Index HDK CAD tree *****\n");

my $ninety_days_ago = $start_time - (90*24*60*60);
$log->infoq("Ninety Days Ago Seconds: $ninety_days_ago");
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ninety_days_ago);
$mon += 1;
$year += 1900;
$log->infoq("Ninety Days Ago Date: $year $mon $mday $hour $min $sec");

# Set find options for cad tree indexing
my %find_options = (
		    "follow" => 1,
		    "follow_skip" => 2,
		    "wanted" => \&wanted,
		    "dangling_symlinks" => 0,
		    # "preprocess" => \&preprocess    Not activated if follow is set
		   );


# Index cad trees
my %cadtreeindex;
# For each tool collateral
foreach my $toolcollateral (@toolcollaterallist) {
  # For each cad tree
  foreach my $cadtree ('HDK') {
    $log->info("Indexing tool/collateral in $cadtree CAD tree: $toolcollateral");
    # Capture versions and date last modified.
    my $caddirstring = $caddir{$cadtree}{$toolcollateral};
    $log->infod("caddirstring->($caddirstring)");
    if ($caddirstring) {
      my @caddirs = split(/\:/, $caddirstring);
      foreach my $caddir (@caddirs) {
	my $tooldir = "${caddir}/${toolcollateral}";
	$log->infod("TARGET TOOLDIR->($tooldir)");
	my $tooldir_abspath = abs_path($tooldir);
	unless (-d $tooldir_abspath) {
	  $log->infod("Tool directory is not a directory->($tooldir_abspath)");
	  next;
	}
	$log->infod("Resolved tooldir->($tooldir_abspath)");
	my $tooldir_h = IO::Dir->new;
	$tooldir_h->open($tooldir) or die $log->fatalq("Could not open CAD directory for reading: $tooldir");
	my @versiondirs = $tooldir_h->read;
	foreach my $versiondir (@versiondirs) {
	  %touchtally = ();
	  if ($versiondir =~ /^\w/) {
	    my $toolversiondir = "${tooldir}/${versiondir}";
	    $log->newline(1);
	    $log->infod("TARGET TOOLVERSIONDIR->($toolversiondir)");
	    my $toolversiondir_abspath = abs_path($toolversiondir);
	    unless ($toolversiondir_abspath and (-d $toolversiondir_abspath)) {
	      $log->warnd("Tool version directory link is not a directory->($toolversiondir)");
	      next;
	    }
	    $log->infod("RESOLVED TOOLVERSIONDIR->($toolversiondir_abspath)");
	    # capture toolcollateral, cadtree, version -> directory, mtime for the valid simlink at the top of the tree
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat($toolversiondir);
	    $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{'DIRECTORY'} = $toolversiondir;
	    $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{'MTIME'} = $mtime;
	    $log->infod("TC->($toolcollateral) UNRESOLVED VERSION DIR->($toolversiondir) RESOLVED VERSION DIR->($toolversiondir_abspath) UNRESOLVED VERSION LINK MTIME->($mtime)");
	    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
	    my @workweek_output;
	    my $yyyyww;
	    $mon += 1;
	    $year += 1900;
	    my $datetime = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
	    my $workweek_cmd = "/usr/intel/bin/workweek ${mon}/${mday}/${year}";
	    unless (Pipe($log, $workweek_cmd, '', \@workweek_output)) {
	      foreach my $line (@workweek_output) {
		$log->infoq($line);
	      }
	      die $log->fatalq("Error while executing command: $workweek_cmd");
	    }
	    foreach my $workweek_result (@workweek_output) {
	      $log->infod("WORKWEEK RETURN: $workweek_result");
	      if ($workweek_result =~ /\s+WW(\w{2})\s+/) {
		$yyyyww = "${year}${1}";
	      } else {
		die $log->fatalq("Workweek call return did not have WW match\n");
	      }
	    }
	    $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+CSV_DATETIME} = $datetime;
	    $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+CSV_YYYYWW} = $yyyyww;
	    $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+KEEP_VERSION} = 0;
	    # Skip the next level directory if it was not used by the config and version directory mtime is earlier than 90 days ago
	    # Otherwise index the version
	    if ((not exists $toolcollateralversionused{$toolcollateral}{$versiondir}) and ($mtime <= $ninety_days_ago)) {
	      $log->infoq("Tool Collateral Version Not Used By Config and link tree greater than 90 days old.  Skipping. TC->($toolcollateral) VERSION->($versiondir)\n");
	      next;
	    }
	    unless (-r $toolversiondir_abspath) {
	      $log->warnd("Tool version directory is not readable->(${toolversiondir_abspath})\n");
	      next;
	    }
	    if (exists $toolcollateralversionused{$toolcollateral}{$versiondir}) {
	      $log->infoq("Tool Collateral Search Start (Used by config): TC->($toolcollateral) VERSION->($versiondir) PATH->($toolversiondir) RESOLVED PATH->($toolversiondir_abspath)");
	    }
	    elsif ($mtime > $ninety_days_ago) {
	      $log->infoq("Tool Collateral Search Start (Less than 90 days): TC->($toolcollateral) VERSION->($versiondir) PATH->($toolversiondir) RESOLVED PATH->($toolversiondir_abspath)");
	    } else {
	      die $log->fatalq("Tool Collateral Search Start (Version should of been skipped): TC->($toolcollateral) VERSION->($versiondir) PATH->($toolversiondir) RESOLVED PATH->($toolversiondir_abspath)");
	    }

	    $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+KEEP_VERSION} = 1;

	    next if $opt_skipcadscan;
	    
	    find(\%find_options, $toolversiondir_abspath);
	    
	    # Bound the earliest and latest tally dates
	    my ($earliest, $latest) = ('') x 2;
	    my $count = 0;
	    foreach my $datetime (keys %touchtally) {
	      if (($earliest eq '') or ($earliest gt $datetime)) {
		$earliest = $datetime;
	      }
	      if (($latest eq '') or ($latest lt $datetime)) {
		$latest = $datetime;
	      }
	      $count++
	    }
	    # For each tally date
	    foreach my $datetime (keys %touchtally) {
	      # Convert to workweek
	      my ($year, $mon, $mday) = split (/\-|\s/, $datetime);
	      $workweek_cmd = "/usr/intel/bin/workweek ${mon}/${mday}/${year}";
	      unless (Pipe($log, $workweek_cmd, '', \@workweek_output)) {
		foreach my $line (@workweek_output) {
		  $log->infoq($line);
		}
		die $log->fatalq("Error while executing command: $workweek_cmd");
	      }
	      foreach my $workweek_result (@workweek_output) {
		$log->infod("WORKWEEK RETURN: $workweek_result");
		if ($workweek_result =~ /\s+WW(\w{2})\s+/) {
		  $yyyyww = "${year}${1}";
		} else {
		  die $log->fatalq("Workweek call return did not have WW match\n");
		}
	      }
	      # Add EVENT_CAD_VERSION_TOUCHED record
	      my $revision_freshness = 'NOT EARLIEST OR LATEST';
	      if ($datetime eq $earliest) {
		$revision_freshness = 'EARLIEST';
	      }
	      if ($datetime eq $latest) {
		$revision_freshness = 'LATEST';
	      }
	      # Bin tool version into whether it was used or not
	      my $event;
	      if (exists $toolcollateralversionused{$toolcollateral}{$versiondir} ) {
		$event = EVENT_CAD_FILES_TOUCHED_AFTER_CONFIG_RELEASE_DATE;   #assume fail condition until proven otherwise
		if ($datetime lt $toolcollateralversionused{$toolcollateral}{$versiondir}) {
		  $event = EVENT_CAD_FILES_TOUCHED_BEFORE_CONFIG_RELEASE_DATE;
		}
	      } else {
		$event = EVENT_CAD_FILES_TOUCHED_VERSION_NOT_USED_BY_CONFIG;
	      }
	      my $entry = join(',', $dot_process, $opt_config, $event, $datetime, TC_TYPE_COLLATERAL, $toolcollateral, $versiondir, DATA_TYPE_NUM_FILES_TOUCHED_ON_THIS_DATE, $touchtally{$datetime}, $revision_freshness, $toolversiondir);
	      push(@{ $timewheel{$toolcollateral}{$yyyyww}{$datetime} }, $entry);
	    }
	  }
	}
      }
    }
  }
}


# Foreach version revision
# If match found with cad index for mig,hdk trees, then capture in main hash

# Original order, process, config, tool, version, latest?, config update date, config update
foreach my $toolcollateral (@toolcollaterallist) {
  if (exists $toolcollateralhash{$toolcollateral}{'REVISIONS'}) {
    foreach my $rev (sort numerically keys %{ $toolcollateralhash{$toolcollateral}{'REVISIONS'} }) {
      my $configtoolcollateralversion = $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{+CSV_VERSION};
      # for each cad tree
      foreach my $cadtree ('HDK') {
	# if config tool collateral version matches cad tree, then reference the cad index for that TC version
	if (exists $cadtreeindex{$toolcollateral}{$configtoolcollateralversion}{$cadtree}) {
	  $toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{$cadtree} = \%{$cadtreeindex{$toolcollateral}{$configtoolcollateralversion}{$cadtree}};
	} else {
	  $log->warnd("Tool Collateral version in config history no longer exists in cad tree: TC->($toolcollateral) Ver->($configtoolcollateralversion)");
	}
      }
    }
  }
}




my $cadtree = 'HDK';
my $event = EVENT_CAD_VERSION_DIR_DATE;
foreach my $toolcollateral (@toolcollaterallist) {
  foreach my $versiondir (keys %{ $cadtreeindex{$toolcollateral} }) {
    if ($cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+KEEP_VERSION}) {
      my $fullpathversiondir =  $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{'DIRECTORY'};
      my $datetime = $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+CSV_DATETIME};
      my $yyyyww = $cadtreeindex{$toolcollateral}{$versiondir}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+CSV_YYYYWW};
      my $entry = join(',', $dot_process, $opt_config, $event, $datetime, TC_TYPE_COLLATERAL, $toolcollateral, $versiondir, DATA_TYPE_VERSION_UPDATE_OCCURRED, 1, 'NA', $fullpathversiondir);
      push(@{ $timewheel{$toolcollateral}{$yyyyww}{$datetime} }, $entry);
    }
  }
}

# Assertion
# [DEBUG]-I- getTCver.pl: TC->(stdcells/ec0) REV->(3) LATEST->(NO) VER->(15ww15.5_ec0_e.1.cnl.sdg.mig_mig74_15ww19.4) WW->(201521)
#my $toolcollateral = "stdcells/ec0";
#my $rev = 3;
#$cadtree = 'HDK';
#$log->infod("Assertion tc->($toolcollateral) rev->($rev) cadtree->($cadtree)");
#$log->infod("$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{'DIRECTORY'}");
#$log->infod("$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{'MTIME'}");
#$log->infod("$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+CSV_DATETIME}");
#$log->infod("$toolcollateralhash{$toolcollateral}{'REVISIONS'}{$rev}{$cadtree}{+EVENT_CAD_VERSION_DIR_DATE}{+CSV_YYYYWW}");




# Backfill time wheel if the full CAD scan is activated (for good Excel pivoted timeline)
if (%timewheel) {
  my %wheeldatesused;
  foreach my $toolcollateral (keys %timewheel) {
    foreach my $yyyyww (keys %{ $timewheel{$toolcollateral} }) {
      $wheeldatesused{$yyyyww} = 1;
    }
  }
  my @wheeldates = sort keys %wheeldatesused;
  my $mindate = shift @wheeldates if (scalar @wheeldates);
  my $maxdate = $mindate;
  $maxdate = pop @wheeldates if (scalar @wheeldates);
  $log->infod("MINDATE: $mindate");
  $log->infod("MAXDATE: $maxdate");
  my $targetdate = $mindate;
  while ($targetdate <= $maxdate) {
    my $entry = join(',', $dot_process, $opt_config, EVENT_WW_FILL, '', '', '', '', '', '', '', '');
    push(@{ $timewheel{+EMPTY_WW}{$targetdate}{$targetdate} }, $entry);
    unless (exists $wheeldatesused{$targetdate}) {
      $entry = join(',', $dot_process, $opt_config, EVENT_NO_EVENT_IN_WW, '', '', '', '', '', '', '', '');
      push(@{ $timewheel{+EMPTY_WW}{$targetdate}{$targetdate} }, $entry);
    }
    my $yyyy = substr $targetdate, 0, 4;
    my $ww = substr $targetdate, -2;
    if ($ww == 53) {
      $yyyy++;
      $targetdate = "${yyyy}01";
    }
    elsif ($ww == 52) {
      my $timelocalyear = sprintf("%02d", $yyyy % 100);
      my $time = timelocal(0,0,0,25,11,$timelocalyear);
      my @templist = localtime($time);
      if ($templist[6] == 0) {
	$targetdate = "${yyyy}53";
      } else{
	$yyyy++;
	$targetdate = "${yyyy}01";
      }
    } else {
      $targetdate++
    }
  }
}


# Write event output csv
$stage++;
$log->newline;
$log->info("***** Stage $stage: Write event .csv report file *****");
my @csv_fields = (CSV_SCRIPT_START_DATE, CSV_SCRIPT_FINISH_DATE, CSV_YYYYWW, CSV_PROCESS, CSV_CONFIGURATION, CSV_EVENT_TYPE, CSV_EVENT_DATE, CSV_TOOL_COLLATERAL_TYPE, CSV_TOOL_COLLATERAL, CSV_VERSION, CSV_DATATYPE, CSV_DATAVALUE, CSV_FRESHNESS, CSV_COMMENT, CSV_YYYYWW_REPEAT);
unshift(@csv_fields, CSV_REPORT_ORDER) unless $opt_skipreportorder;
my $csvout = "${basefile}.events.csv";
my $csvout_h = IO::File->new;
$csvout_h->open(">$csvout") or die $log->fatalq("Could not open report file for write: $csvout");
my $headerrow = join(',', @csv_fields);
if ($opt_skipheader) {
  my $headerout = "${basefile}.header.csv";
  my $headerout_h = IO::File->new;
  $headerout_h->open(">$headerout") or die $log->fatalq("Could not open header file for write: $headerout");
  $headerout_h->print("$headerrow\n");
} else {
  $csvout_h->print("$headerrow\n");
}


my $rownum = 1;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($start_time);
$mon += 1;
$year += 1900;
my $script_start_datetime = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mon += 1;
$year += 1900;
my $script_finish_datetime = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);

foreach my $toolcollateral (sort by_toolcollateral keys %timewheel) {
  foreach my $yyyyww (sort keys %{ $timewheel{$toolcollateral} }) {
    foreach my $datetime (sort keys %{ $timewheel{$toolcollateral}{$yyyyww} }) {
      foreach my $event (@{ $timewheel{$toolcollateral}{$yyyyww}{$datetime} }) {
	my @csvrow = ();
	push(@csvrow, $rownum) unless $opt_skipreportorder;
	push(@csvrow, $script_start_datetime);
	push(@csvrow, $script_finish_datetime);
	push(@csvrow, $yyyyww);
	my $datarow = join(',', @csvrow, $event, $yyyyww);
	$csvout_h->print("$datarow\n");
	$rownum++
      }
    }
  }
}
$csvout_h->close;

# ManipFile($log, 'copy', $HOME, $csvout, '.');

DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
my $stop_minus_start = $stop_time - $start_time;
my ($elapsed_days, $elapsed_hours, $elapsed_minutes, $elapsed_seconds) = ConvertEpochSecondsToElapsedTime($stop_minus_start);
$log->newline;
$log->info("Script completion date: $stop_date");
my $elapsed_string = sprintf("Script elapsed wallclock time: %d Days, %d Hours, %d Minutes, %d Seconds", $elapsed_days, $elapsed_hours, $elapsed_minutes, $elapsed_seconds);
$log->info($elapsed_string);
$log->info("$exe_name run complete");


##### Start subroutine definitions #####

# Sort numeric
sub numerically {$a <=> $b;}

# Sort by the order of tool collateral as it appears in @toolcollaterallist
sub by_toolcollateral {$toolcollateralindex{$a} <=> $toolcollateralindex{$b};}

# Used for File::Find.  Sub written to support follow option
sub wanted {
  my $filename = $File::Find::fullname;
  my $shortname = $File::Find::name; 
  if ($filename) {
    if (($shortname =~ /\/cnldfm\/\S+\/sources\/\w+_cltr/) and (-d $filename)) {
      $File::Find::prune = 1;
      return;
    }
  }
  # If the file is a plain file (including dot files) then tally the mtime
  if (($filename) and (-f $filename)) {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
    # Record which day is the earliest in time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
    # Local tally of files under day (time set to midnight)
    $mon += 1;
    $year += 1900;
    my $datetime = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, 0, 0, 0);
    if (exists $touchtally{$datetime}) {
      $touchtally{$datetime}++;
    } else {
      $touchtally{$datetime} = 1;
    }
  }
}

