#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w
#
# $Id: spice2xl.pl,v 1.1 2015/12/23 02:54:52 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: spice2xl.pl,v 1.1 2015/12/23 02:54:52 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: spice2xl.pl
Project: ihdk 10nm
Original Author: Matthew Roha

Functional Description: This script will read one or more spice netlists and 
generate a report file for the schematic hierarchy for planning purposes.

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
use Getopt::Long;
use Time::Local;
use IO::File;
use Env;
use File::Path;
use File::Basename;
use File::Temp;
use Env;
use Cwd 'abs_path';
use Excel::Writer::XLSX;
use Spice;
use DAStd;
use Logfile;
use UE;


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
usage:  $exe_name --spicefile <path to single sp file> OR
                  --spicedir <dir containing sp files> 
                  [--run-name <logfile label>]
                  [--depth <report depth>]
                  [--nocsvheader]
                  [--uedbb <dbb name>]
                  [--uemodel <UE model>]
                  [--uecfg <user cfg file>]
                  [--env 'VAR=VALUE']
                  [--help] [--verbose] [--debug]

flag descriptions:

--spicefile         Input spice file.  Either this switch or --spicedir is required.

--spicedir          Directory containing multiple .sp files for processing.  Either this switch or --spicefile is required

--run-name          Optional.  String label for output files only. Default is the script name only.

--depth             Optional. Only report cells to given depth. Depth 0 is top level. Default is full depth.

--nocsvheader       Optional. Do not print the column header row in the .csv file. Useful
                    when concatenating multiple .csv files

--addtocsv          Optional. Input file format is csv format, embedded commas not supported.
                    file. First row expected to be column header, following rows are
                    data. First column is expected to contain fub/cell names.
                    Output csv file will have column added.

--uedbb             Optional. If not provided, default DBB is the current UE DBB.

--uemodel           Optional. If not provided, default model is current UE model.

--uecfg             Optional. User config file path for recompiling UE. If not provided, default
                    is the current UE \$USERCFGFILE setting.

--env               Optional. Set env var at start of execution. Can provide more than
                    one --env flag.  Format is VAR=VALUE

--debug             Run flow in debug mode. Temporary files are not deleted and
                    additional data is placed in log file.

--verbose           Will add status messages to STDOUT.

--help              This usage message will appear. 


example: $exe_name --spicefile fmmgend.sp
         $exe_name --spicedir $HOME/spicefiles

Files that result from this run:

\$WORK/<cell>.${exe_prefix}.log
\$WORK/<cell>.${exe_prefix}.report.csv

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $exe_name: No command line parameters. Use --help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_spicefile, $opt_spicedir, $opt_run_name);
our ($opt_depth, $opt_skip_profiler, $opt_uedbb, $opt_uemodel, $opt_uecfg);
our (@opt_env, $opt_nocsvheader, $opt_addtocsv);
our ($opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
		            "spicefile=s",
			    "spicedir=s",
			    "run-name=s", => \$opt_run_name,
			    "skip-profiler" => \$opt_skip_profiler,
			    "depth=i",
			    "nocsvheader",
			    "addtocsv=s",
			    "uedbb=s",
			    "uemodel=s",
			    "uecfg=s",
			    "env=s@",
			    "debug",
			    "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help;
my @required_flag_list = ('--spicefile:--spicedir');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);
if ($opt_spicefile and $opt_spicedir) {
  die "-F- $exe_name: --spicefile and --spicedir switches can not be used together\n";
}
if (defined $opt_depth) {
  if ($opt_depth < 0) {
    $opt_depth = 0;
  }
}


##### Begin Main Program #####

# Inputs
# - One spice file OR
# - Directory containing spice files, looking for ".sp" context
#
# General flow
# - Quick Rejection: Validate input spice netlists (confirm they are spice)
# - For each spice netlist
#   - Parse netlist
#   - Extract profile for subckt, including counts for nets, instances, devices\
#   - Skip subckt if already defined


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
if ($opt_run_name) {
  $basefile = "${opt_run_name}.${exe_prefix}";
} else { 
  $basefile = "${exe_prefix}";
}
$log = Logfile->new("${WORK}/${basefile}.log");
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


