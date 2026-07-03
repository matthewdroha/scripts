#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: migstat3.pl,v 1.2 2006/02/17 09:16:05 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: migstat3.pl,v 1.2 2006/02/17 09:16:05 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: migstat3.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Queries DB root and Penryn SQL to report status of pshift3

=cut

# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
  if (defined $ENV{'DA_OVR'}) {
    push @INC, $ENV{'DA_OVR'};
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
use Cwd;
use Time::Local;
use DAStdLib;
use MigStdLib;
use PdsStdLib;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE;

$SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME [-help] [-verbose] [-debug]
                  [-debug]

flag descriptions:

-debug            Run flow in debug mode. Temporary files are not deleted and
                  additional data is placed in log file.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME

Files that result from this run:

EOD



# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
my $options_ok = &GetOptions("help",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ();
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


##### Main Program #####

# Capture initial environment variables
our ($HOME, $WORK_AREA_ROOT_DIR, $DB_ROOT, $PROJ_SKILL, $PROJECT, $DA_PROJECTS, $SYNC_DIR);
our ($CDSLIB, $DMSPATH, $DBB, $MODEL, $DMSMODE);
my @env_list = ('HOME', 'WORK_AREA_ROOT_DIR', 'DB_ROOT', 'PROJ_SKILL', 'PROJECT', 'DA_PROJECTS');
@env_list = (@env_list, 'SYNC_DIR', 'CDSLIB', 'DMSPATH', 'DBB', 'MODEL', 'DMSMODE');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}

our ($BASEFILE, $MAINLOG);
$BASEFILE = "${EXE_PREFIX}";
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


unless ($machine_info =~ /i686 unknown/) {
  die $MAINLOG->fatalq("This script must be ran in a Linux-32 UE");
}


# Read list of supplementary fubs that need to be migrated
my $supplement_list = "$mig_lookup{$SITE}{'migstat3'}/ctl/fubs.supplement";
my $supplement_regex;
my %supplement_lookup;
if (-e $supplement_list) {
  open (SUPP, $supplement_list) or die $MAINLOG->fatalq("Could not open supplement list for reading: $supplement_list");
  while (<SUPP>) {
    if ((/^\s*\#/) or (/^\s*$/)) {
      next;
    }
    if (/^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/) {
      my $fub = $1;
      my $style = $2;
      my $cluster = $3;
      my $section = $4;
      my $temp_val = join(':', $style, $cluster, $section);
      $supplement_lookup{lc($fub)} = $temp_val;
      $MAINLOG->infoq("Added full fub definition fub from supplement list: " . lc($fub));
    }
    if (/^\s*(\S+)\s*$/) {
      my $fub = $1;
      $supplement_lookup{lc($fub)} = 1;
      $MAINLOG->infoq("Added fub from supplement list: " . lc($fub));
    }
  }
  close (SUPP);
  
  $supplement_regex = '^\s*(' . join('|', keys %supplement_lookup) . ')\s+(\S+)';
}

# Read list of fubs whose names are invalid and filter them from the master list
my $ignore_list = "$mig_lookup{$SITE}{'migstat3'}/ctl/fubs.ignore";
my %ignore_lookup;
if (-e $ignore_list) {
  open (IGNORE, $ignore_list) or die $MAINLOG->fatalq("Could not open ignore list for reading: $ignore_list");
  while (<IGNORE>) {
    if ((/^\s*\#/) or (/^\s*$/)) {
      next;
    }
    if (/\w/) {
      my @record = split;
      foreach my $fub (@record) {
	my $fub_lc = lc($fub);
	$ignore_lookup{$fub_lc} = 1;
	if ($supplement_lookup{$fub_lc}) {
	  die $MAINLOG->fatalq("Ignore list contains a fub that is also in the supplement list: $fub_lc");
	}
      }
    }
  }
}


my %fub_table;
my %format_table;

# Capture fubs in database that will be migrated
my $fubquery = "$PROJ_SKILL/gallery/bin/users_request/isFub.pl $PROJECT";
open (FUBQUERY, "$fubquery |") or die $MAINLOG->fatalq("Could not open fub query:", $fubquery);
my $fub_regex = 'regf|datap|rom|gigacell|special_circuit';
$MAINLOG->infoq("REGEX being used to filter target fub list: $fub_regex");
while (<FUBQUERY>) {
  my $fub = '';
  my $style = '';
  my $cluster = '';
  my $section = '';
  if ((/^\s*(\S+)\s+(${fub_regex})/) or ((scalar keys %supplement_lookup) and (/${supplement_regex}/))){
    $fub = lc($1);
    $style = lc($2);
    my @record = split;
    $cluster = pop (@record);
    $section = pop (@record);
  }
  if ($fub) {
    if ($ignore_lookup{$fub}) {
      $MAINLOG->infoq("Fub found in ignore list and removed from master table: $fub");
    } else {
      &InitializeFub($MAINLOG, \%fub_table, \%format_table, $fub, $style, $cluster, $section);
    }
  }
}
close (FUBQUERY);


foreach my $fub (keys %supplement_lookup) {
  if ($supplement_lookup{$fub} =~ /(\S+):(\S+):(\S+)/) {
    my $style = $1;
    my $cluster = $2;
    my $section = $3;
    unless (defined $fub_table{$fub}) {
      &InitializeFub($MAINLOG, \%fub_table, \%format_table, $fub, $style, $cluster, $section);
    }
  }
}



# Capture fubs which are LOR1 done
$fubquery = "${PROJ_SKILL}/gallery/data/macros/${PROJECT}/lor1_status/lor1_status.mco";
open (FUBQUERY, "$fubquery |") or die $MAINLOG->fatalq("Could not open fub query:", $fubquery);
while (<FUBQUERY>) {
  if (/MACRO|Cluster|Fub|Totals|(\/\d)/) {
    next;
  }
  elsif (/\w/) {
    my @record = split;
    my $fub = shift(@record);
    my $tag = pop(@record);
    $tag =~ s/\-/\./;
    if ($fub) {
      my $fub_lc = lc($fub);
      if (defined $fub_table{$fub_lc}) {
	$fub_table{$fub_lc}{'LOR1'} = $tag;
      }
    }
  }
}
close (FUBQUERY);



# For shared library situations, read target library for those fubs
my $shared_lib_list = "$mig_lookup{$SITE}{'migstat3'}/ctl/fubs.sharedlib";
if (-e $shared_lib_list) {
  open (SHARED, $shared_lib_list) or die $MAINLOG->fatalq("Could not open shared lib list for reading: $shared_lib_list");
  while (<SHARED>) {
    if ((/^\s*\#/) or (/^\s*$/)) {
      next;
    }
    my ($fub, $lib, $dbb) = split;
    my $fub_lc = lc($fub);
    if (exists $fub_table{$fub_lc}) {
      $fub_table{$fub_lc}{'FUBLIB'} = $lib;
      if ($dbb) {
	$fub_table{$fub_lc}{'DBB'} = $dbb;
      }
    } else {
      $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $shared_lib_list");
    }
  }
  close (SHARED);
}


# Grab the tags in the pshift3 UE model file
my %lay_cfg_hash;
my $ps3_cfg_file = "${DA_PROJECTS}/${PROJECT}/${PROJECT}.pshift3.cfg";
open (PS3CFG, $ps3_cfg_file) or die $MAINLOG->fatalq("Could not open cfg file for reading: $ps3_cfg_file");
while (<PS3CFG>) {
  if (/^\s*(\S+_${PROJECT}_lay)\s+(\S+)\s+/) {
    my $lib = lc($1);
    my $tag = lc($2);
    $lay_cfg_hash{$lib} = $tag;
  }
}
close (PS3CFG);


my $fub_total = scalar keys %fub_table;
my $fubs_processed = 0;
# Check pshift3 database status
foreach my $fub (keys %fub_table) {
  $MAINLOG->newline;
  $fubs_processed++;
  my $tempstring = sprintf "***** Start Processing fub:%-15s  %3s of %3s *****", "($fub)", $fubs_processed, $fub_total;
  $MAINLOG->info($tempstring);
  
  my $lib_prefix = $fub_table{$fub}{'FUBLIB'};
  $lib_prefix =~ s/_lay$//;
  my $lay_lib = "${DB_ROOT}/${PROJECT}/${lib_prefix}/lay";
  if (-d $lay_lib) {
    opendir (LAYLIB, $lay_lib) or die $MAINLOG->fatalq("Could not open lay lib dir for reading: $lay_lib");
    my @pshift3_dirs = grep /^pnr_pshift3/, readdir (LAYLIB);
    rewinddir (LAYLIB);
    my @pre_pshift3_dirs = grep /^pnr_pre_ps3/, readdir (LAYLIB);
    close (LAYLIB);
    $fub_table{$fub}{'PS3_TAG_COUNT'} = scalar @pshift3_dirs;
    if (scalar @pre_pshift3_dirs) {
      my @dirs = sort @pre_pshift3_dirs;
      my $target_cfg = pop(@dirs);
      $MAINLOG->infoq("Target pre_ps3 Config:(${target_cfg})");
      $fub_table{$fub}{'PRE_PS3_STATUS'} = $target_cfg;
    }
    if (scalar @pshift3_dirs) {
      my @dirs = sort @pshift3_dirs;
      my $target_cfg = pop(@dirs);
      $MAINLOG->infoq("Target Pshift3 Config:(${target_cfg})");
      my $fub_data_dir = "${lay_lib}/${target_cfg}/$fub_table{$fub}{'FUBLIB'}/${fub}";
      my $top_level_lnf = "${fub_data_dir}/${fub}.lnf";
      $fub_table{$fub}{'PS3_STATUS'} = $fub_table{$fub}{'TAG'} = $target_cfg;
      if (-e $top_level_lnf) {
	unless ($fub_table{$fub}{'IGNORETAG'} eq $target_cfg) {
	  $fub_table{$fub}{'LNF'} = 'yes';
	}
      }	
      my $lnf_time;
      if ($fub_table{$fub}{'LNF'} eq 'yes') {
	# Capture latest status
	my $tagquery = "${SYNC_DIR}/bin/dssc ls -report OMSRUNCTA $top_level_lnf";
	open (TAGQUERY, "$tagquery |") or die $MAINLOG->fatalq("Could not open tag query:", $tagquery);
	while (<TAGQUERY>) {
	  if (/^\s*Cached File\s+(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)/) {
	    chomp;
	    $MAINLOG->infoq("DSSC: $_");
	    my $month = $1;
	    my $mday = $2;
	    my $year = $3;
	    my $hour = $4;
	    my $minute = $5;
	    my $second = 0;
	      
	    $month -= 1;  # Needs to be in range of 0..11
	    $lnf_time = timelocal($second,$minute,$hour,$mday,$month,$year);
	    $MAINLOG->infoq("LNF-> FUB:($fub) SEC:($second) MIN:($minute) HOUR:($hour) MDAY:($mday) MONTH:($month) YEAR:($year)");
	    $MAINLOG->infoq("LNF-> FUB:(${fub}) LNF_TIME:($lnf_time)");
	    last;
	  }
	}
	close (TAGQUERY);
	unless ($lnf_time) {
	  die $MAINLOG->fatalq("No time stamp was extracted from SYNC dssc: $tagquery");
	}

	# Verify the proper tag is in the pshift3 UE model
	if (exists $lay_cfg_hash{$fub_table{$fub}{'FUBLIB'}}) {
	  if ($fub_table{$fub}{'TAG'} eq $lay_cfg_hash{$fub_table{$fub}{'FUBLIB'}}) {
	    $fub_table{$fub}{'UE_MODEL'} = 'yes';
	  }
	}

	# Verify integrity of data and whether the tagged fub is PlatoCBD or Sagantec
	if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'yes')) {
	  # Hack DMSPATH for specific fub
	  $MAINLOG->infoq("Compiling dmspath...");
	  my $newdmspath = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.dms.pth";
	  push(@TMPFILES, $newdmspath);
	  my $newdmsmodes = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.dms.pth.modes";
	  push(@TMPFILES, $newdmsmodes);
	  my $newcdslib = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.cds.lib";
	  push(@TMPFILES, $newcdslib);
	  
	  &RecompileDmspath($MAINLOG, $fub_table{$fub}{'DBB'}, 'pshift3', $newdmspath, $newcdslib);
	  $DMSPATH = $newdmspath;
	  $CDSLIB = $newcdslib;

	  my $cell_log = "${PDSLOGS}/$fub_table{$fub}{'FUB'}.cell.log";
	  &DeleteFiles($cell_log);
	  my @issin_out;
	  my $issin_cmd = "cd $PDSLOGS; ${ISSTOOLS}/issin -c $fub_table{$fub}{'FUB'} -noLayMapWarn -l rarepd.db -caseSensitive  -d lnf -lnfNoPolygonsForUdmPins    -ltlResolution 4  -cdsTechLib p1266lib -cdslib $CDSLIB -cadence50 -m ${ISSTOOLS}/p1266.map  -noSynthNetText -noIssinInfo -noLTLoutput";
	  &Pipe($MAINLOG, $issin_cmd, '', \@issin_out);
	  if (-e $cell_log) {
	    my $total_cells = 0;
	    my $sag_cells = 0;
	    open (CELLLOG, $cell_log) or die $MAINLOG->fatalq("Could not open cell.log file for reading: $cell_log");
	    while (<CELLLOG>) {
	      if (/and 0 error messages/) {
		$fub_table{$fub}{'ISS_OK'} = 'yes';
	      }
	      if (/NO_VER/) {
		die $MAINLOG->fatalq("One of the LNF files for fub:(${fub}) did not originate from the library");
	      }
	      if (/^\S+_${PROJECT}_lay\s+(\S+)\s+\d+\.\d+/) {
		my $cell = $1;
		$total_cells++;
		if ($cell =~ /^x[a-z][a-z]00/) {
		  $sag_cells++;
		}
	      }
	    }
	    close (CELLLOG);
	  }
	}
      }
    }
  }
  $MAINLOG->infoq("***** End Processing fub:($fub) *****");
}




# Build a hash whose primary key is the cluster
my %fub_cluster_hash;
foreach my $fub (keys %fub_table) {
  $fub_cluster_hash{$fub_table{$fub}{'CLUSTER'}}{$fub_table{$fub}{'SECTION'}}{$fub} = 1;
}


my $ps3_all_table = "${EXE_PREFIX}.pshift3_all.table";
my $ps3_all_csv = "${EXE_PREFIX}.pshift3_all.csv";
open (PS3ALLTAB, ">$ps3_all_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_all_table");
open (PS3ALLCSV, ">$ps3_all_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_all_csv");
my @header = ('FUB', 'STYLE', 'CLUSTER', 'SECTION', 'LOR1', 'PRE_PS3_STATUS', 'PS3_STATUS', 'LNF', 'UE_MODEL', 'ISS_OK', 'PS3_TAG_COUNT', 'COMMENT');
my $format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

my $csv_header = join(',', @header);
printf PS3ALLTAB ("${format}", @header);
printf PS3ALLCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS3ALLTAB ("${format}", @values);
  printf PS3ALLCSV "$csv_record\n";
}
close (PS3ALLTAB);
close (PS3ALLCSV);


my $ps3_status_table = "${EXE_PREFIX}.pshift3_status.table";
my $ps3_status_csv = "${EXE_PREFIX}.pshift3_status.csv";
open (PS3STATUSTAB, ">$ps3_status_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_status_table");
open (PS3STATUSCSV, ">$ps3_status_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_status_csv");
@header = ('FUB', 'STYLE', 'CLUSTER', 'LOR1', 'PRE_PS3_STATUS', 'PS3_STATUS', 'LNF', 'UE_MODEL', 'ISS_OK', 'PS3_TAG_COUNT', 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS3STATUSTAB ("${format}", @header);
printf PS3STATUSCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS3STATUSTAB ("${format}", @values);
  printf PS3STATUSCSV "$csv_record\n";
}
close (PS3STATUSTAB);
close (PS3STATUSCSV);


my $ps3_todo_table = "${EXE_PREFIX}.pshift3_todo.table";
my $ps3_todo_csv = "${EXE_PREFIX}.pshift3_todo.csv";
open (PS3TODOTAB, ">$ps3_todo_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_todo_table");
open (PS3TODOCSV, ">$ps3_todo_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_todo_csv");
@header = ('FUB', 'CLUSTER', 'LOR1', 'PS3_STATUS', 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS3TODOTAB ("${format}", @header);
printf PS3TODOCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  unless ($fub_table{$fub}{'TAG'}) {
    my @values;
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    my $csv_record = join(',', @values);
    printf PS3TODOTAB ("${format}", @values);
    printf PS3TODOCSV "$csv_record\n";
  }
}
close (PS3TODOTAB);
close (PS3TODOCSV); 


my $ps3_missinglnf_table = "${EXE_PREFIX}.pshift3_missinglnf.table";
my %fub_missing_lnf_hash;
open (PS3LNF, ">$ps3_missinglnf_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_missinglnf_table");
@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS3LNF ("${format}", @header);

foreach my $fub (sort keys %fub_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  if (($fub_table{$fub}{'TAG'}) and ($fub_table{$fub}{'LNF'} eq 'no')) {
    printf PS3LNF ("${format}", @values);
    $fub_missing_lnf_hash{$fub} = 1;
  } 
}

close (PS3LNF);


my $ps3_missingmodel_table = "${EXE_PREFIX}.pshift3_missingmodel.table";
my %fub_missing_model_hash;
open (PS3MODEL, ">$ps3_missingmodel_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_missingmodel_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS3MODEL ("${format}", @header);

foreach my $fub (sort keys %fub_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'no')) {
    printf PS3MODEL ("${format}", @values);
    $fub_missing_model_hash{$fub} = 1;
  } 
}


