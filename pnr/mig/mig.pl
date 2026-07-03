#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: mig.pl,v 1.18 2005/06/16 05:28:55 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: mig.pl,v 1.18 2005/06/16 05:28:55 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: mig.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

This script performs the following tasks on the input fub/cell:


=cut


# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
  if (defined $ENV{'MIG_OVR'}) {
    push @INC, $ENV{'MIG_OVR'};
  } else {
    push @INC, "/nfs/iil/disks/home10/mroha/pnr/mig", "/usr/users/home2/mroha/pnr/mig";
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
use Cwd;
use DAStdLib;
use MigStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();

my $mig_mode_string = join(' ', keys %mig_mode_table);

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cell <input cell> -mode <migration mode>
                  [-nofub <fub name for prefix>]
                  [-inputcif <input cif>]
                  [-help] [-verbose] [-debug]

flag descriptions:

-cell             Input cell name

-mode             Migration mode. Valid options: $mig_mode_string

-incif            Input CIF that will be copied to src area for migration run. If this
                  switch is not used, then it is assumed the source cif will be in
                  \$WORK_AREA_ROOT_DIR/mig/<cell>/src

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell fmmgend
         $EXE_NAME -cell tm0cmx05i5 -mode lib -incif \$WORK_AREA_ROOT_DIR/pds/stream/tm0cmx05i5.cif.1264

Files that result from this run:

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
our ($opt_cell, $opt_mode, $opt_incif);
my $options_ok = &GetOptions("help",
			     "debug",
			     "verbose",
			     "cell=s",
			     "mode=s",
			     "incif=s");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-cell');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

our ($WORK_AREA_ROOT_DIR);
&Env::import('WORK_AREA_ROOT_DIR');
unless ((defined $WORK_AREA_ROOT_DIR) and (-d $WORK_AREA_ROOT_DIR)) {
  $WORK_AREA_ROOT_DIR = cwd;
}
  
unless (defined $opt_mode) {
  $opt_mode = 'fub';
}

unless (exists $mig_mode_table{$opt_mode}) {
  die "-F- $EXE_NAME: -mode: $opt_mode not a valid option. Current -mode options: $mig_mode_string\n";
}


# Variables to start log file
my $cell_lc = lc($opt_cell);

our ($BASEFILE, $MAINLOG, $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${EXE_PREFIX}.${opt_mode}";
$MAINLOG = LogFile->new("${WARD}/${BASEFILE}.log");
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


# Initialize migration environment
my $stage = 1;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Initialize migration environment and directories *****");

my %mig_env_table;
$MAINLOG->info("-mode $opt_mode detected. Setting $opt_mode environment");
  
&ReadEnvironmentFile($MAINLOG, $mig_mode_table{$opt_mode}, \%mig_env_table);
my $force_set_env = 0;   # Want to use any mig env vars already set in environment
&SetEnvironment($MAINLOG, \%mig_env_table, $force_set_env, 1);  

my %mig_stage_hash;
foreach my $stage (@mig_stage_list) {
  $mig_stage_hash{$stage} = 1;
}

my $final_stage;
if ((exists $ENV{'MIG_END_STAGE'}) and ((exists $mig_stage_hash{$ENV{'MIG_END_STAGE'}}) or ($ENV{'MIG_END_STAGE'} eq 'lib'))) {
  $final_stage = $ENV{'MIG_END_STAGE'};
  $MAINLOG->infoq("The final expected data for migration mode ($opt_mode) will be from stage ($final_stage)");
} else {
  die $MAINLOG->fatalq("The env file for mode $opt_mode did not have MIG_END_STAGE set to a valid end stage");
}


$ENV{'name_prefix'} = 'xx';
$ENV{'fub'} = $cell_lc;

$MAINLOG->infoq("\$fub = $ENV{'fub'}\n");
$MAINLOG->infoq("\$name_prefix = $ENV{'name_prefix'}");

my $mig_ue_area = "$WORK_AREA_ROOT_DIR/mig";
my $mig_auxiliaries = "${mig_ue_area}/${cell_lc}/auxiliaries";
my $mig_src = "${mig_ue_area}/${cell_lc}/src";
my $mig_bin = "${mig_ue_area}/${cell_lc}/bin";
my $mig_setup = "${mig_ue_area}/${cell_lc}/setup";
my $mig_work;
if ($opt_mode eq '1265') {
  $mig_work = "${mig_ue_area}/${cell_lc}/work-${cell_lc}-harvest";
} else {
  $mig_work = "${mig_ue_area}/${cell_lc}/work-${cell_lc}";
}
&CreateDirTrees($mig_ue_area, $mig_auxiliaries, $mig_bin, $mig_setup, $mig_work, $mig_src);

$MAINLOG->info("Checking out RCS contents to bin area...");
&RcsCo($MAINLOG, $mig_bin, $mig_lookup{$SITE}{'rcsbin'}, $opt_debug);
$MAINLOG->info("Checking out RCS contents to setup area...");
&RcsCo($MAINLOG, $mig_setup, $mig_lookup{$SITE}{'rcssetup'}, $opt_debug);

# Search for override PDB files in users area and overwrite with existing files
$MAINLOG->infod("Searching for override PDB files...") if $opt_debug;

my %ovr_hash;
$ovr_hash{'setup'}{'source'} ="$HOME/setup_ovr";
$ovr_hash{'bin'}{'source'} = "$HOME/bin_ovr";
$ovr_hash{'setup'}{'target'} = $mig_setup;
$ovr_hash{'bin'}{'target'} = $mig_bin;
foreach my $area ('setup', 'bin') {
  if (-d $ovr_hash{$area}{'source'}) {
    opendir (OVR, $ovr_hash{$area}) or die $MAINLOG->fatalq("Could not open directory: $ovr_hash{$area}");
    my @override_files = grep /\w+\.\w+/, readdir(OVR);
    foreach my $file (@override_files) {
      &ManipFile($MAINLOG, 'copy', '', "$ovr_hash{$area}{'source'}/${file}", "$ovr_hash{$area}{'target'}/${file}");
      $MAINLOG->warn("Override file copied:", 
		     "Source: $ovr_hash{$area}{'source'}/${file}", 
		     "Target: $ovr_hash{$area}{'target'}/${file}");
    }
    closedir (OVR);
  }
}




my $input_cif = "${mig_src}/${cell_lc}.cif";

if ($opt_incif) {
  my ($name,$path,$suffix)  = fileparse($opt_incif);
  my $resolved_path = abs_path($path);
  my $resolved_incif = join('', "${resolved_path}/", $name);
  if (-f $resolved_incif) {
    if (-f $input_cif) {
      &ManipFile($MAINLOG, 'move',  $mig_src, $input_cif, basename($input_cif) . '.mig.bak');
    }
    &ManipFile($MAINLOG, 'copy', $mig_src, $resolved_incif, basename($resolved_incif));
    unless (basename($input_cif) eq basename($resolved_incif)) {
      &ManipFile($MAINLOG, 'symlink', $mig_src, basename($resolved_incif), basename($input_cif));
    }
    $MAINLOG->info("-incif switch detected. Using following CIF as input: $opt_incif");
  } else {
    die $MAINLOG->fatalq("-incif file does not exist: $opt_incif");
  }
}
					 

# Run Migration Flow
$stage++;
$MAINLOG->newline;
$MAINLOG->info("***** Stage $stage: Run migration flow *****");

chdir ("${mig_ue_area}/${cell_lc}") or die $MAINLOG->fatalq("Could not switch directory to mig work area: $mig_work");

my $mig_log;
my $mig_cmd;
my $run_ok;
my $intermediate_process_harvest_stm;
if ($opt_mode eq 'lib') {
  $mig_log = "${mig_work}/${cell_lc}.log";
  $mig_cmd = "${mig_bin}/runallLib.csh >& $mig_log";
  $run_ok = &Tcsh($MAINLOG, $mig_cmd);
}
elsif ($opt_mode eq '1265') {
  $intermediate_process_harvest_stm = "${mig_work}/work-fub_harvest${mig_intermediate_process}/${cell_lc}.stm.fub_harvest${mig_intermediate_process}";
  $mig_log = "${WARD}/${BASEFILE}.log";
  &DeleteFiles($intermediate_process_harvest_stm);
  $MAINLOG->infod("1265 mode detected: Linking PDB files to migration work area...") if $opt_debug;
  &ManipFile($MAINLOG, 'symlink', $mig_work, '../setup', 'setup');
  &ManipFile($MAINLOG, 'symlink', $mig_work, '../bin', 'bin');
  &ManipFile($MAINLOG, 'symlink', $mig_work, '../src', 'src');
  opendir (MIGSETUP, $mig_setup) or die $MAINLOG->fatalq("Could not open directory: $mig_setup");
  my @fub_pdb_files = grep /fub.+\.pdb/, readdir(MIGSETUP);
  closedir (MIGSETUP);
  foreach my $file (@fub_pdb_files) {
    &ManipFile($MAINLOG, 'symlink', $mig_work, "../setup/${file}", "$file");
  }
  &Harvest1265($MAINLOG, $mig_work, "fub_harvest${mig_intermediate_process}.pdb");
} else {
  $mig_log = "${mig_work}/${cell_lc}.log";
  $mig_cmd = "${mig_bin}/runall.csh >& $mig_log";
  $run_ok = &Tcsh($MAINLOG, $mig_cmd);
}


if (-f $mig_log) {
  open (MIGLOG, $mig_log) or die $MAINLOG->fatalq("Cound not open migration log for reading: $mig_log");
  while (<MIGLOG>) {
    if (/^\s*(\-)?E\-/) {
      chomp;
      $MAINLOG->errorq($_);
    }
    if (/Aborting|(^\s*(\-)?F\-)/) {
      chomp;
      $MAINLOG->error($_);
      $MAINLOG->error("Migration run contained a fatal in migration log, line $.");
      $run_ok = 0;
    }
  }
  close (MIGLOG);
}

unless ($run_ok) {
  die $MAINLOG->fatalq("Migration run failed. See log file: $mig_log");
}


my %mig_file_table;
&InitMigFileTable($cell_lc, '', \%mig_file_table, $final_stage => $WORK_AREA_ROOT_DIR);
if (exists $mig_file_table{$final_stage}) {
  foreach my $view ('resultcif', 'resultstm') {
    if (exists $mig_file_table{$final_stage}{$view}) {
      if (exists $mig_file_table{$final_stage}{$view}{'ward'}) {
	my $sourcedir = $mig_file_table{$final_stage}{$view}{'ward'}{'source'};
	opendir (SOURCE, $sourcedir) or die $MAINLOG->fatalq("Could not open dir for reading: $sourcedir");
	my @files = grep /$mig_file_table{$final_stage}{$view}{'ward'}{'filepattern'}/, readdir (SOURCE);
	if (scalar @files > 1) {
	  die $MAINLOG->fatalq("Files not expected in run: ".join(' ', @files));
	}
	elsif (scalar @files == 0) {
	  die $MAINLOG->fatalq("Output file not found:",
			       "DIR: $sourcedir",
			       "PATTERN: $mig_file_table{$final_stage}{$view}{'ward'}{'filepattern'}");
	} else {
	  $MAINLOG->infoq("Expected file found: ${sourcedir}/".join(' ', @files));
	}
      }
    }
  }
}

$MAINLOG->info("Migration log: $mig_log");

$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");


##### Start subroutine definitions #####