# Recompile DMSPATH file if requested by user
if ($opt_uedbb or $opt_uemodel or $opt_uecfg) {
  $stage++;
  $log->newline;
  $log->info("***** Stage $stage: --uedbb/--uemodel/--uecfg detected. Recompiling DMS path.*****");
  my $uemodel;
  if ($opt_uemodel) {
    $uemodel = $opt_uemodel;
  } else {
    $uemodel = $MODEL;
  }
  my $uedbb;
  if ($opt_uedbb) {
    $uedbb = $opt_uedbb;
  } else {
    $uedbb = $DBB;
  }
  my $uecfg;
  if ($opt_uecfg) {
    $uecfg = $opt_uecfg;
  } else {
    $uecfg = '';
  }
  $stage++;
  $log->newline;
  $log->info("***** Stage $stage: Recompiling DMSPATH *****");
  my $newdmspath = "${WORK}/${basefile}.dms.pth";
  push(@tmplist, $newdmspath);
  my $newdmsmodes = "${WORK}/${basefile}.dms.pth.modes";
  push(@tmplist, $newdmsmodes);
  my $newcdslib = "${WORK}/${basefile}.cds.lib";
  push(@tmplist, $newcdslib);
  RecompileDmspath($log, $uedbb, $uemodel, $uecfg, $newdmspath, $newcdslib);
  $DMSPATH = $newdmspath;
  $CDSLIB = $newcdslib;
}


# Read external .csv file to merge into final report if requested by user
my %external_csv;
my @external_csvfields;
if ($opt_addtocsv) {
  my $addtocsv = abs_path($opt_addtocsv);
  $stage++;
  $log->newline;
  $log->info("***** Stage $stage: --addtocsv detected. Reading external CSV to append info  *****");
  unless (-f $addtocsv) {
    die $log->fatalq("Input CSV does not exist: $addtocsv");
  }
  $log->info("CSV: $addtocsv");
  my @record;
  open (ADDTOCSV, $addtocsv) or die $log->fatalq("Could not open csv file for reading: $addtocsv");
  while (<ADDTOCSV>) {
    chomp;
    $_ = lc($_);
    @record = split(/,/, $_);
    if ($. == 1) {
      shift @record;
      @external_csvfields = @record;
      if ($opt_debug) {
	$log->infod("-addtocsv input file csv field list:");
	foreach my $field (@external_csvfields) {
	  $log->infod("field->($field)");
	}
      }
    } else {
      my $csv_cell = shift(@record);
      if ($opt_debug) {
	$log->infod("Found addtocsv input line (line $.) -> $_");
      }
      if ((scalar @record) != (scalar @external_csvfields)) {
	$log->warnp("Column count mismatch in addtocsv input file, line $.   Skipping this line...");
	next;
      }
      if (exists $external_csv{$csv_cell}) {
	$log->warnp("Found duplicate entry for $csv_cell in addtocsv input file, line $.  Using latest entry.");
      }
      foreach my $field (@external_csvfields) {
	$external_csv{$csv_cell}{$field} = shift(@record);
      }
    }
  }
  close (ADDTOCSV);
}


$stage++;
$log->newline;
$log->info("***** Stage $stage: Quick Rejection Test: Validate Input Spice Files *****");
my @target_spicefile_list;
if ($opt_spicefile) {
  my $target_spicefile = abs_path($opt_spicefile);
  if (-f $target_spicefile) {
    push @target_spicefile_list, $target_spicefile;
  } else {
    die $log->fatalq("File specified by --spicefile does not exist: $opt_spicefile");
  }

}
elsif ($opt_spicedir) {


}

my $spicefile_count = scalar @target_spicefile_list;
$log->info("Total spicefiles->(${spicefile_count})");


foreach my $target_spicefile (@target_spicefile_list) {
  my $target_spicefh = IO::File->new;
  $target_spicefh->open($target_spicefile) or die $log->fatalq("Could not open input spice netlist for reading: $target_spicefile");
  my $subckt_found = 0;
  while (<$target_spicefh>) {
    if (/^\.subckt/) {
      $subckt_found = 1;
    }
    elsif (/^\.ends/) {
      if ($subckt_found) {
	last;
      } else {
	die $log->fatalq(".ends found with no opening .subckt, line->($.), file: $target_spicefile");
      }
    }
  }
}



$stage++;
$log->newline;
$log->info("***** Stage $stage: Parse Spice Files *****");

foreach my $target_spicefile (@target_spicefile_list) {
  spiceInit($target_spicefile);
  my $test  = getSubckt("ec0nand02al1n06x5");
  #print "$test\n";
  my @instances = getInstances("ip10xddrdll_mcmpidecoder_x4pi");
  while (@instances) {
    my $name = shift @instances;
    my $hash_ref = shift @instances;
    my @sublist = keys %{$hash_ref};
    #print "NETS->($$hash_ref{'NETS'})\n";
    #print "MASTER->($$hash_ref{'MASTER'})\n";
  }
}


