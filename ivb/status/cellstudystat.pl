#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: cellstudystat.pl,v 1.1 2010/01/08 19:57:32 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: cellstudystat.pl,v 1.1 2010/01/08 19:57:32 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: cellstudystat.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: 

Analyzes all ai0 cells installed in study lib and generates report on scaling

=cut

BEGIN {
  use IO::Dir;
  my $homeproject = 'ivb';
  my %homedir;
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'EC_SITE'}) {
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new;
    $dir->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $dir->read();
    if (-d "$ENV{'HOME'}/ovrd") {
      push @INC, "$ENV{'HOME'}/ovrd";
    }
    foreach my $item (@dirs) {
      if (-d "${code_dir}/${item}") {
	push @INC, "${code_dir}/${item}";
      }
    } 
  } else {
    die "Environment var EC_SITE is not defined. Please make your environment eclogin compliant\n";
  } 
}


use strict;
use warnings;
use English;
use IO::File;
use IO::Dir;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';
use DAStd;
use UE;
use Genesys;
use Logfile;
use Netbatch;

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
usage:  $exe_name [--help] [--verbose] [--debug]

flag descriptions:

--debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

--verbose          Will add status messages to STDOUT.

--help             This usage message will appear. 


example: $exe_name

Files that result from this run:

${exe_name}.studylib.csv
${exe_name}.sourcecompare.csv

EOD


# Get command line options. GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our (@opt_env);
our ($opt_debug, $opt_verbose, $opt_help);
my $options_ok = GetOptions("help",
			    "debug",
			    "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use -help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ();
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####


# Capture initial environment variables
our ($HOME, $USER);
my @env_list = ('HOME', 'USER');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


our ($basefile, $logfh);
$basefile = "${exe_prefix}";
$logfh = Logfile->new("${basefile}.log");
$logfh->flowname($exe_name);
$logfh->verbose($opt_verbose);
$logfh->debug($opt_debug);

my $machine_info = `uname -a`;
chomp $machine_info;
$logfh->info("Script command: $exe_name $command_line");
$logfh->info("Script start date: $start_date");
$logfh->info("Machine Type: $machine_info");

# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @tmplist = ();

# Set any command line env vars
if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $logfh->infoq("-env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $logfh->fatalq("Invalid value for switch -env: $setting");
    }
  }
}

my $home_area = "/usr/users/home2/mroha/cellstudystat";

# Master field list
my %cell_table;
my %source_table;
my $study_table;
my %format_table;
my @master_field_list = ('YG MAJOR', 'YG MINOR', 'YG CELL NAME', 'NOMINAL YG CELL NAME', 'AI MAJOR', 'AI MINOR', 'AI CELL NAME');
@master_field_list = (@master_field_list, 'MAPPING COUNT', 'LIB', 'DRAWN OR ESTIMATED', 'QUALITY', 'SHORTS/GRID', 'INTERFACE');
@master_field_list = (@master_field_list, 'X SCALE FACTOR', 'X GROWTH (PITCHES)', 'Y SCALE FACTOR');
#@master_field_list = (@master_field_list, 'ASSIGNED TO', 'LATEST CHECKIN DATE', 'LATEST CHECKIN OWNER', 'ORIGINAL CHECKIN DATE');
@master_field_list = (@master_field_list, 'LATEST CHECKIN DATE', 'LATEST CHECKIN OWNER', 'ORIGINAL CHECKIN DATE', 'ORIGINAL CHECKIN OWNER');
@master_field_list = (@master_field_list, 'COMMENTS', 'TOTAL INSTANCES', 'YG CELL WIDTH');
@master_field_list = (@master_field_list, 'YG CELL HEIGHT', 'YG CELL AREA', 'YG INSTANCE AREA', 'YG POLY PITCHES', 'YG DEVCOUNT');
@master_field_list = (@master_field_list, 'AI CELL WIDTH', 'AI CELL HEIGHT', 'AI POLY PITCHES', 'CSV GENERATION DATE');
@master_field_list = (@master_field_list, 'INSTANCE SUMMARY', 'FUB USAGE');


