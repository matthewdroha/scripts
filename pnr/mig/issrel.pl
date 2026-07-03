#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: issrel.pl,v 1.2 2005/05/05 10:26:12 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: issrel.pl,v 1.2 2005/05/05 10:26:12 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: issrel.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Runs the provided runset on the provided release on the provided datatype

=cut

# Will redefine when we get a permanant UE friendly setup for 1266 and migration
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
use PdsStdLib;
use MigStdLib;


my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();


my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME  -cell <released cell name>
                   -stage <target release stage>
                   [-reldir <specific release directory>]
                   [-help] [-debug] [-verbose]

flag descriptions:

-cell             Cell to run. Latest release for this cell will be used. If an override
                  is required, then link to target release in different dir and use
                  -reldir

-stage            stm and lnf from this stage will be taken from release area
                  Supported stages are siclone, gridding, finish. If not specified,
                  data from the latest flow stage will be taken (i.e. finish
                  before gridding, etc...)

-flows            PDS flows to run on data. You can specify multiple flow switches

-format           rawstm, cleanedstm, or lnf. rawstm is used as input to PIE
                  cleaned stm is the stm prepped for the next stage and may
                  have non-drc compliant geometries

-reldir           Optional argument for override release area. Default
                  is to take input from official release area.

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell iecrud -stage finish -format rawstm -flows drcd -flows fillable

Files that result from this run:

Standard ISS files

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_help, $opt_debug, $opt_verbose);
our ($opt_cell, $opt_reldir, $opt_stage, $opt_format, @opt_flows);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "stage=s",
			     "flows=s@",
			     "format=s",
			     "reldir=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help;

my @required_flag_list = ('-cell', '-format', '-flows');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

my $valid_regexp = join('|', @mig_stage_list);
if (defined $opt_stage) {
  unless ($opt_stage =~ /^(${valid_regexp})$/) {
    die "-F- $EXE_NAME: -stage must be one of the following: ". join(' ', @mig_stage_list). "\n";
  }
}

my @valid_format_list = ('rawstm', 'cleanedstm', 'lnf');
$valid_regexp = join('|', @valid_format_list);
unless ($opt_format =~ /^(${valid_regexp})$/) {
  die "-F- $EXE_NAME: -format must be one of the following: ". join(' ', @valid_format_list). "\n";
}


##### Main Program #####

our ($WORK_AREA_ROOT_DIR, $DMSPATH);
my @env_list = ('WORK_AREA_ROOT_DIR', 'DMSPATH');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