my %spice_hash;
foreach my $target_spicefile (@target_spicefile_list) {
  $log->info("Parsing spicefile: $target_spicefile");
  spiceInit($target_spicefile);
  my $topcell = getTopSubckts;
  my @subckt_list = getSubcktList;
  foreach my $subckt (@subckt_list) {
    $log->infod("SUBCKT FOUND->($subckt)");
    $spice_hash{$topcell}{$subckt}{'TOPCELL'} = $topcell;
    $spice_hash{$topcell}{$subckt}{'MASTER'} = $subckt;
    $spice_hash{$topcell}{$subckt}{'MASTER_NO_INDENT'} = $subckt;
    $spice_hash{$topcell}{$subckt}{'VERSION'} = getVersion($subckt);
    $log->infod("SUBCKT VERSION: subckt->($subckt) version->($spice_hash{$topcell}{$subckt}{'VERSION'})");
    #$spice_hash{$topcell}{$subckt}{'ACTIVE DEVICES'} = GetActiveDeviceCount($subckt);
    #$space_hash{$topcell}{$subckt}{'DUMMY DEVICES'} = GetDummyDeviceCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'DIGITAL PITCH DEVICES'} = GetDigitalPitchDeviceCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'TG DEVICES'} = GetTGPitchDeviceCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'XLL DEVICES'} = GetXLLPitchDeviceCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'NETS'} = GetNetCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'CONNECTIONS'} = GetConnectionCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'CELL MASTERS'} = GetMasterCount($subckt);
    #$spice_hash{$topcell}{$subckt}{'CELL INSTANCES'} = GetInstanceCount($subckt);
    #my @instancemasters_list = GetInstanceMasters($subckt);
    #foreach my $master (@record) {
    #  $sch_record{$topcell}{$subckt}{'INSTMASTERS'}{$master}++;
    #}
    #my $category = 'UNKNOWN';
    #my $macro_profile;
    #my $device_profile;
  }
}

exit;