# Library query list
my @lib_list = ('ai0cld', 'ai0study', 'ai3study', 'ai7study');
#my @lib_list = ('ai7study');
my $stage = 1;
$logfh->info("***** Stage $stage: Read YG* List  *****");
# Read yg* data file (csv with field header)
my $ygdata = "${home_area}/ctl/yg.csv";
my $ygdatafh = IO::File->new;
$ygdatafh->open($ygdata) or die $logfh->fatalq("Could not open file for reading: $ygdata");
while (<$ygdatafh>) {
  chomp;
  if ($. == 1) {
    next;
  }
  if (/\S+/) {
    my ($ygname, $ygnomname, $ygwidth, $ygheight, $ygdevcount) = split(/\,/, $_);
    $ygname = lc($ygname);
    InitializeCell($logfh, \@master_field_list, $ygname, \%cell_table, \%format_table);
    $cell_table{$ygname}{'YG CELL NAME'} = $ygname;
    $cell_table{$ygname}{'NOMINAL YG CELL NAME'} = $ygnomname;
    $cell_table{$ygname}{'YG CELL WIDTH'} = $ygwidth;
    $cell_table{$ygname}{'YG CELL HEIGHT'} = $ygheight;
    $cell_table{$ygname}{'YG DEVCOUNT'} = $ygdevcount;
  }
}
$ygdatafh->close;
my $count = scalar keys %cell_table;
$logfh->info("$count YG cells read from file: $ygdata");


$stage++;
$logfh->info("***** Stage $stage: Read SNB leaf usage file  *****");
# Read SNB leaf usage file  (csv with field header)
my $leafdata = "${home_area}/ctl/snb_leaf_usage.csv";
my $leafdatafh = IO::File->new;
$leafdatafh->open($leafdata) or die $logfh->fatalq("Could not open file for reading: $leafdata");
while (<$leafdatafh>) {
  chomp;
  if ($. == 1) {
    next;
  }
  if (/\S+/) {
    my ($leafname, $instcount, $lowerleft_x, $lowerleft_y, $width, $height, $devcount, $fublist, $instsummary) = split(/\,/, $_);
    $leafname = lc($leafname);
    if (exists $cell_table{$leafname}) {
      $cell_table{$leafname}{'TOTAL INSTANCES'} = $instcount;
      $cell_table{$leafname}{'FUB USAGE'} = $fublist;
      $cell_table{$leafname}{'INSTANCE SUMMARY'} = $instsummary;
    }
  }
}
$leafdatafh->close;

$stage++;
$logfh->info("***** Stage $stage: Read YG->AI mapping file  *****");
# Read yg->ai name mapping file (whitespace delimited, no field headers)
my %ai_map;
my $aimap = "${home_area}/ctl/ivb_yg_ai.map";
my $aimapfh = IO::File->new;
$aimapfh->open($aimap) or die $logfh->fatalq("Could not open file for reading: $aimap");
while (<$aimapfh>) {
  if (/^(\S+)\s+(\S+)/) {
    my $ygcell = $1;
    my $aicell = $2;
    if (exists $cell_table{$ygcell}) {
      $cell_table{$ygcell}{'AI CELL NAME'} = $aicell;
      unless (exists $ai_map{$aicell}) {
	@{ $ai_map{$aicell} } = ();
      }
      push @{ $ai_map{$aicell} }, $ygcell;
    }
  }
}
$aimapfh->close;


$stage++;
$logfh->info("***** Stage $stage: Read cell assignment files  *****");
# Read assignment files
my $assigndir = "${home_area}/ctl";
my $assigndirfh = IO::Dir->new;
$assigndirfh->open($assigndir) or die $logfh->fatalq("Could not open directory for reading: $assigndir");
my @assign_files = grep /\.assign$/, $assigndirfh->read();
foreach my $file (@assign_files) {
  my $owner = $file;
  $owner =~ s/\.assign$//;
  my @record = ();
  ReadListFile($logfh, "${assigndir}/${file}", \@record);
  foreach my $ygcell (@record) {
    if (exists $cell_table{$ygcell}) {
      if ($cell_table{$ygcell}{'ASSIGNED TO'}) {
	$logfh->errorp("Cell->($ygcell) has been assigned more than once -> ($owner) ($cell_table{$ygcell}{'ASSIGNED TO'})");
      }
      $cell_table{$ygcell}{'ASSIGNED TO'} = $owner;
    } else {
      $logfh->errorp("Cell listed in assign file->(${file}) does not exist in yg0 master list->($ygcell)");
    }
  }
}


$stage++;
$logfh->info("***** Stage $stage: Search for LNFs in ivbstd libraries and run health checks *****");

our ($TRANSIENT_PSE_DB, $ATF_LOCKED);
Env::import('TRANSIENT_PSE_DB', 'ATF_LOCKED');

# Make sure we can't mess with the ATF database
$ATF_LOCKED = 'YES';