close (PS3MODEL);


my $ps3_badiss_table = "${EXE_PREFIX}.pshift3_badiss.table";
my %fub_badiss_hash;
open (PS3BADISS, ">$ps3_badiss_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_badiss_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS3BADISS ("${format}", @header);

foreach my $fub (sort keys %fub_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'yes') and ($fub_table{$fub}{'ISS_OK'} eq 'no')) {
    printf PS3BADISS ("${format}", @values);
    $fub_badiss_hash{$fub} = 1;
  } 
}

close (PS3BADISS);



my $ps3_nopretag_table = "${EXE_PREFIX}.pshift3_nopretag.table";
my %fub_nopretag_hash;
open (PS3NOPRETAG, ">$ps3_nopretag_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_nopretag_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS3NOPRETAG ("${format}", @header);

foreach my $fub (sort keys %fub_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  if (($fub_table{$fub}{'PS3_STATUS'} =~ /pnr_pshift3/) and ($fub_table{$fub}{'PRE_PS3_STATUS'} !~ /pnr_pre_ps3/)) {
    printf PS3NOPRETAG ("${format}", @values);
    $fub_nopretag_hash{$fub} = 1;
  } 
}

close (PS3BADISS);



my $ps3_release_summary = "${EXE_PREFIX}.pshift3_release.summary";
open (PS3SUM, ">$ps3_release_summary") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_release_summary");
print PS3SUM "***** migstat3.pl pshift3 summary *****\n\n";
print PS3SUM "Report Generated: ${start_date}\n\n";
my $target_count = 0;
my $lnf_count = 0;
my $ue_count = 0;
my $issok_count = 0;
my $released_count = 0;
my %fub_release_hash;
my %fub_issin_hash;
foreach my $fub (sort keys %fub_table) {
  if ($fub_table{$fub}{'LNF'} eq 'yes') {
    $lnf_count++;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} =~ /^(yes|n\/a)$/)) {
    $ue_count++;
    $fub_issin_hash{$fub} = 1;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'ISS_OK'} =~ /^(yes|n\/a)$/)) {
    $issok_count++;
    $fub_issin_hash{$fub} = 1;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and 
      ($fub_table{$fub}{'UE_MODEL'} eq 'yes') and 
      ($fub_table{$fub}{'ISS_OK'} =~ /^(yes|n\/a)$/)) {
    $released_count++;
    $fub_release_hash{$fub} = 1;
  }
  $target_count++;
}


