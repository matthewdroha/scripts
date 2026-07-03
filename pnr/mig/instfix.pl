#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: instfix.pl,v 1.1 2007/09/13 18:01:03 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: instfix.pl,v 1.1 2007/09/13 18:01:03 mroha Exp $

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


    # Build the cleanup area that mkcif will collect from
    my $collect_lnf = "${WARD}/${release}/genesys/lnf";
    my $collect_stm = "${WARD}/${release}/pds/stream";
    my $collect_sn = "${WARD}/${release}/netlists/cvssch";
    &CreateDirTrees($collect_lnf, $collect_stm, $collect_sn);
    &ManipFile($MAINLOG, 'copy', $collect_stm, $stm_snapshot, basename($stm_snapshot));
    &ManipFile($MAINLOG, 'copy', $collect_sn, "${PDSSN}/${cell_lc}.sn", "${cell_lc}.sn");
    

    # Open Genesys session
    my $genesyslog = "${WARD}/${BASEFILE}.genesyslog";
    my $genesysfh = &GenesysOpenSession($genesyslog);
    
    # Preprocess LNF files
    my $readonly = 1;
    &GenesysOpenCell($cell_lc, 'lnf', '', $readonly, $genesysfh);
    &GenesysLoadModules(\@mig_tcl_modules_list, $genesysfh);

    &GenesysCommandLine($genesysfh, "::mig::i0plus $cell_lc");

    &GenesysSaveAllWithPrefix($cell_lc, 'lnf', '', $collect_lnf, $genesysfh);

    &GenesysCloseSession($genesysfh);
  }
}
    

$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete");
$MAINLOG->close;


########## Begin subroutine definitions ##########

sub GenesysOpenSession {

  my $genesyslog = shift;
  my $parentfh = select;  # Capture existing value
  my $genesys_cmd_line;

  local *GENESYSFH;

  $genesys_cmd_line = "$GENESYS_DIR/ConfigFiles/nike.wrapper $GENESYS_DIR/bin/genesys -nullgt";
  open (GENESYSFH, "| $genesys_cmd_line > $genesyslog 2>&1") or die
    $MAINLOG->fatalq("Could not open a pipe to Genesys");
  select(GENESYSFH);
  $| = 1;

  select($parentfh);
  return *GENESYSFH;
}

sub GenesysCloseSession {

  my $genesysfh = shift;
  my $parentfh = select($genesysfh);   

  print "quit\n";
  print "no\n";
  close ($genesysfh);
  select($parentfh);
}

sub GenesysOpenCell {

   my $cell = shift;
   my $view = shift;
   my $path = shift;
   my $readonly = shift;
   my $genesysfh = shift;
   my $parentfh = select($genesysfh);
   my $path_with_flag;

   if (-e $path) {
     $path_with_flag = "-path ${path}/${cell}.${view}";
   } else {
     $path_with_flag = "";
   }

   if ($readonly) {
     print "\nRead -cellname $cell -viewname $view $path_with_flag\n";
   } else {
     print "\nOpen -cellname $cell -viewname $view $path_with_flag\n";
     # Just in case you try to use this without having all the data in a local library
     # Never did figure out what -noask does...
     # Flag this when commands get wrapped
     print "no\n";
   }
   select($parentfh);
}


sub GenesysCommandLine {

  my $genesysfh = shift;
  my $genesys_command = shift;
  my $parentfh = select($genesysfh);

  print "\n$genesys_command\n";

  select($parentfh);
}


sub GenesysLoadModules {

  my $tcl_module_list_ref = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  my $tclfile;
  my $at_least_one_module_bad = 0;

  # Very dirty way for doing this right now...
  # Assume if the file exists it is OK
  foreach $tclfile (@{$tcl_module_list_ref}) {
    if (-e $tclfile) {
      print "source $tclfile\n";
    } else {
      $MAINLOG->fatalq("Could not load TCL module into Genesys:", $tclfile);
      my $at_least_one_module_bad = 1;
    }
  }
  if ($at_least_one_module_bad) {
    die $MAINLOG->fatalq("At least one TCL file not sourced properly into Genesys");
  }
  select($parentfh);
}


sub GenesysTouchAndWaitForFile {

   my $flagfile = shift;
   my $genesysfh = shift;
   my $parentfh = select($genesysfh);

   if (-e $flagfile) {
     die $MAINLOG->fatalq("Flagfile detected before polling started:", $flagfile);
   }
   print "exec touch $flagfile\n";
   &PollForFile($flagfile);

   select($parentfh);
}



sub GenesysSaveAllWithPrefix {

  my $cell = shift;
  my $view = shift;
  my $prefix = shift;
  my $outdir = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  my $dir;
  my $expected_outfile;
  my $saveall_flag = "${WARD}/genesys/${BASEFILE}.saveall_flag";
  my $prefix_with_flag;

  &DeleteFiles($saveall_flag);
  push (@TMPFILES, $saveall_flag);
  if (&CreateDirTrees($outdir)) {
    die $MAINLOG->fatalq("Could not create directory for lnf save:", $outdir);
  }
  
  if ($prefix) {
    $prefix_with_flag = "-prefix $prefix";
  } else {
    $prefix_with_flag = "";
  }
  print "\nSaveAll -cellname $cell -dir $outdir -targetview $view $prefix_with_flag\n";
  &GenesysTouchAndWaitForFile($saveall_flag, $genesysfh);
  $expected_outfile = "${outdir}/${prefix}${cell}.${view}";
  unless (-e $expected_outfile) {
    die $MAINLOG->fatalq("Genesys output not written out. Expected:", $expected_outfile);
  }

  select($parentfh);
}