# Define tcl modules
my @tcl_modules_list;
my $genesys_code_dir = "${code_dir}/genesys";
my $dir_h = IO::Dir->new($genesys_code_dir);
my @dirs = grep /\.tcl$/, $dir_h->read();
foreach my $file (@dirs) {
  push @tcl_modules_list, "${genesys_code_dir}/${file}";
}


# Query study libs for checked in cell information
my %uid_hash;
my %aicell_data;
foreach my $targetlib (@lib_list) { 
  my @aicell_list_loop = ();
  $logfh->info("Querying Syncronicity information from cells in libary->($targetlib)");
  my $laylib = "${DB_ROOT}/${PROJECT}/${targetlib}_ivbstd/lay/latest/${targetlib}_ivbstd_lay";
  my $laylibfh = new IO::Dir;
  $laylibfh->open($laylib) or die $logfh->fatalq("Could not open library directory: $laylib");
  @aicell_list_loop = grep /^a(i|n)\w+$/, $laylibfh->read();
  foreach my $aicell (@aicell_list_loop) {
    my $lnf = "${laylib}/${aicell}/${aicell}.lnf";
    if (-f $lnf) {
      my $dsscquery = "${SYNC_DIR}/bin/dssc report history -list $lnf";
      my $dsscqueryfh = new IO::File;
      $dsscqueryfh->open("$dsscquery |") or die $logfh->fatalq("Could not open DSSC query:", $dsscquery);
      my (@record, $uid, $year, $time, $mday, $month_name, $day_of_week_name);
      my ($year_orig, $time_orig, $mday_orig, $month_name_orig, $day_of_week_name_orig, $uid_orig);
      $uid = '';
      while (<$dsscqueryfh>) {
	chomp;
	$logfh->infod("DSSC: $_") if $opt_debug;
	$_ =~ s/\{|\}/ /g;
	@record = split;
	my @shift_record = @record;
	my $first_record_date = 1;
	my $first_record_uid = 1;
	foreach my $token (@record) {
	  if ($token eq "D") {
	    $day_of_week_name = $shift_record[1]; 
	    $month_name = $shift_record[2];
	    $mday = $shift_record[3];
	    $time = $shift_record[4];
	    $year = $shift_record[5];
	    if ($first_record_date) {
	      $day_of_week_name_orig = $day_of_week_name;
	      $month_name_orig = $month_name;
	      $mday_orig = $mday;
	      $time_orig = $time;
	      $year_orig = $year;
	      $first_record_date = 0;
	    }
	  }
	  if ($token eq "A") {
	    $uid = $shift_record[1];
	    $logfh->infod("DSSC: UID->($uid)");
	    $uid_hash{$uid} = 1;
	    if ($first_record_uid) {
	      $uid_orig = $uid;
	      $first_record_uid = 0;
	    }
	  }
	  shift @shift_record;
	}
      }
      if ($uid) {
	my $month = ConvertMonthStringToInt($month_name) + 1;
	my $lastest_checkin_date = "${year}-${month}-${mday} $time";
	my $month_orig = ConvertMonthStringToInt($month_name_orig) + 1;
	my $original_checkin_date = "${year_orig}-${month_orig}-${mday_orig} ${time_orig}";
	my $original_checkin_uid = $uid_orig;
	if (exists $ai_map{$aicell}) {
	  $aicell_data{$targetlib}{$aicell}{'LATEST CHECKIN OWNER'} = $uid;
	  $aicell_data{$targetlib}{$aicell}{'LATEST CHECKIN DATE'} = $lastest_checkin_date;
	  $aicell_data{$targetlib}{$aicell}{'ORIGINAL CHECKIN DATE'} = $original_checkin_date;
	  $aicell_data{$targetlib}{$aicell}{'ORIGINAL CHECKIN OWNER'} = $original_checkin_uid;
	  $aicell_data{$targetlib}{$aicell}{'LIB'} = $targetlib;
	} else {
	  # Handle case where checked in cell name does not exist in cell map file
	  $logfh->errorp("Could not find cell in map file, skipping...  cell->($aicell) lib->($targetlib)");
	}
      }
    }
  }
  my $cellcount = scalar @aicell_list_loop;
  $logfh->info("Cells queried from $targetlib->($cellcount)");

  # Move to next lib if no cells found
  next unless ($cellcount);

  # Run Genesys for each set of cells in each library
  $logfh->info("Extracting Genesys cell metrics for cells in library->(${targetlib})");
  my $dmsprefix = "${WARD}/${basefile}.${targetlib}";
  RecompileDmspath($logfh, $targetlib, 'latest', "${dmsprefix}.pth", "${dmsprefix}.cds");
  $DMSPATH = "${dmsprefix}.pth";
  $CDSLIB = "${dmsprefix}.cds";
  my $runfile_dir = "${WARD}/runfiles_${targetlib}";
  DeleteDirTrees($runfile_dir);
  CreateDirTrees($runfile_dir);
  my $genesyslog = "${WARD}/${basefile}.${targetlib}.genesyslog";
  my $genesysfh = GenesysOpenSession($logfh, $genesyslog);
  GenesysLoadModules($logfh, $genesysfh, \@tcl_modules_list);
  $cellcount = 0;
  foreach my $aicell (sort keys %{ $aicell_data{$targetlib} }) {
    GenesysOpenCell($logfh, $aicell, 'lnf', '', 1, $genesysfh);
    GenesysCommandLine($logfh, $genesysfh, "::fmrMig::getCellMetrics");
    $cellcount++;
    if ($cellcount > 100) {
      GenesysDiscardAll($logfh, $genesysfh);
      $cellcount = 0;
    }
  }
  GenesysCloseSession($logfh, $genesysfh);  
  # Check to make sure run did not fatal
  CheckGenesysRun($logfh, \@tmplist, $genesyslog);
  
  # Extract data from Genesys run
  my $genesyslogfh = new IO::File;
  $genesyslogfh->open($genesyslog) or die $logfh->fatalq("Could not open file for reading: $genesyslog");
  ManipFile($logfh, 'copy', $runfile_dir, $genesyslog, '.');
  my (@record, $aicell, $width, $height, $devcount);
  while (<$genesyslogfh>) {
    if (/getCellMetrics: Cell->(\S+)\s+LowerLeft->(\S+)\s+XWidth->(\S+)u\s+YHeight->(\S+)u\s+HierDevCount->(\S+)\s*$/) {
      $aicell = $1;
      $width = $3;
      $height = $4;
      $devcount = $5;
      if ($devcount > 0) {
	$devcount = "drawn";
      } else {
	$devcount = "estimated";
      }
      $aicell_data{$targetlib}{$aicell}{'DRAWN OR ESTIMATED'} = $devcount;
      $aicell_data{$targetlib}{$aicell}{'AI CELL WIDTH'} = $width;
      $aicell_data{$targetlib}{$aicell}{'AI CELL HEIGHT'} = $height;
    }
  }
  
  # Build netbatch feeder commands for PY shorts and Genesys interface check
  $logfh->info("Build netbatch feeder commands for PY shorts and Genesys interface check lib->(${targetlib})");
  my $nbmgr = Netbatch->new($logfh, "CellStudy${targetlib}");
  my $persistency_dir = "${WARD}/persistency";
  DeleteDirTrees($persistency_dir);
  # Run PY shorts for all cells using netbatch (approx 2 min per cell!)
  my $pdsmode = 'trcstd';
  my $pdscommandbase = "/p/mpg/proc/common2/da_utils/lv/ivb_1.0/pdscommand.pl -mode $pdsmode -cmp nocmp -topcheck check -atf no";
  my $pdslogsfh = IO::Dir->new;
  $pdslogsfh->open($PDSLOGS) or die $logfh->fatalq("Could not open directory for reading: $PDSLOGS");
  my @files = grep /(\.cell\.log)|(\.run_details)|(\.iss\.)|(\.stats)/, $pdslogsfh->read;
  foreach my $file (@files) {
    if (-d "${PDSLOGS}/${file}") {
      DeleteDirTrees("${PDSLOGS}/${file}");
    } else {
      DeleteFiles("${PDSLOGS}/${file}");
    }
  }
  $pdslogsfh->close;
  foreach my $aicell (sort keys %{ $aicell_data{$targetlib} }) {
    $nbmgr->addjobtotask("CellstudyShorts_${targetlib}", "${pdscommandbase} -c ${aicell}");
  }
  $nbmgr->taskworkarea("CellstudyShorts_${targetlib}", $persistency_dir);
  $nbmgr->tasknbqueue("CellstudyShorts_${targetlib}", 'Express_MPG_IALcs');
  $nbmgr->tasknbclass("CellstudyShorts_${targetlib}", 'SUSE_64');
  $nbmgr->tasknbqslot("CellstudyShorts_${targetlib}", '500');
  $nbmgr->taskonjobfinish("CellstudyShorts_${targetlib}", "NBErr:Requeue(2)");
  $nbmgr->taskhunglimits("CellstudyShorts_${targetlib}", "10m:20m");
  $nbmgr->taskmaxwaiting("CellstudyShorts_${targetlib}", 30);
  $nbmgr->taskmaxjobs("CellstudyShorts_${targetlib}", 40);
  

  # Batch Genesys runs for the Genesys interface checker
  my $genesyslogsfh = IO::Dir->new;
  $genesyslogsfh->open($WARD) or die $logfh->fatalq("Could not open directory for reading: $WARD");
  @files = grep /\.rungenesys\.genesyslog/, $genesyslogsfh->read;
  foreach my $file (@files) {
    DeleteFiles("${WARD}/${file}");
  }
  my $genesyscommandbase = "${HOME}/ivb/genesys/rungenesys.pl";
  foreach my $aicell (sort keys %{ $aicell_data{$targetlib} }) {
    $nbmgr->addjobtotask("CellstudyInterface_${targetlib}", "${genesyscommandbase} --cell ${aicell} --command \"source ${GENESYS_MACROS}/fmStdCellCmp.tcl\" --command \"::fmStdCellCmp::CompareCell ${aicell} 1\"");
  }
  $nbmgr->taskworkarea("CellstudyInterface_${targetlib}", $persistency_dir);
  $nbmgr->tasknbqueue("CellstudyInterface_${targetlib}", 'MPG_IALcs');
  $nbmgr->tasknbclass("CellstudyInterface_${targetlib}", 'pnr_to');
  $nbmgr->tasknbqslot("CellstudyInterface_${targetlib}", '500');
  $nbmgr->taskonjobfinish("CellstudyInterface_${targetlib}", "NBErr:Requeue(2)");
  $nbmgr->taskhunglimits("CellstudyInterface_${targetlib}", "10m:20m");
  $nbmgr->taskmaxwaiting("CellstudyInterface_${targetlib}", 30);
  $nbmgr->taskmaxjobs("CellstudyInterface_${targetlib}", 40);

  # Launch nbfeeder
  $nbmgr->workarea($persistency_dir);
  $nbmgr->block_on;
  $nbmgr->terminate_on_finish_on;
  $nbmgr->taskrefresh(30);
  my $taskfile = "${WARD}/${exe_prefix}.${targetlib}.feed";
  $logfh->info("Starting netbatch feeder for health checking lib->(${targetlib})");
  $nbmgr->nbfeederstart($taskfile);
  $logfh->info("Netbatch feeder run complete for lib->(${targetlib})");

  # Examine PY output files
  $logfh->info("Parse PY/Genesys output files from netbatch run");
  foreach my $aicell (sort keys %{ $aicell_data{$targetlib} }) {
    my $rundetails = "${PDSLOGS}/${aicell}.${pdsmode}.py.run_details/${aicell}.LAYOUT_ERRORS";
    if ((-e "${PDSLOGS}/${aicell}.${pdsmode}.iss.log.abort") or (not (-e $rundetails))) {
      ManipFile($logfh, 'move', $runfile_dir, "${PDSLOGS}/${aicell}.${pdsmode}.iss.log.abort", '.');
      $aicell_data{$targetlib}{$aicell}{'SHORTS/GRID'} = 'ABORT';
      $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'AB'} = 1;
    }
    elsif (-e $rundetails) {
      my $rundetailsfh = IO::File->new;
      $rundetailsfh->open($rundetails) or die $logfh->fatalq("Could not open file for reading: $rundetails");
      ManipFile($logfh, 'copy', $runfile_dir, $rundetails, '.'); 
      my $shorts_grid_error_count = 0;
      while (<$rundetailsfh>) {
	if (/LAYOUT ERRORS RESULTS:\s+CLEAN/) {
	  $aicell_data{$targetlib}{$aicell}{'SHORTS/GRID'} = 0;
	  last;
	}
	if (/text_short\s+(\.)+\s+(\d+)\s+violation/) {
	  $shorts_grid_error_count += $2;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'SH'} = 1;
	}
	if (/off_grid_boundary\s+(\.)+\s+(\d+)\s+violation/) {
	  $shorts_grid_error_count += $2;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'GR'} = 1;
	}
	if (/ERROR DETAILS/) {
	  $aicell_data{$targetlib}{$aicell}{'SHORTS/GRID'} = $shorts_grid_error_count;
	  last;
	}
      }
      $rundetailsfh->close;
    }
    # Examine Genesys check interface output files
    my $checkinterface = "${WARD}/${aicell}.rungenesys.genesyslog";
    if (-e $checkinterface) {
      my $checkinterfacefh = IO::File->new;
      $checkinterfacefh->open($checkinterface) or die $logfh->fatalq("Could not open file for reading: $checkinterface");
      ManipFile($logfh, 'move', $runfile_dir, $checkinterface, '.');
      my $interface_error_count = 0;
      my %errors = ();
      my $run_ok = 0;
      while (<$checkinterfacefh>) {
	if (/Found a total of\s+\d+\s+violation\(s\)/) {
	  $run_ok = 1;
	  last;
	}
	elsif (/Bad m2 power rails in cell/) {
	  if ($aicell !~ /^(ai7|an4)/) {
	    $interface_error_count++;
	    $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'PW'} = 1;
	  }
	}
	elsif (/Cell origin for(.+)is not at 0/) {
	  $interface_error_count++;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'ZR'} = 1;
	}
	elsif (/Interfaces with uppercase name:/) {
	  $interface_error_count++;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'UP'} = 1;
	}
	elsif (/Missing interfaces:/) {
	  $interface_error_count++;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'MI'} = 1;
	}
	elsif (/Extra interfaces:/) {
	  $interface_error_count++;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'EI'} = 1;
	}
	elsif (/Different inte(r)?face layers/) {
	  $interface_error_count++;
	  $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'WL'} = 1;
	}
	elsif (/Different interface order:/) {
	  if ($aicell !~ /^(ai7|an4)/) {
	    $interface_error_count++;
	    $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'IO'} = 1;
	  }
	}
	elsif (/Different max hit points for drawn m1 terminal of net/) {
	  #$interface_error_count++;
	  #$aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'MX'} = 1;
	}
      }
      if ($run_ok) {
	$aicell_data{$targetlib}{$aicell}{'INTERFACE'} = $interface_error_count;
      } else {
	$aicell_data{$targetlib}{$aicell}{'INTERFACE'} = 'ABORT';
	$aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'AB'} = 1
      }
    } else {
      $aicell_data{$targetlib}{$aicell}{'INTERFACE'} = 'ABORT';
      $aicell_data{$targetlib}{$aicell}{'ERRORLIST'}{'AB'} = 1;
    }
    if (exists ($aicell_data{$targetlib}{$aicell}{'ERRORLIST'})) {
      $aicell_data{$targetlib}{$aicell}{'ERRORSTRING'} = join ('-', sort keys %{ $aicell_data{$targetlib}{$aicell}{'ERRORLIST'} });
    }
  }
}