printf PS3SUM "%-30s: %-5s of %-5s\n", 'Total pshift3 fubs released', "(${released_count})", "(${target_count})";
printf PS3SUM "%-51s: (%s)\n", 'Total number of pshift3 fubs with checked-in LNF', $lnf_count;
printf PS3SUM "%-51s: (%s)\n", 'Total number of pshift3 fubs in pshift3 UE model', $ue_count;
printf PS3SUM "%-51s: (%s)\n", 'Total number of pshift3 fubs with clean ISSIN run', $issok_count;
print PS3SUM "\n\n";
print PS3SUM "***** pshift3 fully released fubs *****\n";


my $ps3_release_list = "${EXE_PREFIX}.pshift3_release.list";
open (PS3RELLIST, ">$ps3_release_list") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_release_list");
foreach my $fub (sort keys %fub_release_hash) {
  printf PS3SUM "%-$format_table{'FUB'}s\n", $fub;
  printf PS3RELLIST "%-$format_table{'FUB'}s\n", $fub;
}
close (PS3RELLIST);


my $ps3_issin_ok_table = "${EXE_PREFIX}.pshift3_issin_ok.table";
my $ps3_issin_ok_list = "${EXE_PREFIX}.pshift3_issin_ok.list";
open (PS3ISSLIST, ">$ps3_issin_ok_list") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_issin_ok_list");
open (PS3ISSTABLE, ">$ps3_issin_ok_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps3_issin_ok_table");
@header = ('FUB');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s";
}
chomp $format;
$format .= "\n";
printf PS3ISSTABLE ("${format}", @header);

