#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: drvupdate.pl,v 1.3 2005/05/04 13:20:45 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: drvupdate.pl,v 1.3 2005/05/04 13:20:45 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: sum2csv.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Parses PDS sum files and writes output to csv format. Also can
be used to filter results and write additional reports for
the filters

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
                   [-runcmp]
                   [-help] [-debug] [-verbose]

flag descriptions:

-cell             Target fub to re-run DRV statistics on. All migration
                  releases for this fub will be re-ran

-stage            stm and lnf from this stage will be taken from release area
                  Today, only 'finish' is supported.

-runcmp           In addition to other flows, run trcalt cmp on data

-reldir           Optional argument for override release area. Default
                  is to take input from official release area.

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -cell iecrud -stage finish

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
our ($opt_help, $opt_debug, $opt_verbose);
our ($opt_cell, $opt_reldir, $opt_stage, $opt_runcmp);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "stage=s",
			     "runcmp",
			     "reldir=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help;

my @required_flag_list = ('-cell', '-stage');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);

my @valid_stages = ('finish');
my $valid_regexp = join('|', @valid_stages);
unless ($opt_stage =~ /^(${valid_regexp})$/) {
  die "-F- $EXE_NAME: -stage must be one of the following: ". join(' ', @valid_stages). "\n";
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

my $cell_lc = lc($opt_cell);
our ($BASEFILE, $MAINLOG, $WARD);
$WARD = $WORK_AREA_ROOT_DIR;
$BASEFILE = "${cell_lc}.${EXE_PREFIX}.${opt_stage}";
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

my %release_lookup;
&GetMigReleaseStatus($MAINLOG, $release_area, \%release_lookup);

my $prep_dir;
if (exists $release_lookup{$cell_lc}) {  
  foreach my $release (sort @{ $release_lookup{$cell_lc} }) {
    my $stm = "${release_area}/${release}/stm/${cell_lc}.stm.${opt_stage}.${mig_output_process}";
    my $lnf_dir = "${release_area}/${release}/lnf/${cell_lc}_${opt_stage}_cleaned_lnf_${mig_output_process}";
    if ((-e $stm) and (-d $lnf_dir)) {
      $MAINLOG->info("Required LNF and STM files found.  Release:(${release})");
    }
    my $lnf_snapshot = "${WARD}/genesys/lnf/${release}_lnf_${mig_output_process}";
    &CreateDirTrees($lnf_snapshot);
    my $files_copied_count = &CopyFilesToDir($MAINLOG, '.lnf$', $lnf_dir, $lnf_snapshot);
    unless ($files_copied_count) {
      die $MAINLOG->fatalq("Could not copy LNF files to storage dir: $lnf_snapshot");
    }
    my $stm_snapshot = "${PDSSTM}/${cell_lc}.stm";
    &ManipFile($MAINLOG, 'copy', '', $stm, $stm_snapshot);

    if ($opt_runcmp) {
      my $sn_dir = "${release_area}/${release}/sn";
      my $sn_regex = '\.sn';
      
      opendir (SNDIR, $sn_dir) or die $MAINLOG->fatalq("Could not open sndir for reading: $sn_dir");
      my @sn_files = grep /${sn_regex}/, readdir (SNDIR);
      if (scalar @sn_files) {
	&ManipFile($MAINLOG, 'copy', '', "${sn_dir}/$sn_files[0]", "${PDSSN}/${cell_lc}.sn");
      } else {
	die $MAINLOG->fatalq("Should only match exactly 1 harvest SN file from release area");
      }
    }


    # Reset DMSPATH for ISS/Genesys to operate on private LNF area 
    open (DMSPATH, $DMSPATH) or die $MAINLOG->fatalq("Could not open $DMSPATH for reading");
    my $tempdms = "${WARD}/${BASEFILE}.${release}.dms.pth";
    open (TEMPDMS, ">$tempdms") or die $MAINLOG->fatalq("Could not open $tempdms for writing");
    my $tool_section = 0;
    while (<DMSPATH>) {
      if (/DMS PATH FOR TOOL:\s+(isstools|genesys)/) {
	$tool_section = 1;
      }
      if ($tool_section) {
	if (/\$WORK_AREA_ROOT_DIR\/genesys\/lnf/) {
	  s/\$WORK_AREA_ROOT_DIR\/genesys\/lnf/${lnf_snapshot}/;
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


    # Run DRC/Fillable on original STM used for PIE and cleaned LNF
    my $parent_flow;
  
    my $iss_header = "ISS DRCD (STM-Original)";
    $MAINLOG->info("Running $iss_header...");
    my $gdsintp = 0;
    my ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'drcd', '', $gdsintp);
    my $sumfile_string;
    if ($pds_sum_or_abort =~ /\.sum$/) {
      $sumfile_string = "-sumfile $pds_sum_or_abort ";
    }
    elsif ($pds_sum_or_abort =~ /\.abort$/) {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    } else {
      die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
    }

    $iss_header = "ISS FILLABLE (STM-Original)";
    $MAINLOG->info("Running $iss_header...");
    $gdsintp = 0;
    ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'fillable', '', $gdsintp);
    if ($pds_sum_or_abort =~ /\.sum$/) {
      $sumfile_string .= "-sumfile $pds_sum_or_abort ";
    }
    elsif ($pds_sum_or_abort =~ /\.abort$/) {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    } else {
      die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
    }

    if ($opt_runcmp) {
      $iss_header = "ISS TRCALT (STM-Original)";
      $MAINLOG->info("Running $iss_header...");
      $gdsintp = 0;
      ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'stm', 'trcalt', '', $gdsintp);
      if ($pds_sum_or_abort =~ /\.sum$/) {
	$sumfile_string .= "-sumfile $pds_sum_or_abort ";
      }
      elsif ($pds_sum_or_abort =~ /\.abort$/) {
	die $MAINLOG->fatalq("$iss_header run ABORTED");
      } else {
	die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
      }
    }


    &Tcsh($MAINLOG, "$mig_utils{$SITE}/sum2csv.pl -filtercsv $mig_utils{$SITE}/Migration_Runset_Table.csv $sumfile_string -sumre $cell_lc");
    
    my $filter_report = "${cell_lc}.sum2csv.report.${opt_stage}";
    unless (-e $filter_report) {
      die $MAINLOG->fatalq("ISS filter report was not generated: $filter_report");
    }
    
    $parent_flow = $MAINLOG->flowname('DRCSTAT-MIG (STM-Original)');

    &Pipe($MAINLOG, "$mig_utils{$SITE}/drcstat.pl $filter_report");
    $MAINLOG->flowname($parent_flow);
    
    my $stm_report = "${filter_report}.${EXE_PREFIX}.rawstm";
    &ManipFile($MAINLOG, 'move', '', $filter_report, $stm_report);
    
    
    $iss_header = "ISS DRCD (Cleaned LNF)";
    $MAINLOG->info("Running $iss_header...");
    $gdsintp = 0;
    ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'lnf', 'drcd', '', $gdsintp);
    if ($pds_sum_or_abort =~ /\.sum$/) {
      $sumfile_string = "-sumfile $pds_sum_or_abort ";
    }
    elsif ($pds_sum_or_abort =~ /\.abort$/) {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    } else {
      die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
    }
    
    $iss_header = "ISS FILLABLE (Cleaned LNF)";
    $MAINLOG->info("Running $iss_header...");
    $gdsintp = 0;
    ($rundirty, $pds_sum_or_abort) = &RunISS($MAINLOG, $opt_debug, $cell_lc, 'lnf', 'fillable', '', $gdsintp);
    if ($pds_sum_or_abort =~ /\.sum$/) {
      $sumfile_string .= "-sumfile $pds_sum_or_abort ";
    }
    elsif ($pds_sum_or_abort =~ /\.abort$/) {
      die $MAINLOG->fatalq("$iss_header run ABORTED");
    } else {
      die $MAINLOG->fatalq("Neither sum nor abort file returned by ISS: $pds_sum_or_abort");
    }
    
    &Tcsh($MAINLOG, "$mig_utils{$SITE}/sum2csv.pl -filtercsv $mig_utils{$SITE}/Migration_Runset_Table.csv $sumfile_string -sumre $cell_lc");
    
    unless (-e $filter_report) {
      die $MAINLOG->fatalq("ISS filter report was not generated: $filter_report");
    }
    
    $parent_flow = $MAINLOG->flowname('DRCSTAT-MIG (LNF)');
    &Pipe($MAINLOG, "$mig_utils{$SITE}/drcstat.pl $filter_report");
    $MAINLOG->flowname($parent_flow);
    my $lnf_report = "${filter_report}.${EXE_PREFIX}.lnf";
    &ManipFile($MAINLOG, 'move', '', $filter_report, $lnf_report);

    
    $filter_report = "${cell_lc}.sum2csv.report.penryn_finish";
    $parent_flow = $MAINLOG->flowname('DRCSTAT-PENRYN (LNF)');
    &Pipe($MAINLOG, "$mig_utils{$SITE}/drcstat.pl $filter_report");
    $MAINLOG->flowname($parent_flow);

    $prep_dir = "${release}/logs";
    &CreateDirTrees($prep_dir);
    &ManipFile($MAINLOG, 'copy', $prep_dir, "${WARD}/$stm_report", basename($stm_report));
    &ManipFile($MAINLOG, 'copy', $prep_dir, "${WARD}/$lnf_report", basename($lnf_report));
  }
}
    
  

$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete");
$MAINLOG->close;

system ("cp ${WARD}/${BASEFILE}.log ${prep_dir}/${BASEFILE}.log");


########## Begin subroutine definitions ##########