# Read comment files
$stage++;
$logfh->info("***** Stage $stage: Fetch cell study comment files *****");
$uid_hash{$USER} = 1;
my %comment_hash;
foreach my $uid (keys %uid_hash) {
  my $comment_file = `cd ~${uid};pwd`;
  chomp $comment_file;
  $comment_file = "${comment_file}/cellstudy.comment";
  if (-r $comment_file) {
    my $commentfh = new IO::File;
    $commentfh->open($comment_file) or die $logfh->fatalq("Could not open file for reading: $comment_file");
    while (<$commentfh>) {
      if (/^\s*((y|a)\w\d\w+)\s+(.+)$/) {
	my $cell = $1;
	my $comment = ${3};
	chomp $comment;
	$comment =~ s/\"/\'/g;
	$comment = "\"${comment}\"";
	$logfh->infod("UID->($uid} Cell->($cell) Comment->($comment)");
	if (exists $comment_hash{$cell}) {
	  $logfh->warnp("Cell->($cell) has a duplicate comment");
	}
	$comment_hash{$cell} = $comment;
      }
    }
    $commentfh->close();
  }
}
foreach my $cell (sort keys %comment_hash) {
  if (exists $ai_map{$cell}) {
    if ($ai_map{$cell}) {
      foreach my $ygcell (@{ $ai_map{$cell} }) {
	if (exists $cell_table{$ygcell}) {
	  $cell_table{$ygcell}{'COMMENTS'} = $comment_hash{$cell};
	}
      }
    }
  }
  elsif (exists $cell_table{$cell}) {
    $cell_table{$cell}{'COMMENTS'} = $comment_hash{$cell};
  } else {
    $logfh->warnp("Cell->($cell) did not match existing yg*/ai* name");
  }
}