foreach my $fub (sort keys %fub_issin_hash) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  printf PS3ISSTABLE ("${format}", @values);
  printf PS3ISSLIST "%-$format_table{'FUB'}s\n", $fub;
}
close (PS3ISSLIST);
close (PS3ISSTABLE);


print PS3SUM "\n\n";


print PS3SUM "\n\n";
print PS3SUM "***** pshift3 fubs that have a TAG but are missing the PRE-PSHIFT3 TAG *****\n";
foreach my $fub (sort keys %fub_nopretag_hash) {
  printf PS3SUM "%-$format_table{'FUB'}s\n", $fub;
}

print PS3SUM "\n\n";
print PS3SUM "***** pshift3 fubs that have a TAG but are MISSING LNF *****\n";
foreach my $fub (sort keys %fub_missing_lnf_hash) {
  printf PS3SUM "%-$format_table{'FUB'}s\n", $fub;
}

print PS3SUM "\n\n";
print PS3SUM "***** pshift3 fubs that have TAG but are not in pshift3 MODEL  *****\n";
foreach my $fub (sort keys %fub_missing_model_hash) {
  printf PS3SUM "%-$format_table{'FUB'}s\n", $fub;
}

print PS3SUM "\n\n";
print PS3SUM "***** pshift3 fubs FAILING ISSIN in pshift3 model *****\n";
foreach my $fub (sort keys %fub_badiss_hash) {
  printf PS3SUM "%-$format_table{'FUB'}s\n", $fub;
}