# Build CAFE runfile for parsing SN file
unless ($opt_skip_profiler) {

$stage++;
$log->newline;
$log->info("***** Stage $stage: Running CAFE extractor on SN *****");
my $cafe_runfile = "${WORK}/${basefile}.cafe.tcl";
my $cafe_runfile_base = basename($cafe_runfile);
our $CAFE;
unless ($ENV{'CAFE'}) {
  $ENV{'CAFE'} = "/p/mpg/proc/cad/em64t_linux26/cafe/1.2.5";
}
$log->infoq("CAFE environment: \$CAFE->($ENV{'CAFE'})");
open (CAFEFILE, ">$cafe_runfile") or die $log->fatalq("Could not open cafe runfile for writing: $cafe_runfile");

### Start CAFE TCL script section
print CAFEFILE <<"CAFESCRIPT";
\#!/bin/sh -f

\# \\
exec $ENV{'CAFE'}/cafe -script \$0 \$*

lassign [split \$argv] cell targetsn

if {[catch {ispl_parse_circuit -circuit \$cell -macro \$cell -file \$targetsn -fix} msg]} {
  error "\$msg"
}

set macros [ispl_list_macros]
foreach macro \$macros {
  set digitaldevicecount 0
  set analogdevicecount 0
  set dummydevicecount 0 
  set netcount 0
  set connectioncount 0
  array set netCountHash {}
  array set masterCountHash {}
  set instancemasterlist {}
  foreach element [ispl_list_elements -macro \$macro] {
    ispl_element -macro \$macro -type type -template template \$element
    if {\$type == "mos"} {
      set valuecount 0
      set devicetype ""
      foreach value [ispl_list_values -macro \$macro -types -evaluate_type \$element] {
        if {\$valuecount == 2} {
          if {[regexp {^0\.(052|08(0)?|058|088|116)\\s+REAL} \$value]} {
	    set devicetype "analog"
          } else {
            set devicetype "digital"
          }
          break
        }
        incr valuecount
      }
    } elseif {\$type == "instance"} {
      lappend instancemasterlist \$template
      set template [ispl_get_element_template -macro \$macro \$element]
      if {![info exist masterCountHash(\$template)]} {
        set masterCountHash(\$template) 1
      }
    } else {
      puts "-W- getSNMetrics: Found unhandled type: macro->(\$macro) type->(\$type)"
    }
    set dummynodecount 0
    foreach connection [ispl_list_connections -macro \$macro -element \$element] {
      set connectionLC [string tolower \$connection]
      if {\$type == "mos"} {
	if {[regexp {^((vc|vss)|(\\d+\$))} \$connectionLC]} {
          incr dummynodecount
        }
      }
      if {![regexp {^((vc|vs)|(\\d+\$)|(_hercules_generated_(\\d+\$)))} \$connectionLC]} {
        if {[info exist netCountHash(\$connectionLC)]} { 
          incr netCountHash(\$connectionLC)
        } else {
          set netCountHash(\$connectionLC) 1
        }
      }
    }
    if {\$type == "mos"} {
      if {\$dummynodecount > 2} {
        incr dummydevicecount
      } elseif {\$devicetype == "analog"} {
        incr analogdevicecount
      } else {
        incr digitaldevicecount
      }
    }
  }
  set netcount [array size netCountHash]
  set mastercount [array size masterCountHash]
  foreach targetConnection [array names netCountHash] {
    set connectioncount [expr \$netCountHash(\$targetConnection) + \$connectioncount]
    if {\$netCountHash(\$targetConnection) > 1} {
      incr connectioncount -1
    }
  }
  puts "-I- getSNMetrics: macro->(\$macro)  digitalDeviceCount->(\$digitaldevicecount)  analogDeviceCount->(\$analogdevicecount)  dummyDeviceCount->(\$dummydevicecount)  netCount->(\$netcount)  connectionCount->(\$connectioncount)  uniqueMasterCount->(\$mastercount)  instMasters->(\$instancemasterlist)"
  array unset netCountHash
  array unset masterCountHash
}

CAFESCRIPT

close CAFEFILE;
chmod 0775, $cafe_runfile;

my $cell_lc;
my %primlist_hash;
# Parse CAFE run results and hash to data structures
$stage++;
$log->newline;
$log->info("***** Stage $stage: Processing CAFE run results *****");
my %sch_record;
my $testchip_prefix = '(w\d+)?x(\d+)';
my $adtemplate_prefix = '(c)(8)';
my $stdcell_prefix = '(c(c0|s7|xx))';
my $layoutonly_prefix = '(gsr|ivb|skl)_';

my @stdout_and_err;
foreach my $string (@stdout_and_err) {
  $log->flowname('CAFE_OUT');
  $log->infod($string);
  $log->flowname($exe_name);
  if ($string =~ /error\(s\) while parsing/) {
    die $log->fatalq("CAFE reported errors while parsing SN file. See log file for details.");
  }
  elsif ($string =~ /\(\)(.+)instMasters/) {
    die $log->fatalq("Unexpected empty value from CAFE query:", $string);
  }
  elsif ($string =~ /getSNMetrics:\s+macro->\((\S+)\)\s+digitalDeviceCount->\((\d+)\)\s+analogDeviceCount->\((\d+)\)\s+dummyDeviceCount->\((\d+)\)\s+netCount->\((\d+)\)\s+connectionCount->\((\d+)\)\s+uniqueMasterCount->\((\d+)\)\s+instMasters->\((.*)\)/) {
    my $macro = $1;
    my $digitaldevicecount = $2;
    my $analogdevicecount = $3;
    my $dummydevicecount = $4;
    my $netcount = $5;
    my $connectioncount = $6;
    my $mastercount = $7;
    my $instmasters = $8;
    my $activedevicecount = $digitaldevicecount + $analogdevicecount;
    $sch_record{$macro}{'MASTER'} = $macro;
    $sch_record{$macro}{'MASTER_NO_INDENT'} = $macro;
    $sch_record{$macro}{'ACTIVE DEVICES'} = $activedevicecount;
    $sch_record{$macro}{'ANALOG DEVICES'} = $analogdevicecount;
    $sch_record{$macro}{'DIGITAL DEVICES'} = $digitaldevicecount;
    $sch_record{$macro}{'DECAP/DUMMY DEVICES'} = $dummydevicecount;
    $sch_record{$macro}{'NETS'} = $netcount;
    $sch_record{$macro}{'CONNECTIONS'} = $connectioncount;
    $sch_record{$macro}{'CELL MASTERS'} = $mastercount;
    $sch_record{$macro}{'CELL INSTANCES'} = 0;
    my @record = split /\s+/, $instmasters;
    foreach my $master (@record) {
      $sch_record{$macro}{'INSTMASTERS'}{$master}++;
      $sch_record{$macro}{'CELL INSTANCES'}++;
    }
    my $category = 'UNKNOWN';
    my $macro_profile;
    my $device_profile;
    
    if ($macro =~ /^${stdcell_prefix}/) {
      $macro_profile = 'stdcell';
    }
    elsif ($macro =~ /^${adtemplate_prefix}/) {
      $macro_profile = 'ad template';
    }
    elsif ($macro =~ /^${layoutonly_prefix}/) {
      $macro_profile = 'layout only';
    }
    elsif ($macro =~ /^${testchip_prefix}/) {
      $macro_profile = "testchip custom";
    } else {
      $macro_profile = 'custom';
    }

    if ($macro_profile eq 'layout only') {
      $device_profile = 'cell';
    }
    elsif (exists $primlist_hash{$macro}) {
      $device_profile = 'bbox';
    }
    elsif ($activedevicecount == 0) {
      if ($sch_record{$macro}{'CELL INSTANCES'} == 0) {
	$device_profile = 'primitive or passive';
      } else {
	$device_profile = 'routing hier';
      }
    }
    elsif (($digitaldevicecount > 0) and ($analogdevicecount > 0)) {
      $device_profile = 'analog+digital';
    }
    elsif ($digitaldevicecount > 0) {
      $device_profile = 'digital';
    }
    elsif ($analogdevicecount > 0) {
      $device_profile = 'analog';
    }
    if ($macro_profile and $device_profile) {
      $category = "$macro_profile $device_profile";
    }
    $sch_record{$macro}{'CATEGORY'} = $category;
  }
  elsif ($string =~ /^\-W\-/) {
    $log->warn("Warning from CAFE run:", $string);
  }
  elsif (not $opt_debug) {
    $log->flowname('CAFE_OUT');
    $log->infoq($string);
    $log->flowname($exe_name);
  }
}
if ($opt_debug) {
  foreach my $macro (sort keys %sch_record) {
    $log->infod("Master:$sch_record{$macro}{'MASTER'} Category:$sch_record{$macro}{'CATEGORY'} DigitalDevices:$sch_record{$macro}{'DIGITAL DEVICES'} AnalogDevices:$sch_record{$macro}{'ANALOG DEVICES'}  DecapDummyDevices:$sch_record{$macro}{'DECAP/DUMMY DEVICES'}}  Nets:$sch_record{$macro}{'NETS'} Connections:$sch_record{$macro}{'CONNECTIONS'} Masters:$sch_record{$macro}{'CELL MASTERS'} Instances:$sch_record{$macro}{'CELL INSTANCES'}");
    if (defined $sch_record{$macro}{'INSTMASTERS'}) {
      foreach my $instmaster (sort keys %{ $sch_record{$macro}{'INSTMASTERS'} }) {
	$log->infod("    Instance $instmaster ($sch_record{$macro}{'INSTMASTERS'}{$instmaster})");
      }
    }
  }
}

# Backfill additional fields for each cell.  Assume zero initial effort for stdcell and testchip collateral
my $analog_devices_per_day = 20;
my $digital_devices_per_day = 20;
my $dummy_devices_per_day = 1000;
my $connections_per_day = 500;
my @backfill_fields = ('ESTIMATED ROUTING EFFORT FOR THIS LEVEL', 'ESTIMATED ANALOG EFFORT FOR THIS LEVEL', 'ESTIMATED DIGITAL EFFORT FOR THIS LEVEL', 'ESTIMATED DECAP/DUMMY EFFORT FOR THIS LEVEL', 'ESTIMATED TOTAL EFFORT FOR THIS LEVEL', 'ADJUSTED EFFORT FOR THIS LEVEL', 'ADJUSTED EFFORT DELTA FOR THIS LEVEL');
foreach my $macro (keys %sch_record) {
  foreach my $field (@backfill_fields) {
    $sch_record{$macro}{$field} = '';
    if ($field =~ /ESTIMATED/) {
      if ($sch_record{$macro}{'CATEGORY'} =~ /^(stdcell|(layout only))/) {
	$sch_record{$macro}{$field} = 0;
      }
    }      
  }
  $sch_record{$macro}{'ESTIMATED ANALOG EFFORT FOR THIS LEVEL'} = $sch_record{$macro}{'ANALOG DEVICES'}/${analog_devices_per_day};
  $sch_record{$macro}{'ESTIMATED DIGITAL EFFORT FOR THIS LEVEL'} = $sch_record{$macro}{'DIGITAL DEVICES'}/${digital_devices_per_day};
  $sch_record{$macro}{'ESTIMATED DECAP/DUMMY EFFORT FOR THIS LEVEL'} = $sch_record{$macro}{'DECAP/DUMMY DEVICES'}/${dummy_devices_per_day};
  if ($sch_record{$macro}{'ACTIVE DEVICES'} == 0) {
    $sch_record{$macro}{'ESTIMATED ROUTING EFFORT FOR THIS LEVEL'} = $sch_record{$macro}{'CONNECTIONS'}/${connections_per_day};
  } else {
    $sch_record{$macro}{'ESTIMATED ROUTING EFFORT FOR THIS LEVEL'} = 0;
  }
  $sch_record{$macro}{'ESTIMATED TOTAL EFFORT FOR THIS LEVEL'} = $sch_record{$macro}{'ESTIMATED ANALOG EFFORT FOR THIS LEVEL'} + $sch_record{$macro}{'ESTIMATED DIGITAL EFFORT FOR THIS LEVEL'};
  $sch_record{$macro}{'ESTIMATED TOTAL EFFORT FOR THIS LEVEL'} += $sch_record{$macro}{'ESTIMATED DECAP/DUMMY EFFORT FOR THIS LEVEL'} + $sch_record{$macro}{'ESTIMATED ROUTING EFFORT FOR THIS LEVEL'};
} 


# Recursively calculate hierarchical unique device counts for each hierarchy
my @unique_field_list = ('UNIQUE CUSTOM EFFORT', 'UNIQUE TESTCHIP EFFORT', 'UNIQUE STDCELL EFFORT', 'UNIQUE NETS', 'UNIQUE CONNECTIONS', 'UNIQUE CELL MASTERS', 'UNIQUE CELL INSTANCES', 'UNIQUE ACTIVE DEVICES', 'UNIQUE ANALOG DEVICES', 'UNIQUE DIGITAL DEVICES');
@unique_field_list = (@unique_field_list, 'UNIQUE CUSTOM ANALOG DEVICES', 'UNIQUE CUSTOM DIGITAL DEVICES');
@unique_field_list = (@unique_field_list, 'UNIQUE TESTCHIP ANALOG DEVICES', 'UNIQUE TESTCHIP DIGITAL DEVICES');
@unique_field_list = (@unique_field_list, 'UNIQUE STDCELL ANALOG DEVICES', 'UNIQUE STDCELL DIGITAL DEVICES');
$stage++;
$log->newline;
$log->info("***** Stage $stage: Calculate unique hierarchical device counts *****");
SetUniqueFieldValues(\%sch_record, \@unique_field_list, $cell_lc);
if ($opt_debug) {
  foreach my $macro (sort keys %sch_record) {
    my @debug_record = ();
    push @debug_record, "MASTER:$sch_record{$macro}{'MASTER'}";
    foreach my $field (@unique_field_list) {
      push @debug_record, "${field}:$sch_record{$macro}{$field}";
    }
    my $data = join(' ', @debug_record);
    $log->infod($data)
    }
}

 
# Recursively calculate flat device counts for each hierarchy
my @flat_field_list = ('FLAT NETS', 'FLAT CONNECTIONS', 'FLAT CELL MASTERS', 'FLAT CELL INSTANCES', 'FLAT ACTIVE DEVICES', 'FLAT DIGITAL DEVICES', 'FLAT ANALOG DEVICES');
@flat_field_list = (@flat_field_list, 'FLAT CUSTOM ANALOG DEVICES', 'FLAT CUSTOM DIGITAL DEVICES');
@flat_field_list = (@flat_field_list, 'FLAT TESTCHIP ANALOG DEVICES', 'FLAT TESTCHIP DIGITAL DEVICES');
@flat_field_list = (@flat_field_list, 'FLAT STDCELL ANALOG DEVICES', 'FLAT STDCELL DIGITAL DEVICES');
$stage++;
$log->newline;
$log->info("***** Stage $stage: Calculate flat device counts *****");
SetFlatFieldValues(\%sch_record, \@flat_field_list, $cell_lc);
if ($opt_debug) {
  foreach my $macro (sort keys %sch_record) {
    my @debug_record = ();
    push @debug_record, "MASTER:$sch_record{$macro}{'MASTER'}";
    foreach my $field (@flat_field_list) {
      push @debug_record, "${field}:$sch_record{$macro}{$field}";
    }
    my $data = join(' ', @debug_record);
    $log->infod($data)
  }
}


# Merge in external csv from user, if exists
if (scalar @external_csvfields) {
  foreach my $macro (keys %sch_record) {
    foreach my $csvfield (@external_csvfields) {
      if (exists $external_csv{$macro}) {
	$sch_record{$macro}{$csvfield} = $external_csv{$macro}{$csvfield};
      } else {
	$sch_record{$macro}{$csvfield} = '';
      }
    }
  }
}


# Compile ordered hierarchy report
$stage++;
$log->newline;
$log->info("***** Stage $stage: Compile hierarchy report *****");
my $rank = 0;
my %listing;
my %ordered_report_hash;
CompileOrderedReport(\%sch_record, \%ordered_report_hash, \$rank, \%listing, $cell_lc, 0, 1);


# Write output files
$stage++;
$log->newline;
$log->info("***** Stage $stage: Write output files *****");
my @csv_fields = ('RANK', 'LISTING', 'INSTANCES IN PARENT', 'MASTER', 'DEPTH', 'CATEGORY', 'NETS', 'CONNECTIONS', 'CELL MASTERS');
@csv_fields = (@csv_fields, 'CELL INSTANCES', 'ANALOG DEVICES', 'DIGITAL DEVICES', 'DECAP/DUMMY DEVICES', 'ACTIVE DEVICES');
@csv_fields = (@csv_fields, @backfill_fields, @unique_field_list, @flat_field_list, @external_csvfields, 'MASTER_NO_INDENT');
my $csv_report = "${WORK}/${basefile}.report.csv";
my $csv_reportfh = IO::File->new;
$csv_reportfh->open (">$csv_report") or die $log->fatalq("Could not open csv sch report for writing: $csv_report");
unless ($opt_nocsvheader) {
  my $csv_header = lc(join(',', @csv_fields));
  $csv_reportfh->print("$csv_header\n");
}
foreach my $rownumber (sort numerically keys %ordered_report_hash) {
  my @csv_record = ();
  foreach my $field (@csv_fields) {
    push (@csv_record, $ordered_report_hash{$rownumber}{$field});
  }
  my $datarow = join(',', @csv_record);
  my $depth = $ordered_report_hash{$rownumber}{'DEPTH'};
  if (defined $opt_depth) {
    if ($depth <= $opt_depth) {
      $csv_reportfh->print("$datarow\n");
    }
  } else {
    $csv_reportfh->print("$datarow\n");
  }
}
$csv_reportfh->close;
ManipFile($log, 'copy', $HOME, $csv_report, '.');


}  # end $opt_skip_profiler

DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$log->info("Script completion date: $stop_date");
$log->info("$exe_name run complete");




##### Start subroutine definitions #####

sub numerically {$a <=> $b;}




# SetHierUniqDevices
# Calculates hierarchical unique device counts for each hierarchy and populates fields in %sch_record for later processing
# Uses depth first recursion
sub SetUniqueFieldValues {
  my $sch_record_ref = shift;
  my $field_list_ref = shift;
  my $cell = shift;

  unless (defined $$sch_record_ref{$cell}{'UNIQUE ACTIVE DEVICES'}) {
    if (defined $$sch_record_ref{$cell}{'INSTMASTERS'}) {
      foreach my $macro (sort keys %{ $$sch_record_ref{$cell}{'INSTMASTERS'} }) {
	&SetUniqueFieldValues($sch_record_ref, $field_list_ref, $macro);
	foreach my $field (@{$field_list_ref}) {
	  $$sch_record_ref{$cell}{$field}+= $$sch_record_ref{$macro}{$field};
	}
      }
    }
    $$sch_record_ref{$cell}{'UNIQUE NETS'}+= $$sch_record_ref{$cell}{'NETS'};
    $$sch_record_ref{$cell}{'UNIQUE CONNECTIONS'}+= $$sch_record_ref{$cell}{'CONNECTIONS'};
    $$sch_record_ref{$cell}{'UNIQUE CELL MASTERS'}+= $$sch_record_ref{$cell}{'CELL MASTERS'};
    $$sch_record_ref{$cell}{'UNIQUE CELL INSTANCES'}+= $$sch_record_ref{$cell}{'CELL INSTANCES'};
    $$sch_record_ref{$cell}{'UNIQUE ACTIVE DEVICES'}+= $$sch_record_ref{$cell}{'ACTIVE DEVICES'};
    $$sch_record_ref{$cell}{'UNIQUE DIGITAL DEVICES'}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
    $$sch_record_ref{$cell}{'UNIQUE ANALOG DEVICES'}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
    $$sch_record_ref{$cell}{'UNIQUE CUSTOM EFFORT'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE TESTCHIP EFFORT'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE STDCELL EFFORT'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE CUSTOM DIGITAL DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE CUSTOM ANALOG DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE TESTCHIP DIGITAL DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE TESTCHIP ANALOG DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE STDCELL DIGITAL DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'UNIQUE STDCELL ANALOG DEVICES'}+= 0;
    if ($$sch_record_ref{$cell}{'CATEGORY'} =~ /^(stdcell|(layout only)|(ad template))/) {
      $$sch_record_ref{$cell}{'UNIQUE STDCELL DIGITAL DEVICES'}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
      $$sch_record_ref{$cell}{'UNIQUE STDCELL ANALOG DEVICES'}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
      $$sch_record_ref{$cell}{'UNIQUE STDCELL EFFORT'}+= $$sch_record_ref{$cell}{'ESTIMATED TOTAL EFFORT FOR THIS LEVEL'};
    }
    elsif ($$sch_record_ref{$cell}{'CATEGORY'} =~ /^testchip/) {
      $$sch_record_ref{$cell}{"UNIQUE TESTCHIP DIGITAL DEVICES"}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
      $$sch_record_ref{$cell}{"UNIQUE TESTCHIP ANALOG DEVICES"}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
      $$sch_record_ref{$cell}{'UNIQUE TESTCHIP EFFORT'}+= $$sch_record_ref{$cell}{'ESTIMATED TOTAL EFFORT FOR THIS LEVEL'};
    } else {
      $$sch_record_ref{$cell}{'UNIQUE CUSTOM DIGITAL DEVICES'}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
      $$sch_record_ref{$cell}{'UNIQUE CUSTOM ANALOG DEVICES'}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
      $$sch_record_ref{$cell}{'UNIQUE CUSTOM EFFORT'}+= $$sch_record_ref{$cell}{'ESTIMATED TOTAL EFFORT FOR THIS LEVEL'};
    }
  }				   
}