# Select best available cell interface
# To start, place highest priority on library precedence
# (i.e. take first found data regardless of cleanliness
my @transfer_fields = ('LATEST CHECKIN OWNER', 'LATEST CHECKIN DATE','ORIGINAL CHECKIN OWNER', 'ORIGINAL CHECKIN DATE', 'LIB');
@transfer_fields = (@transfer_fields, 'DRAWN OR ESTIMATED', 'AI CELL WIDTH', 'AI CELL HEIGHT');
@transfer_fields = (@transfer_fields, 'SHORTS/GRID', 'INTERFACE', 'ERRORSTRING');
foreach my $targetlib (@lib_list) {
  foreach my $aicell (sort keys %{ $aicell_data{$targetlib} }) {
    if (exists $aicell_data{$targetlib}{$aicell}{'LATEST CHECKIN OWNER'}) {
      foreach my $ygcell (@{ $ai_map{$aicell} }) {
	if (exists $cell_table{$ygcell}) {
	  foreach my $field (@transfer_fields) {
	    if (exists $aicell_data{$targetlib}{$aicell}{$field}) {
	      $cell_table{$ygcell}{$field} = $aicell_data{$targetlib}{$aicell}{$field};
	    }
	  }
	}
      }
    }
  }
}


# Generate calculated fields
foreach my $ygcell (keys %cell_table) {
  # CSV GENERATION DATE
  my $temp_date = $start_date;
  $temp_date =~ s/\(|\)//g;
  $cell_table{$ygcell}{'CSV GENERATION DATE'} = $temp_date;
  # YG MAJOR
  # YG MINOR
  $cell_table{$ygcell}{'YG MAJOR'} = substr($ygcell, 0, 6);
  $cell_table{$ygcell}{'YG MINOR'} = substr($ygcell, 0, 11);
  # AI MAJOR
  # AI MINOR
  if ($cell_table{$ygcell}{'AI CELL NAME'}) {
    my $ai0cell = $cell_table{$ygcell}{'AI CELL NAME'};
    $cell_table{$ygcell}{'AI MAJOR'} = substr($ai0cell, 0, 6);
    $cell_table{$ygcell}{'AI MINOR'} = substr($ai0cell, 0, 11);
  }

  # MAPPING COUNT
  if ($cell_table{$ygcell}{'AI CELL NAME'}) {
    my $aicell = $cell_table{$ygcell}{'AI CELL NAME'};
    $cell_table{$ygcell}{'MAPPING COUNT'} = scalar @{ $ai_map{$aicell} };
  }
  # X SCALE FACTOR
  if (($cell_table{$ygcell}{'YG CELL WIDTH'}) and ($cell_table{$ygcell}{'AI CELL WIDTH'})) {
    $cell_table{$ygcell}{'X SCALE FACTOR'} = $cell_table{$ygcell}{'AI CELL WIDTH'}/$cell_table{$ygcell}{'YG CELL WIDTH'};
  }
  # Y SCALE FACTOR
  if (($cell_table{$ygcell}{'YG CELL HEIGHT'}) and ($cell_table{$ygcell}{'AI CELL HEIGHT'})) {
    $cell_table{$ygcell}{'Y SCALE FACTOR'} = $cell_table{$ygcell}{'AI CELL HEIGHT'}/$cell_table{$ygcell}{'YG CELL HEIGHT'};
  }
  # YG0 CELL AREA
  if (($cell_table{$ygcell}{'YG CELL WIDTH'}) and ($cell_table{$ygcell}{'YG CELL HEIGHT'})) {
    $cell_table{$ygcell}{'YG CELL AREA'} = $cell_table{$ygcell}{'YG CELL WIDTH'} * $cell_table{$ygcell}{'YG CELL HEIGHT'};
  }
  # YG0 INSTANCE AREA
  if (($cell_table{$ygcell}{'YG CELL AREA'}) and ($cell_table{$ygcell}{'TOTAL INSTANCES'})) {
    $cell_table{$ygcell}{'YG INSTANCE AREA'} = $cell_table{$ygcell}{'YG CELL AREA'} * $cell_table{$ygcell}{'TOTAL INSTANCES'};
  }
  # YG0 POLY PITCHES
  if ($cell_table{$ygcell}{'YG CELL WIDTH'}) {
    $cell_table{$ygcell}{'YG POLY PITCHES'} = Round($cell_table{$ygcell}{'YG CELL WIDTH'}/.116);
  }
  # AI0 POLY PITCHES
  if ($cell_table{$ygcell}{'AI CELL WIDTH'}) {
    $cell_table{$ygcell}{'AI POLY PITCHES'} = Round($cell_table{$ygcell}{'AI CELL WIDTH'}/.09);
  } 
  # POLY PITCH DELTA
  if (($cell_table{$ygcell}{'YG POLY PITCHES'}) and ($cell_table{$ygcell}{'AI POLY PITCHES'})) {
    $cell_table{$ygcell}{'X GROWTH (PITCHES)'} = $cell_table{$ygcell}{'AI POLY PITCHES'} - $cell_table{$ygcell}{'YG POLY PITCHES'};
  }
  # QUALITY
  my $shorts = $cell_table{$ygcell}{'SHORTS/GRID'};
  my $interface = $cell_table{$ygcell}{'INTERFACE'};
  if (defined $shorts and defined $interface) {
    if (($shorts eq 'ABORT') or ($interface eq 'ABORT')) {
      $cell_table{$ygcell}{'QUALITY'} = $cell_table{$ygcell}{'ERRORSTRING'};
    }
    elsif (($shorts =~ /\d/) and ($interface =~ /\d/)) {
      if (($shorts > 0) or ($interface > 0)) {
	$cell_table{$ygcell}{'QUALITY'} = $cell_table{$ygcell}{'ERRORSTRING'};
      } else {
	$cell_table{$ygcell}{'QUALITY'} = "CLEAN";
      }
    }
  } 
}


