#!/usr/intel/pkgs/perl/5.8.5/bin/perl -w
#
# $Id: schdev.pl,v 1.3 2008/09/05 22:33:48 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: schdev.pl,v 1.3 2008/09/05 22:33:48 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: schdev.pl
Project: Sandy Bridge
Original Author: Matthew Roha

Functional Description: This script will generate (or read) an SNSCH file and 
generate a report file on the following information for each master
  - Hierarchy level
  - Number of custom devices
  - Number of devices in std cells
  - Number of instances

=cut




BEGIN {
  use IO::Dir
  my %homedir;
  my $homeproject = "snb";
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'EC_SITE'}) {
    my $targetdirname = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new($targetdirname);
    my @dirs = grep /\w+/, $dir->read();
    foreach my $item (@dirs) {
      if (-d "${targetdirname}/${item}") {
	push @INC, "${targetdirname}/${item}";
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
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';
use DAStd;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Get the site
our $SITE = &GetSite();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell>
                  [-depth <report depth>]
                  [-skipnetlist]
                  [-nocsvheader]
                  [-cdba]
                  [-addtocsv <input file>]
                  [-dbb <dbb name>]
                  [-uemodel <UE model>]
                  [-env 'VAR=VALUE']
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input cell name

-depth            Only report cells to given depth. Depth 0 is top level.

-skipnetlist      Will not run nike netlister and will search for sn file in PDSSN

-dbb              Optional. If not provided, default DBB is the cell name

-uemodel          Optional. If not provided, default model is current UE model

-cdba             Optional. nike_netlister will use cdba as input. Default is sch format.

-nocsvheader      Optional. Do not print the column header row in the .csv file. Useful
                  when concatenating multiple .csv files

-addtocsv         Optional. Input file format is csv or whitespace delimited
                  file. First row expected to be column header, following rows are
                  data. First column is expected to contain fub/cell names.
                  Output csv file will have column added.

-env              Optional. Set env var at start of execution. Can have more than
                  one -env flag.

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend
         $EXE_NAME -cell bnsdcdtimer -dbb dccdatad -uemodel pshift2

Files that result from this run:

\$WORK/<cell>.${EXE_PREFIX}.log
\$WORK/<cell>.${EXE_PREFIX}.report
\$WORK/<cell>.${EXE_PREFIX}.csv

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_cell, $opt_depth, $opt_skipnetlist, $opt_dbb, $opt_uemodel, @opt_env);
our ($opt_nocsvheader, $opt_addtocsv, $opt_cdba);
our ($opt_help, $opt_debug, $opt_verbose);
my $options_ok = &GetOptions("help",
			     "cell=s",
                             "depth=i",
			     "skipnetlist",
			     "nocsvheader",
			     "cdba",
			     "addtocsv=s",
			     "dbb=s",
			     "uemodel=s",
			     "env=s@",
			     "ignorecmp",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

if (defined $opt_depth) {
  if ($opt_depth < 0) {
    $opt_depth = 0;
  }
}




##### Main Program #####


# Capture initial environment variables
our ($HOME, $WORK_AREA_ROOT_DIR);
my @env_list = ('HOME', 'WORK_AREA_ROOT_DIR');

our ($DB_ROOT, $PROJECT, $GENESYS_DIR, $MODEL, $NIKE_NETLISTER);
our ($DMSPATH, $DBB, $CDSLIB, $LM_LICENSE_FILE, $CAD_ROOT);
@env_list = (@env_list, 'DB_ROOT', 'PROJECT', 'GENESYS_DIR', 'MODEL', 'NIKE_NETLISTER');
@env_list = (@env_list, 'DMSPATH', 'DBB', 'CDSLIB', 'LM_LICENSE_FILE', 'CAD_ROOT');


foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
my $cell_lc = lc($opt_cell);

our ($BASEFILE, $MAINLOG, $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${EXE_PREFIX}";
$MAINLOG = LogFile->new("${WARD}/${BASEFILE}.log");
$MAINLOG->flowname($EXE_NAME);
$MAINLOG->verbose($opt_verbose);

my $machine_info = `uname -a`;
chomp $machine_info;
$MAINLOG->info("Script command: $EXE_NAME $COMMAND_LINE");
$MAINLOG->info("Script start date: $start_date");
$MAINLOG->info("System info: $machine_info");

# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @TMPFILES = ();


# Set any command line env vars
if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $MAINLOG->infoq("-env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $MAINLOG->fatalq("Invalid value for switch -env: $setting");
    }
  }
}


# Make sure we can't mess with the ATF database
$ENV{'ATF_LOCKED'} = 'YES';


my $uemodel;
if ($opt_uemodel) {
  $uemodel = $opt_uemodel;
} else {
  $uemodel = $MODEL;
}

my $dbb;
if ($opt_dbb) {
  $dbb = $opt_dbb;
} else {
  $dbb = $cell_lc;
}

my $input_netlist_format = 'sch';
if ($opt_cdba) {
  $input_netlist_format = 'cdba';
}


my $stage = 1;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Recompiling DMSPATH *****");
my $newdmspath = "${WARD}/${BASEFILE}.dms.pth";
push(@TMPFILES, $newdmspath);
my $newdmsmodes = "${WARD}/${BASEFILE}.dms.pth.modes";
push(@TMPFILES, $newdmsmodes);
my $newcdslib = "${WARD}/${BASEFILE}.cds.lib";
push(@TMPFILES, $newcdslib);
&RecompileDmspath($MAINLOG, $dbb, $uemodel, $newdmspath, $newcdslib);
$DMSPATH = $newdmspath;
$CDSLIB = $newcdslib;

my %external_csv;
my @external_csvfields;
if ($opt_addtocsv) {
  my $addtocsv = abs_path($opt_addtocsv);
  $stage++;
  $MAINLOG->newline;
  $MAINLOG->info("***** Stage $stage: Reading external CSV to append info  *****");
  unless (-e $addtocsv) {
    die $MAINLOG->fatalq("Input CSV does not exist: $addtocsv");
  }
  $MAINLOG->info("CSV: $addtocsv");
  my @record;
  open (ADDTOCSV, $addtocsv) or die $MAINLOG->fatalq("Could not open csv file for reading: $addtocsv");
  while (<ADDTOCSV>) {
    chomp;
    $_ = lc($_);
    @record = split(/,/, $_);
    if ($. == 1) {
      shift @record;
      @external_csvfields = @record;
      if ($opt_debug) {
	$MAINLOG->infod("-addtocsv input file csv field list:");
	foreach my $field (@external_csvfields) {
	  $MAINLOG->infod("field->($field)");
	}
      }
    } else {
      my $csv_cell = shift(@record);
      if ($csv_cell ne $cell_lc) {
	next;
      }
      if ($opt_debug) {
	$MAINLOG->infod("Found addtocsv input line (line $.) -> $_");
      }
      if ((scalar @record) != (scalar @external_csvfields)) {
	$MAINLOG->warnp("Column count mismatch in addtocsv input file, line $.   Skipping this line...");
	next;
      }
      if (exists $external_csv{$cell_lc}) {
	$MAINLOG->warnp("Found duplicate entry for $cell_lc in addtocsv input file, line $.  Using last entry.");
      }
      foreach my $field (@external_csvfields) {
	$external_csv{$csv_cell}{$field} = shift(@record);
      }
    }
  }
  close (ADDTOCSV);
}
	
	
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Prepping/Generating SN  *****");

unless ($opt_skipnetlist) {
  my $rundirty = &RunNikeNetlister($MAINLOG, $cell_lc, $input_netlist_format, 'snsch', '');
  if ($rundirty) {
    die $MAINLOG->fatalq("Netlist run failed for cell->($cell_lc). See netlister log in \$WORK/netlists");
  }
}

my $sn_file = "${PDSSN}/${cell_lc}.sn";
my ($name,$path,$suffix) = fileparse($sn_file);
my $resolved_path = abs_path($path);
$sn_file = "${resolved_path}/${name}"; 

if (-e $sn_file) {
  $MAINLOG->infoq("Using SN file: $sn_file");
} else {
  die $MAINLOG->fatalq("SN file does not exist: $sn_file");
}


$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Running CAFE Extractor On SN *****");

my $cafe_runfile = "${WARD}/${BASEFILE}.cafe.tcl";
my $cafe_runfile_base = basename($cafe_runfile);
open (CAFEFILE, ">$cafe_runfile") or die $MAINLOG->fatalq("Could not open cafe runfile for writing: $cafe_runfile");


### Start TCL script
print CAFEFILE <<"CAFESCRIPT";
\#!/bin/sh -f

\# \\
exec ${CAD_ROOT}/cafe/1.2.5/cafe -script \$0 \$*

lassign [split \$argv] cell targetsn

if {[catch {ispl_parse_circuit -circuit \$cell -macro \$cell -file \$targetsn} msg]} {
  error "\$msg"
}

set macros [ispl_list_macros]

foreach macro \$macros {
  set devcount 0
  set instancemasterlist {}
  foreach element [ispl_list_elements -macro \$macro] {
    ispl_element -macro \$macro -type type -template template \$element
    #puts "type: \$type"
    if {\$type == "mos"} {
      incr devcount
    } elseif {\$type == "instance"} {
      lappend instancemasterlist \$template 
    } 
  }
  puts "$cafe_runfile_base: macro->(\$macro) devices->(\$devcount) instmasters->(\$instancemasterlist)"
}

CAFESCRIPT
  
close CAFEFILE;

chmod 0775, $cafe_runfile;
my $cafe_cmd = "${cafe_runfile} $cell_lc $sn_file";
my @stdout_and_err;
&Pipe($MAINLOG, "$cafe_cmd", '', \@stdout_and_err);


my %dev_record;
foreach my $string (@stdout_and_err) {
  if ($string =~ /macro\->\(\)/) {
    die $MAINLOG->fatalq("Empty macro value from CAFE");
  }
  if ($string =~ /devices\->\(\)/) {
    die $MAINLOG->fatalq("Empty device value from CAFE");
  }
  if ($string =~ /macro\->\((\S+)\)\s+devices\->\((\d+)\)\s+instmasters\->\((.*)\)/) {
    my $macro = $1;
    my $devcount = $2;
    my $instmasters = $3;
    $dev_record{$macro}{'DEVICES'} = $devcount;
    my @record = split /\s+/, $instmasters;
    foreach my $master (@record) {
      $dev_record{$macro}{'INSTMASTERS'}{$master}++;
    }
  }
}

if ($opt_debug) {
  foreach my $macro (sort keys %dev_record) {
    $MAINLOG->infod("Macro:$macro Devices:$dev_record{$macro}{'DEVICES'}");
    if (defined $dev_record{$macro}{'INSTMASTERS'}) {
      foreach my $instmaster (sort keys %{ $dev_record{$macro}{'INSTMASTERS'} }) {
	$MAINLOG->infod("    Instance $instmaster ($dev_record{$macro}{'INSTMASTERS'}{$instmaster})");
      }
    }
  }
}

&SetHierUniqueDevices(\%dev_record, $cell_lc);
&SetHierFlatDevices(\%dev_record, $cell_lc);

if ($opt_debug) {
  foreach my $macro (sort keys %dev_record) {
    $MAINLOG->infod("Macro:$macro Devices:$dev_record{$macro}{'DEVICES'} Unique Devices:$dev_record{$macro}{'HIERDEV'} Unique Devices Not In STD Cells:$dev_record{$macro}{'CUSTOMHIERDEV'} Flat Devices:$dev_record{$macro}{'FLATDEV'} Flat Devices Not in STD Cells:$dev_record{$macro}{'CUSTOMFLATDEV'} ");
    if (defined $dev_record{$macro}{'INSTMASTERS'}) {
      foreach my $instmaster (sort keys %{ $dev_record{$macro}{'INSTMASTERS'} }) {
	$MAINLOG->infod("    Instance $instmaster ($dev_record{$macro}{'INSTMASTERS'}{$instmaster}) ($dev_record{$instmaster}{'HIERDEV'})  ($dev_record{$instmaster}{'CUSTOMHIERDEV'}) ($dev_record{$instmaster}{'FLATDEV'}) ($dev_record{$instmaster}{'CUSTOMFLATDEV'})");
      }
    }
  }
}

my @report_list;
my @csv_report_list;
&GenerateDevReport(\%dev_record, \%external_csv, \@external_csvfields, \@report_list, \@csv_report_list,  $cell_lc, 0, 1);

if ($opt_debug) {
  foreach my $line (@report_list) {
    $MAINLOG->infod($line);
  }
}

my $dev_report = "${WARD}/${BASEFILE}.report";
my $csv_report = "${WARD}/${BASEFILE}.report.csv";
open (DEVREPORT, ">$dev_report") or die $MAINLOG->fatalq("Could not open device report for writing: $dev_report");
open (CSVREPORT, ">$csv_report") or die $MAINLOG->fatalq("Could not open csv device report for writing: $csv_report");
print DEVREPORT "# (<instance count>) <cell> (<hierarchy level>) (<devices only in current hierarchy>) (<unique devices in hierarchy>) (<custom unique devices in hierarchy>) (<flat devices in hierarchy>) (<custom flat devices in hierarchy>)\n\n";
unless ($opt_nocsvheader) {
  my @csvfields = ("instance count", "cell", "hier level", "devices only in current hier", "unique devices in hierarchy");
  @csvfields = (@csvfields, "custom unique devices in hierarchy", "flat devices in hierarchy", "custom flat devices in hierarchy");
  if (exists $external_csv{$cell_lc}) {
    @csvfields = (@csvfields, @external_csvfields);
  }
  my $csvline = join(',', @csvfields);
  print CSVREPORT "$csvline\n";
}
foreach my $line (@report_list) {
  my $current_csv_record = shift(@csv_report_list);
  if (defined $opt_depth) {
    if ($line =~ /^\s*\(\d+\)\s+\S+\s+\((\d+)\)/) {
      my $depth = $1;
      if ($depth <= $opt_depth) {
	print DEVREPORT "$line\n";
	print CSVREPORT "$current_csv_record\n";
      }
    }
  } else {
    print DEVREPORT "$line\n";
    print CSVREPORT "$current_csv_record\n";
  }
}
close DEVREPORT;

&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");




##### Start subroutine definitions #####

sub RecompileDmspath {

  my $loghandle = shift;
  my $dbb = shift;
  my $model = shift;
  my $newdmsfile = shift;
  my $newcdsfile = shift;

  my $options_string = join(' ', @_);
  
  my $parent_flow = $loghandle->flowname('RecompileDmspath');

  # Add proper variable path
  $DBB = $dbb;
  $MODEL = $model;
  unless (&Tcsh($MAINLOG, "$DMSMODE > ${newdmsfile}.modes")) {
    die $loghandle->fatalq('DMSMODE generation returned non-zero exit status');
  }
  unless (&Tcsh($MAINLOG, "(dmsCompiler_new.pl -dbtypes lay sch flp dev sim net ctl -createDms2opus $newcdsfile -outfile $newdmsfile $options_string) >& /dev/null")) {
    die $loghandle->fatalq('DMSPATH recompilation for target cell returned non-zero exit status');
  }
  # Confirm existance of new file. Its non-existance is an unexpected condition.
  unless (-e $newdmsfile) {
    die $MAINLOG->fatalq("New dmspth file: $newdmsfile was not created properly for dbb $dbb");
  }
  $loghandle->flowname($parent_flow);
}


sub RunNikeNetlister {

  my $loghandle = shift;
  my $cell = shift;
  my $inputformat = shift;
  my $outputformat = shift;
  my $other_args = join(' ', @_);
  my $summary_found = 0;
  my $fatal_count;
  my $error_count;
  my $warning_count;
  my $run_is_dirty = 0;
  
  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname('RunNikeNetlister');
  
  # Remove previous netlist (future: key off of input format);
  my $outputformat_ucf = ucfirst($outputformat);
  
  my $netlist_dir;
  my $sn_dir;
  if ($other_args =~ /\-outd (\S+)/) {
    $netlist_dir = $1;
    $sn_dir = $1;
  } else {
    $netlist_dir = "$WARD/netlists";
    $sn_dir = "$WARD/netlists/cvssch";
  }
  
  my $outnetlistlog = "${netlist_dir}/${cell}__${inputformat}_to_${outputformat_ucf}__nike_netlister.log";
  my $outnetlist = "${sn_dir}/${cell}.sn";
  &DeleteFiles($outnetlist, $outnetlistlog);
  
  # Nike netlister returns non-zero status if there are non-fatal issues with netlisting, as wellas any process issues (like no disk space or wrong switches).
  # Since I don't know how to tell the difference, just check for the log file)
  unless (&Tcsh($loghandle, "$NIKE_NETLISTER -cell $cell -inf $inputformat -remp none -outf $outputformat $other_args >& /dev/null")) {
    $loghandle->warn('NIKE netlister call returned non-zero status.');
  }

  # Confirm there were no errors in the log file
  open (OUTNETLISTLOG, $outnetlistlog) or die $loghandle->fatalq("Could not open $outnetlistlog for reading");
  while (<OUTNETLISTLOG>) {
    if (/Fatals:\s+(\d+)\s+Errors:\s+(\d+)\s+Warnings:\s+(\d+)/) {
      $fatal_count = $1;
      $error_count = $2;
      $warning_count = $3;
      $summary_found = 1;
      chomp;
      $loghandle->infoq($_);
      last;
    }
  }
  close (OUTNETLISTLOG);

  if ($summary_found) {
    if (($fatal_count ne '0') or ($error_count ne '0')) {
      $loghandle->warnp("Fatals/errors occured during nike_netlister run.",
			"See $outnetlistlog");
      $run_is_dirty = 1;
    }
    if ($warning_count ne '0') {
      $loghandle->warnp("Warnings occured during nike_netlister run.",
			"See $outnetlistlog");
    }
  } else {
    die $loghandle->fatalq("Nike netlister log was found, but no summary was contained in file",
			   "See $outnetlistlog");
  }
  # Confirm output netlist was generated, die otherwise
  
  $loghandle->flowname($parent_flow);
  return $run_is_dirty;
}


sub SetHierUniqueDevices {

  my $dev_record_ref = shift;
  my $cell_lc = shift;

  unless (defined $$dev_record_ref{$cell_lc}{'HIERDEV'}) {
    if (defined $$dev_record_ref{$cell_lc}{'INSTMASTERS'}) {
      foreach my $macro (sort keys %{ $$dev_record_ref{$cell_lc}{'INSTMASTERS'} }) {
	&SetHierUniqueDevices($dev_record_ref, $macro);
	$$dev_record_ref{$cell_lc}{'HIERDEV'}+= $$dev_record_ref{$macro}{'HIERDEV'};
	$$dev_record_ref{$cell_lc}{'CUSTOMHIERDEV'}+= $$dev_record_ref{$macro}{'CUSTOMHIERDEV'};
      }
    }
    $$dev_record_ref{$cell_lc}{'HIERDEV'}+= $$dev_record_ref{$cell_lc}{'DEVICES'};
    if ($cell_lc =~ /^(yg)\S+$/) {
      $$dev_record_ref{$cell_lc}{'CUSTOMHIERDEV'}+= 0;
    } else {
      $$dev_record_ref{$cell_lc}{'CUSTOMHIERDEV'}+= $$dev_record_ref{$cell_lc}{'DEVICES'};
    }
  }				   
}


sub SetHierFlatDevices {

  my $dev_record_ref = shift;
  my $cell_lc = shift;

  unless (defined $$dev_record_ref{$cell_lc}{'FLATDEV'}) {
    if (defined $$dev_record_ref{$cell_lc}{'INSTMASTERS'}) {
      foreach my $macro (sort keys %{ $$dev_record_ref{$cell_lc}{'INSTMASTERS'} }) {
	&SetHierFlatDevices($dev_record_ref, $macro);
	$$dev_record_ref{$cell_lc}{'FLATDEV'}+= ($$dev_record_ref{$macro}{'FLATDEV'}*$$dev_record_ref{$cell_lc}{'INSTMASTERS'}{$macro});
	$$dev_record_ref{$cell_lc}{'CUSTOMFLATDEV'}+= ($$dev_record_ref{$macro}{'CUSTOMFLATDEV'}*$$dev_record_ref{$cell_lc}{'INSTMASTERS'}{$macro});
      }
    }
    $$dev_record_ref{$cell_lc}{'FLATDEV'}+= $$dev_record_ref{$cell_lc}{'DEVICES'};
    if ($cell_lc =~ /^(yg)\S+$/) {
      $$dev_record_ref{$cell_lc}{'CUSTOMFLATDEV'}+= 0;
    } else {
      $$dev_record_ref{$cell_lc}{'CUSTOMFLATDEV'}+= $$dev_record_ref{$cell_lc}{'DEVICES'};
    }
  }				   
}



sub GenerateDevReport {
  my $dev_record_ref = shift;
  my $external_csv_ref = shift;
  my $external_csvfields_ref = shift;
  my $report_list_ref = shift;
  my $csv_report_list_ref = shift;
  my $cell = shift;
  my $level = shift;
  my $instmasters = shift;
  my $spacer = '    ' x $level;
  my $csv_spacer = '-' x $level;

  my $line = sprintf "%-55s %4s %8s %10s %10s %10s %10s", "${spacer} (${instmasters}) $cell", "(${level})", "($$dev_record_ref{$cell}{'DEVICES'})", "($$dev_record_ref{$cell}{'HIERDEV'})", "($$dev_record_ref{$cell}{'CUSTOMHIERDEV'})", "($$dev_record_ref{$cell}{'FLATDEV'})", "($$dev_record_ref{$cell}{'CUSTOMFLATDEV'})";
  my $csv_record = join (',', $instmasters, "${spacer}${cell}", $level, $$dev_record_ref{$cell}{'DEVICES'}, $$dev_record_ref{$cell}{'HIERDEV'}, $$dev_record_ref{$cell}{'CUSTOMHIERDEV'}, $$dev_record_ref{$cell}{'FLATDEV'}, $$dev_record_ref{$cell}{'CUSTOMFLATDEV'});
  if (scalar @{$external_csvfields_ref}) {
    if (defined $$external_csv_ref{$cell}) {
      foreach my $field (@{$external_csvfields_ref}) {
	$csv_record .= ",$$external_csv_ref{$cell}{$field}";
      }
    } else {
      foreach my $field (@{$external_csvfields_ref}) {
	$csv_record .= ",";
      }
    }
  }   
  push (@{ $report_list_ref }, $line);
  push (@{ $csv_report_list_ref }, $csv_record);
  if (defined $$dev_record_ref{$cell}{'INSTMASTERS'}) {
    foreach my $macro (sort keys %{ $$dev_record_ref{$cell}{'INSTMASTERS'} }) {
      &GenerateDevReport($dev_record_ref, $external_csv_ref, $external_csvfields_ref, $report_list_ref, $csv_report_list_ref, $macro, $level+1, $$dev_record_ref{$cell}{'INSTMASTERS'}{$macro});
    }
  }
}