# SetFlatDevices
# Calculates flat/smashed device counts for each hierarchy and populates fields in %sch_record for later processing
# Uses depth first recursion
sub SetFlatFieldValues {
  my $sch_record_ref = shift;
  my $field_list_ref = shift;
  my $cell = shift;

  unless (defined $$sch_record_ref{$cell}{'FLAT ACTIVE DEVICES'}) {
    if (defined $$sch_record_ref{$cell}{'INSTMASTERS'}) {
      foreach my $macro (sort keys %{ $$sch_record_ref{$cell}{'INSTMASTERS'} }) {
	&SetFlatFieldValues($sch_record_ref, $field_list_ref, $macro);
	foreach my $field (@{$field_list_ref}) {
	  $$sch_record_ref{$cell}{$field}+= ($$sch_record_ref{$macro}{$field}*$$sch_record_ref{$cell}{'INSTMASTERS'}{$macro});
	}
      }
    }
    $$sch_record_ref{$cell}{'FLAT NETS'}+= $$sch_record_ref{$cell}{'NETS'};
    $$sch_record_ref{$cell}{'FLAT CONNECTIONS'}+= $$sch_record_ref{$cell}{'CONNECTIONS'};
    $$sch_record_ref{$cell}{'FLAT CELL MASTERS'}+= $$sch_record_ref{$cell}{'CELL MASTERS'};
    $$sch_record_ref{$cell}{'FLAT CELL INSTANCES'}+= $$sch_record_ref{$cell}{'CELL INSTANCES'};
    $$sch_record_ref{$cell}{'FLAT ACTIVE DEVICES'}+= $$sch_record_ref{$cell}{'ACTIVE DEVICES'};
    $$sch_record_ref{$cell}{'FLAT DIGITAL DEVICES'}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
    $$sch_record_ref{$cell}{'FLAT ANALOG DEVICES'}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
    $$sch_record_ref{$cell}{'FLAT CUSTOM DIGITAL DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'FLAT CUSTOM ANALOG DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'FLAT TESTCHIP DIGITAL DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'FLAT TESTCHIP ANALOG DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'FLAT STDCELL DIGITAL DEVICES'}+= 0;
    $$sch_record_ref{$cell}{'FLAT STDCELL ANALOG DEVICES'}+= 0;
    if ($$sch_record_ref{$cell}{'CATEGORY'} =~ /^(stdcell|(layout only)|(ad template))/) {
      $$sch_record_ref{$cell}{'FLAT STDCELL DIGITAL DEVICES'}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
      $$sch_record_ref{$cell}{'FLAT STDCELL ANALOG DEVICES'}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
    }
    elsif ($$sch_record_ref{$cell}{'CATEGORY'} =~ /^testchip/) {
      $$sch_record_ref{$cell}{"FLAT TESTCHIP DIGITAL DEVICES"}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
      $$sch_record_ref{$cell}{"FLAT TESTCHIP ANALOG DEVICES"}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'};
    } else {
      $$sch_record_ref{$cell}{'FLAT CUSTOM DIGITAL DEVICES'}+= $$sch_record_ref{$cell}{'DIGITAL DEVICES'};
      $$sch_record_ref{$cell}{'FLAT CUSTOM ANALOG DEVICES'}+= $$sch_record_ref{$cell}{'ANALOG DEVICES'}; 
    }
  }				   
}