close (PS3SUM);


$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete");



##### Start subroutine definitions #####

sub InitializeFub {

  my $loghandle = shift;
  my $fub_table_ref = shift;
  my $format_table_ref = shift;
  my $fub = shift;
  my $style = shift;
  my $cluster = shift;
  my $section = shift;
  
  $$fub_table_ref{$fub}{'FUB'} = $fub;
  $$format_table_ref{'FUB'} = 15;
  $$fub_table_ref{$fub}{'FUBLIB'} = "${fub}_${PROJECT}_lay";
  $$format_table_ref{'FUBLIB'} = 23;
  $$fub_table_ref{$fub}{'DBB'} = $fub;
  $$format_table_ref{'DBB'} = 15;
  $$fub_table_ref{$fub}{'STYLE'} = $style;
  $$format_table_ref{'STYLE'} = 15; 
  $$fub_table_ref{$fub}{'CLUSTER'} = $cluster;
  $$format_table_ref{'CLUSTER'} = 12;
  $$fub_table_ref{$fub}{'SECTION'} = $section;
  $$format_table_ref{'SECTION'} = 7;
  $$fub_table_ref{$fub}{'COMMENT'} = '-';
  $$format_table_ref{'COMMENT'} = 10;
  $$fub_table_ref{$fub}{'LOR1'} = '-';
  $$format_table_ref{'LOR1'} = 7;
  $$fub_table_ref{$fub}{'TAG'} = '';
  $$format_table_ref{'TAG'} = 18;
  $$fub_table_ref{$fub}{'LNF'} = 'no';
  $$format_table_ref{'LNF'} = 3;
  $$fub_table_ref{$fub}{'UE_MODEL'} = 'no';
  $$format_table_ref{'UE_MODEL'} = 8;
  $$fub_table_ref{$fub}{'ISS_OK'} = 'no';
  $$format_table_ref{'ISS_OK'} = 6;
  $$fub_table_ref{$fub}{'DIRECTIVES'} = '';
  $$format_table_ref{'DIRECTIVES'} = 20;
  $$fub_table_ref{$fub}{'IGNORETAG'} = '';
  $$format_table_ref{'IGNORETAG'} = 9;
  $$fub_table_ref{$fub}{'PS3_TAG_COUNT'} = '0';
  $$format_table_ref{'PS3_TAG_COUNT'} = 13;
  $$fub_table_ref{$fub}{'PS3_STATUS'} = 'no_ps3_tag';
  $$format_table_ref{'PS3_STATUS'} = 15;
  $$fub_table_ref{$fub}{'PRE_PS3_STATUS'} = '-';
  $$format_table_ref{'PRE_PS3_STATUS'} = 15; 
}


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