# Generate studies CSV file
my $cellall_csv = "${exe_prefix}.studylibs.csv";
my $cellall_csvfh = new IO::File;
$cellall_csvfh->open(">$cellall_csv") or die $logfh->fatalq("Could not open file for writing: $cellall_csv");
my @header = @master_field_list;
my $format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

my $csv_header = join(',', @header);
$cellall_csvfh->printf("$csv_header\n");

foreach my $cell (sort keys %cell_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $cell_table{$cell}{$field};
  }
  my $csv_record = join(',', @values);
  $cellall_csvfh->printf("$csv_record\n");
}
$cellall_csvfh->close;
$logfh->info("CSV report generated: $cellall_csv");

# Generate source comparison CSV files
my %compare_table;
my $compare_csv = "${exe_prefix}.sourcecompare.csv";
my $compare_csvfh = new IO::File;
$compare_csvfh->open(">$compare_csv") or die $logfh->fatalq("Could not open file for writing: $compare_csv");
@header = ('AI CELL NAME');
foreach my $targetlib (@lib_list) {
  foreach my $wh ("${targetlib} WIDTH", "${targetlib} HEIGHT") {
    push @header, $wh;
  }
}

foreach my $targetlib (@lib_list) {
  foreach my $aicell (sort keys %{ $aicell_data{$targetlib} }) {
    $compare_table{$aicell}{'AI CELL NAME'} = $aicell;
    if (exists $aicell_data{$targetlib}{$aicell}{'DRAWN OR ESTIMATED'}) {
      $compare_table{$aicell}{"${targetlib} WIDTH"} =  $aicell_data{$targetlib}{$aicell}{'AI CELL WIDTH'};
      $compare_table{$aicell}{"${targetlib} HEIGHT"} =  $aicell_data{$targetlib}{$aicell}{'AI CELL HEIGHT'};
    } 
else {
      $compare_table{$aicell}{"${targetlib} WIDTH"} = '';
      $compare_table{$aicell}{"${targetlib} HEIGHT"} = '';
    }
  }
}

