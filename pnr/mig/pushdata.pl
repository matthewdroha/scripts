#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: pushdata.pl,v 1.13 2005/04/29 15:24:05 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: pushdata.pl,v 1.13 2005/04/29 15:24:05 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: pushdata.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Collects run data from harvest and/or mkcif and copies it into
an area that is prepared for release

=cut

BEGIN {
  if (defined $ENV{'MIG_OVR'}) {
    push @INC, $ENV{'MIG_OVR'};
  } else {
    push @INC, '/nfs/iil/disks/home10/mroha/pnr/mig', '/usr/users/home2/mroha/pnr/mig';
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
use MigStdLib;


my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = &GetDate();


# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -harvestdir <harvest run directory>
                  -siclonedir <siclone mkcif run dir>
                  -griddingdir <gridding mkcif run dir>
                  -finishdir <finish mkcif run dir>
                  -harvestarch <harvest archive dir>
                  -libdir <library run dir>
                  -model <output model name for mig archive area>  
                  [-cell <cell name>]
                  [-help] [-debug] [-verbose]

flag descriptions:

-harvestdir       Directory of harvest run (must contain *harvest.log files)

-siclonedir       Directory of post mkcif.pl LNF->CIF prep for post siclone data

-griddingdir      Directory of post mkcif.pl LNF->CIF prep for post gridding data

-finishdir        Directory of post mkcif.pl LNF->CIF prep for post finish data

-harvestarch      Directory containing harvest data in release structure

-libdir           Directory of post library migration run

-model            Model name for this run

-cell             Operate only on specified cell. If not specified then
                  all valid harvest.log files will be operated on

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -harvestdir \$WORK_AREA_ROOT_DIR -model 2005_01_01_mrm_lor2

Files that result from this run:



EOD

my $options_ok = 1;

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
our ($opt_harvestdir, $opt_siclonedir, $opt_griddingdir, $opt_model, $opt_cell, $opt_libdir, $opt_finishdir);
our ($opt_harvestarch);
$options_ok = &GetOptions("help",
			  "harvestdir=s",
			  "harvestarch=s",
			  "siclonedir=s",
			  "griddingdir=s",
			  "finishdir=s",
			  "libdir=s",
			  "model=s",
			  "cell=s",
			  "debug",
			  "verbose");


# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-model');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

if ($opt_harvestdir and $opt_harvestarch) {
  die "-F- $EXE_NAME: Can not use both -harvestdir and -harvestarch switches\n";
}


##### Main Program #####


# Variables

my $cell_lc;
if ($opt_cell) {
  $cell_lc = lc($opt_cell);
} else {
  unless ((defined ($opt_harvestdir) or defined ($opt_harvestarch))) {
    die "-F- $EXE_NAME: Must specify -harvestdir if -cell is not being used\n";
  }
  $cell_lc = '';
}

our ($BASEFILE, $MAINLOG);
if ($cell_lc) {
  $BASEFILE = "${cell_lc}.${EXE_PREFIX}";
} else {
  $BASEFILE = "${EXE_PREFIX}";
}
$MAINLOG = LogFile->new("${BASEFILE}.log");
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


my $harvestdir;
if (defined $opt_harvestdir) {
  unless (-d $opt_harvestdir) {
    die $MAINLOG->fatalq("Harvest directory not accessable: $opt_harvestdir");
  }
  $harvestdir = abs_path($opt_harvestdir);
  $MAINLOG->info("Resolved harvest dir path to: $harvestdir");
}

my $harvestarch;
if (defined $opt_harvestarch) {
  unless (-d $opt_harvestarch) {
    die $MAINLOG->fatalq("Harvest archive directory not accessable: $opt_harvestarch");
  }
  $harvestarch = abs_path($opt_harvestarch);
  $MAINLOG->info("Resolved harvest archive path to: $harvestarch");
}

my $siclonedir;
if (defined $opt_siclonedir) {
  unless (-d $opt_siclonedir) {
    die $MAINLOG->fatalq("Siclone directory not accessible: $opt_siclonedir");
  }
  $siclonedir = abs_path($opt_siclonedir);
  $MAINLOG->info("Resolved siclone mkcif dir path to: $siclonedir");
}


my $griddingdir;
if (defined $opt_griddingdir) {
  unless (-d $opt_griddingdir) {
    die $MAINLOG->fatalq("Gridding directory not accessible: $opt_griddingdir");
  }
  $griddingdir = abs_path($opt_griddingdir);
  $MAINLOG->info("Resolved gridding mkcif dir path to: $griddingdir");
}


my $finishdir;
if (defined $opt_finishdir) {
  unless (-d $opt_finishdir) {
    die $MAINLOG->fatalq("Finish directory not accessible: $opt_finishdir");
  }
  $finishdir = abs_path($opt_finishdir);
  $MAINLOG->info("Resolved finish mkcif dir path to: $finishdir");
}


my $libdir;
if (defined $opt_libdir) {
  unless (-d $opt_libdir) {
    die $MAINLOG->fatalq("Library run directory not accessible: $opt_libdir");
  }
  $libdir = abs_path($opt_libdir);
  $MAINLOG->info("Resolved library  dir path to: $libdir");
}

unless ($opt_model =~ /\w/) {
  die $MAINLOG->fatalq("Invalid model name. Must contain alphanumeric characters: $opt_model");
}


my @potentials_list;
if ($cell_lc) {
  push @potentials_list, $cell_lc;
} 
# else key off of harvest logs
elsif ($harvestdir) {
  opendir (HARVESTDIR, $harvestdir) or die $MAINLOG->fatalq("Could not open dir for reading: $opt_harvestdir");
  my @harvest_logs = grep /harvest\.log$/, readdir(HARVESTDIR);
  foreach my $file (@harvest_logs) {
    my $cell = $file;
    $cell =~ s/\.harvest\.log//;
    push (@potentials_list, $cell);
  }
}
elsif ($harvestarch) {
  opendir (HARVESTARCH, $harvestarch) or die $MAINLOG->fatalq("Could not open dir for reading: $opt_harvestarch");
  my @harvest_logs = grep /harvest\.log$/, readdir(HARVESTARCH);
  foreach my $file (@harvest_logs) {
    my $cell = $file;
    $cell =~ s/\.harvest\.log//;
    push (@potentials_list, $cell);
  }
  closedir (HARVESTARCH);
}
# else key off of siclone mkcif logs
elsif ($siclonedir) {
  opendir (SICLONEDIR, $siclonedir) or die $MAINLOG->fatalq("Could not open dir for reading: $opt_siclonedir");
  my @siclone_logs = grep /mkcif\.siclone\.log$/, readdir(SICLONEDIR);
  foreach my $file (@siclone_logs) {
    my $cell = $file;
    $cell =~ s/\.mkcif\.siclone\.log$//;
    push (@potentials_list, $cell);
  }
}
# else key off of gridding mkcif logs
elsif ($griddingdir) {
  opendir (GRIDDINGDIR, $griddingdir) or die $MAINLOG->fatalq("Could not open dir for reading: $opt_griddingdir");
  my @gridding_logs = grep /mkcif\.gridding\.log$/, readdir(GRIDDINGDIR);
  foreach my $file (@gridding_logs) {
    my $cell = $file;
    $cell =~ s/\.mkcif\.gridding\.log$//;
    push (@potentials_list, $cell);
  }
}
elsif ($finishdir) {
  opendir (FINISHDIR, $finishdir) or die $MAINLOG->fatalq("Could not open dir for reading: $opt_finishdir");
  my @finish_logs = grep /mkcif\.finish\.log$/, readdir(FINISHDIR);
  foreach my $file (@finish_logs) {
    my $cell = $file;
    $cell =~ s/\.mkcif\.finish\.log$//;
    push (@potentials_list, $cell);
  }
}
# else key off of library logs
elsif ($libdir) {
  opendir (LIBDIR, $libdir) or die $MAINLOG->fatalq("Could not open dir for reading: $opt_libdir");
  my @lib_logs = grep /mig\.lib\.log$/, readdir(LIBDIR);
  foreach my $file (@lib_logs) {
    my $cell = $file;
    $cell =~ s/\.mig\.lib\.log$//;
    push (@potentials_list, $cell);
  }
}


if ($opt_debug) {
  foreach my $potential (sort @potentials_list) {
    $MAINLOG->infod("Log file exists: $potential");
  }
  my $potential_count = scalar (@potentials_list);
  $MAINLOG->infod("Number of harvest/mkcif log files found: $potential_count");
}


my @cell_list;
if ($harvestdir) {
  foreach my $cell (@potentials_list) {
    my $harvestlog ="${harvestdir}/${cell}.harvest.log";
    open (HARVESTLOG, $harvestlog) or die $MAINLOG->fatalq("Could not open log file for reading: $harvestlog");
    while (<HARVESTLOG>) {
      if (/run complete for cell: (\S+)/) {
	push (@cell_list, $1);
      }
    }
    close (HARVESTLOG);
  }
}
elsif ($harvestarch) {
  foreach my $cell (@potentials_list) {
    my $harvestarch ="${harvestarch}/logs/${cell}.harvest.log";
    open (HARVESTARCH, $harvestarch) or die $MAINLOG->fatalq("Could not open log file for reading: $harvestarch");
    while (<HARVESTARCH>) {
      if (/run complete for cell: (\S+)/) {
	push (@cell_list, $1);
      }
    }
    close (HARVESTARCH);
  }
}
elsif ($siclonedir) {
  foreach my $cell (@potentials_list) {
    my $siclonelog ="${siclonedir}/${cell}.mkcif.siclone.log";
    open (SICLONELOG, $siclonelog) or die $MAINLOG->fatalq("Could not open log file for reading: $siclonelog");
    while (<SICLONELOG>) {
      if (/run complete for cell: (\S+)/) {
	push (@cell_list, $1);
      }
    }
    close (SICLONELOG);
  }
}
elsif ($griddingdir) {
  foreach my $cell (@potentials_list) {
    my $griddinglog ="${griddingdir}/${cell}.mkcif.gridding.log";
    open (GRIDDINGLOG, $griddinglog) or die $MAINLOG->fatalq("Could not open log file for reading: $griddinglog");
    while (<GRIDDINGLOG>) {
      if (/run complete for cell: (\S+)/) {
	push (@cell_list, $1);
      }
    }
    close (GRIDDINGLOG);
  }
}
elsif ($finishdir) {
  foreach my $cell (@potentials_list) {
    my $finishlog ="${finishdir}/${cell}.mkcif.finish.log";
    open (FINISHLOG, $finishlog) or die $MAINLOG->fatalq("Could not open log file for reading: $finishlog");
    while (<FINISHLOG>) {
      if (/run complete for cell: (\S+)/) {
	push (@cell_list, $1);
      }
    }
    close (FINISHLOG);
  }
}
elsif ($libdir) {
  foreach my $cell (@potentials_list) {
    my $liblog ="${griddingdir}/${cell}.mig.lib.log";
    open (LIBLOG, $liblog) or die $MAINLOG->fatalq("Could not open log file for reading: $liblog");
    while (<LIBLOG>) {
      if (/run complete for cell: (\S+)/) {
	push (@cell_list, $1);
      }
    }
    close (LIBLOG);
  }
}

    
my $good_log_count = scalar @cell_list;
if ($good_log_count) {
  $MAINLOG->info("Number of logs with a completed run: $good_log_count");
} else {
  die $MAINLOG->fatalq("No log files found with completed run");
}



my %source_table;
foreach my $stage (@mig_stage_list, 'lib') {
  $source_table{$stage} = 'ward';
}

my @stage_dirs = ();

if ($harvestdir) {
  push @stage_dirs, harvest => $harvestdir;
}
elsif ($harvestarch) {
  push @stage_dirs, harvest => $harvestarch;
  $source_table{'harvest'} = 'arch';
}
if ($siclonedir) {
  push @stage_dirs, siclone => $siclonedir;
}
if ($griddingdir) {
  push @stage_dirs, gridding => $griddingdir;
}
if ($finishdir) {
  push @stage_dirs, finish => $finishdir;
}
if ($libdir) {
  push @stage_dirs, lib => $libdir;
}




foreach my $cell (sort @cell_list) {

  my %mig_file_table;

  $MAINLOG->info("Collecting data for cell: ${cell}...");

  &InitMigFileTable($cell, $opt_model, \%mig_file_table, @stage_dirs);


  # Confirm the mig table conforms to the rules set forth

  foreach my $stage (sort keys %mig_file_table) {
    foreach my $view (keys %{ $mig_file_table{$stage} }) {
      if (exists $mig_file_table{$stage}{$view}{'ward'}{'noarchive'}) {
	next;
      }
      foreach my $dirtype ('ward', 'arch') {
	unless (exists $mig_file_table{$stage}{$view}{$dirtype}) {
	  die $MAINLOG->fatalq("Error in definition for mig_file_table: Missing entry for stage: $stage view: $view dirtype: $dirtype");
	}
	foreach my $origin ('source', 'target', 'filepattern') {
	  unless (exists $mig_file_table{$stage}{$view}{$dirtype}{$origin}) {
	    die $MAINLOG->fatalq("Error in definition for mig_file_table: Missing entry for stage: $stage view: $view dirtype: $dirtype origin: $origin");
	  }
	}
      }
      unless ((exists $mig_file_table{$stage}{$view}{'ward'}{'namematch'}) and (exists $mig_file_table{$stage}{$view}{'ward'}{'namereplace'})) {
	$mig_file_table{$stage}{$view}{'ward'}{'namematch'} = '';
	$mig_file_table{$stage}{$view}{'ward'}{'namereplace'} = '';
      }
    }
  }

  foreach my $stage (keys %mig_file_table) {
    foreach my $view (keys %{ $mig_file_table{$stage} }) {
      if (exists $mig_file_table{$stage}{$view}{'arch'}) {
	if (exists $mig_file_table{$stage}{$view}{'arch'}{'target'}) {
	  &CreateDirTrees($mig_file_table{$stage}{$view}{'arch'}{'target'});
	}
      }
    }
  }
  

  foreach my $stage (sort keys %mig_file_table) {
    foreach my $view (keys %{ $mig_file_table{$stage} }) {
      if (exists $mig_file_table{$stage}{$view}{'ward'}{'noarchive'}) {
	next;
      } 
      unless (-d $mig_file_table{$stage}{$view}{$source_table{$stage}}{'source'}) {
	$MAINLOG->warnp("Source directory not found: $mig_file_table{$stage}{$view}{$source_table{$stage}}{'source'}");
	next;
      }
      my @files_copied = &CopyFilesToDir($MAINLOG, $mig_file_table{$stage}{$view}{$source_table{$stage}}{'filepattern'}, $mig_file_table{$stage}{$view}{$source_table{$stage}}{'source'}, $mig_file_table{$stage}{$view}{'arch'}{'target'}, $mig_file_table{$stage}{$view}{'ward'}{'namematch'}, $mig_file_table{$stage}{$view}{'ward'}{'namereplace'});
      my @info_list = ("REGEXP: $mig_file_table{$stage}{$view}{$source_table{$stage}}{'filepattern'}" ,
		       "SOURCE: $mig_file_table{$stage}{$view}{$source_table{$stage}}{'source'}",
		       "DESTINATION: $mig_file_table{$stage}{$view}{'arch'}{'target'}",
		       "FILE NAME MATCH: $mig_file_table{$stage}{$view}{'ward'}{'namematch'}",
		       "FILE NAME REPLACE: $mig_file_table{$stage}{$view}{'ward'}{'namereplace'}");
      if (scalar @files_copied) {
	$MAINLOG->infoq(scalar @files_copied . 'files_copied files copied:', @info_list);
      } else {
	$MAINLOG->warnp("Had issues with copying data:", @info_list);
      }
    }
  }
 
  
  if ($harvestdir or $harvestarch) {
    
    my $model_sn_dir = $mig_file_table{'harvest'}{'sn'}{'arch'}{'target'};
    
    opendir (MODELSN, $model_sn_dir) or die $MAINLOG->fatalq("Could not open sn directory: $model_sn_dir");
    my ($harvest_sn) = grep /\.nobonus\.${mig_input_process}$/, readdir(MODELSN);
    rewinddir(MODELSN);
    my ($siclone_sn) = grep /\.siclone\.cleaned\.${mig_input_process}$/, readdir(MODELSN);
    rewinddir(MODELSN);
    my ($gridding_sn) = grep /\.gridding\.cleaned\.${mig_input_process}$/, readdir(MODELSN);
    rewinddir(MODELSN);
    my ($finish_sn) = grep /\.finish\.cleaned\.${mig_input_process}$/, readdir(MODELSN);
    closedir (MODELSN);
      
    if (defined($harvest_sn)) {
      my @target_sn_list;
      if (defined($siclone_sn)) {
	push (@target_sn_list, $siclone_sn);
      }
      if (defined($gridding_sn)) {
	push (@target_sn_list, $gridding_sn);
      }	
      if (defined($finish_sn)) {
	push (@target_sn_list, $finish_sn);
      }	
      if (scalar @target_sn_list) {
	foreach my $target_sn (@target_sn_list) {
	  my $diffs_found = 0;
	  my $cmd = "/usr/bin/diff ${model_sn_dir}/${harvest_sn} ${model_sn_dir}/${target_sn}";
	  $MAINLOG->infoq("Running command: $cmd");
	  open (DIFFPIPE, "$cmd  2>&1 |") or die $MAINLOG->fatalq("Could not open pipe to /usr/bin/diff");
	  while (<DIFFPIPE>) {
	    chomp;
	    if (/\w/) {
	      $diffs_found = 1;
	      $MAINLOG->warnq("SN DIFF: $_");
	    }
	  }
	  close (DIFFPIPE);
	  if ($diffs_found) {
	    $MAINLOG->warnp("Differences found between harvest SN file and the cleaned SN for cell: $target_sn");
	  } else {
	    &DeleteFiles("${model_sn_dir}/${target_sn}");
	  }
	}
      } else {
	$MAINLOG->warnp("SN diff not ran because no post cleaned SNs present. See previous warnings in log file");
      }
    }
  }
}


$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
if ($cell_lc) {
  $MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc");
}


exit 1;



# Build model directories in archive area (set to mig_da)
# Copy files to new area, use 775



########## Begin subroutine definitions ##########