my $flow_string = join('_', @opt_flows);
my $cell_lc = lc($opt_cell);
our ($BASEFILE, $MAINLOG, $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${EXE_PREFIX}.${opt_format}.${flow_string}";
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


my $release_area;
if ((defined $opt_reldir) and (-d $opt_reldir)) {
  $release_area = $opt_reldir;
} else {
  $release_area = "$mig_lookup{$SITE}{'release'}/idc";
}


# See what has been released. If there is more than one release for a fub, take the latest one
my %release_lookup;
&GetMigReleaseStatus($MAINLOG, $release_area, \%release_lookup);

my $target_release;
if ((exists $release_lookup{$cell_lc}) and (scalar @{ $release_lookup{$cell_lc} })) {
  my @sorted_releases = sort @{ $release_lookup{$cell_lc} };
  $target_release = pop(@sorted_releases);
} else {
  die $MAINLOG->fatalq("No releases found for cell: $cell_lc in release area $release_area");
}

$MAINLOG->infoq("Release selected: (${release_area}/${target_release})");


# Within the chosen release, take the data from the best stage of migration
my $target_stage = '';
if ($opt_stage) {
  $target_stage = $opt_stage;
} else {
  my $lnf_release_area = "${release_area}/${target_release}/lnf";
  opendir (LNFREL, $lnf_release_area) or die $MAINLOG->fatalq("Could not open lnf release area: $lnf_release_area");
  my @dirs = readdir(LNFREL);
STAGESEARCH: foreach my $stage (reverse @mig_stage_list) {
    foreach my $dir (@dirs) {
      if ($dir =~ /_${stage}_/) {
	$target_stage = $stage;
	last STAGESEARCH;
      }
    }
  }
  closedir (LNFREL);
}

unless ($target_stage) {
  die $MAINLOG->fatalq("Could not find stage for cell $cell_lc in $target_release");
}
$MAINLOG->infoq("Stage selected: ($target_stage)");



# Grab the data from the release area and place in the work area
my %mig_file_table;
&InitMigFileTable($cell_lc, $WARD, \%mig_file_table, $target_stage => "${release_area}/${target_release}");

my $view = $opt_format;

&CreateDirTrees($mig_file_table{$target_stage}{$view}{'ward'}{'target'});
unless ((exists $mig_file_table{$target_stage}{$view}{'ward'}{'namematch'}) and (exists $mig_file_table{$target_stage}{$view}{'ward'}{'namereplace'})) {
  $mig_file_table{$target_stage}{$view}{'ward'}{'namematch'} = '';
  $mig_file_table{$target_stage}{$view}{'ward'}{'namereplace'} = '';
}
my @files = &CopyFilesToDir($MAINLOG, $mig_file_table{$target_stage}{$view}{'arch'}{'filepattern'}, $mig_file_table{$target_stage}{$view}{'arch'}{'source'}, $mig_file_table{$target_stage}{$view}{'ward'}{'target'}, $mig_file_table{$target_stage}{$view}{'ward'}{'namematch'}, $mig_file_table{$target_stage}{$view}{'ward'}{'namereplace'});

if (scalar @files) {
  if ($view =~ /rawstm|cleanedstm/) {
    my $stmfile = pop(@files);
    &ManipFile($MAINLOG, 'symlink', $mig_file_table{$target_stage}{$view}{'ward'}{'target'}, $stmfile, "${cell_lc}.stm");
  }
} else {
  die $MAINLOG->fatalq("No input files were copied from the release area");
}
  

if ($view eq 'lnf') {
  # Reset DMSPATH for ISS/Genesys to operate on private LNF area 
  open (DMSPATH, $DMSPATH) or die $MAINLOG->fatalq("Could not open $DMSPATH for reading");
  my $tempdms = "${WARD}/${BASEFILE}.${target_release}.dms.pth";
  open (TEMPDMS, ">$tempdms") or die $MAINLOG->fatalq("Could not open $tempdms for writing");
  my $tool_section = 0;
  while (<DMSPATH>) {
    if (/DMS PATH FOR TOOL:\s+(isstools|genesys)/) {
      $tool_section = 1;
    }
    if ($tool_section) {
      if (/\$WORK_AREA_ROOT_DIR\/genesys\/lnf/) {
	s/\$WORK_AREA_ROOT_DIR\/genesys\/lnf/$mig_file_table{$target_stage}{'lnf'}{'ward'}{'target'}/;
      }
      if (/libpath/) {
	$tool_section = 0;
      }
    }
    print TEMPDMS $_;
  }
  close (DMSPATH);
  close (TEMPDMS);
  $DMSPATH = $tempdms;
}

my $issview;
if ($view =~ /stm/) {
  $issview = 'stm';
} else {
  $issview = $view;
}
# Run the specified flows on the data
foreach my $flow (@opt_flows) {
  my $iss_header = "ISS $flow (Viewtype $view)";
  $MAINLOG->info("Running $iss_header...");
  my $gdsintp = 0;
  my ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, $issview, $flow, '', $gdsintp);
  my $sumfile_string;
  if ($pds_sum_or_abort =~ /\.sum$/) {
    $sumfile_string = "-sumfile $pds_sum_or_abort ";
  }
  elsif ($pds_sum_or_abort =~ /\.abort$/) {
    die $MAINLOG->fatalq("$iss_header run ABORTED");
  } else {
    die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
  }
}


$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete for cell: $cell_lc ($target_stage)");
$MAINLOG->close;


########## Begin subroutine definitions ##########