foreach my $aicell (sort keys %compare_table) {
  foreach my $field (@header) {
    unless (exists $compare_table{$aicell}{$field}) {
      $compare_table{$aicell}{$field} = '';
    }
  }  
}


$csv_header = join(',', @header);
$compare_csvfh->printf("$csv_header\n");

foreach my $aicell (sort keys %compare_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $compare_table{$aicell}{$field};
  }
  my $csv_record = join(',', @values);
  $compare_csvfh->printf("$csv_record\n");
}
$compare_csvfh->close;
$logfh->info("CSV report generated: $compare_csv");


$logfh->newline;
DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$logfh->info("Script completion date: $stop_date");
$logfh->info("$exe_name run complete");



##### Start subroutine definitions #####

sub InitializeCell {

  my $loghandle = shift;
  my $field_list_ref = shift;
  my $cell = shift;
  my $fub_table_ref = shift;
  my $format_table_ref = shift;
  
  foreach my $field (@{ $field_list_ref }) {
    $$fub_table_ref{$cell}{$field} = '';
    $$format_table_ref{$field} = 13;
  }
}


sub CheckGenesysRun {

  my $logfh = shift;
  my $tmpfiles_ref = shift;
  my $genesyslog = shift;

  my $parent_flow = $logfh->flowname('CheckGenesysPreProcess');

  open (GENESYSLOG, $genesyslog) or die $logfh->fatalq("Could not open $genesyslog for reading");
  
  while (<GENESYSLOG>) {
    if (/invalid command name(.+)Baa/) {
      chomp;
      $logfh->infoq($_);
      die $logfh->fatalq("Problem occurred during LNF pre-processing. See Genesys log file:", $genesyslog);
    }
  }
  close (GENESYSLOG);
  
  $logfh->flowname($parent_flow);
}