sub CompileOrderedReport {
  my $sch_record_ref = shift;
  my $ordered_report_hash_ref = shift;
  my $rank_ref = shift;
  my $listing_ref = shift;
  my $cell = shift;
  my $level = shift;
  my $instmasters = shift;
  my $spacer = '     ' x $level;

  $$rank_ref++;
  $$ordered_report_hash_ref{$$rank_ref}{'RANK'} = $$rank_ref;
  if (exists $$listing_ref{$cell}) {
    $$listing_ref{$cell}++;
  } else {
    $$listing_ref{$cell} = 1;
  } 
  $$ordered_report_hash_ref{$$rank_ref}{'LISTING'} = $$listing_ref{$cell};
  $$ordered_report_hash_ref{$$rank_ref}{'DEPTH'} = $level;
  $$ordered_report_hash_ref{$$rank_ref}{'INSTANCES IN PARENT'} = $instmasters;
  foreach my $field (keys %{$$sch_record_ref{$cell}}) {
    $$ordered_report_hash_ref{$$rank_ref}{$field} = $$sch_record_ref{$cell}{$field};
  } 
  $$ordered_report_hash_ref{$$rank_ref}{'MASTER'} = "${spacer}$$ordered_report_hash_ref{$$rank_ref}{'MASTER'}";
  if (defined $$sch_record_ref{$cell}{'INSTMASTERS'}) {
    foreach my $macro (sort keys %{ $$sch_record_ref{$cell}{'INSTMASTERS'} }) {
      &CompileOrderedReport($sch_record_ref, $ordered_report_hash_ref, $rank_ref, $listing_ref, $macro, $level+1, $$sch_record_ref{$cell}{'INSTMASTERS'}{$macro});
    }
  }
}

