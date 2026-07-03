#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: prefillstat.pl,v 1.7 2007/09/13 17:58:33 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: prefillstat.pl,v 1.7 2007/09/13 17:58:33 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: prefillstat.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Queries DB root and Penryn SQL to report best available prefill tag

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


#unless ($machine_info =~ /i686 unknown/) {
#  die $MAINLOG->fatalq("This script must be ran in a Linux-32 UE");
#}

my $home_area = "/usr/users/home2/mroha/prefillstat";

# Read list of supplementary fubs that need to be scanned
my $supplement_list = "${home_area}/ctl/fubs.supplement";
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
my $ignore_list = "${home_area}/ctl/fubs.ignore";
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
my $fub_regex = 'regf|datap|rom|gigacell|special_circuit|repeater|logic|rls';
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

# For shared library situations, read target library for those fubs
my $shared_lib_list = "${home_area}/ctl/fubs.sharedlib";
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


# A0 list
#my @tag_priority_list = ("silver", "rls_silver", "lorf", "rls2", "early_cdr_silver", "pre_cdrf", "lor2", "lor2_prefill");

# B0 list
my @tag_priority_list = ("lorb", "rlsblo", "early_cdr_silver", "iter_lorb", "pre_cdrb", "pre_rlsb");
my $tag_priority_re = join ('|', @tag_priority_list);
my %tag_priority_hash;

my @tag_weighted_list = reverse (@tag_priority_list);
&InitializePriority(\%tag_priority_hash, \@tag_weighted_list, 1000);


my $fub_total = scalar keys %fub_table;
my $fubs_processed = 0;
# Extract best tag and verify with ISSIN
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
    my @tag_dirs = grep /^${PROJECT}_(${tag_priority_re})\./, readdir (LAYLIB);
    close (LAYLIB);
    my @sorted_dirs = sort by_best_tag @tag_dirs;
    if (scalar @sorted_dirs) {
      if ($opt_debug) {
	my $tag_string = join(' ', @tag_dirs);
	$MAINLOG->infod("Initial tags: $tag_string");
      }
      if ($opt_debug) {
	my $tag_string = join(' ', @sorted_dirs);
	$MAINLOG->infod("Weighted tags: $tag_string");
      }
      my $target_cfg = pop(@sorted_dirs);
      $MAINLOG->infoq("Target Fill Config:(${target_cfg})");
      my $fub_data_dir = "${lay_lib}/${target_cfg}/$fub_table{$fub}{'FUBLIB'}/${fub}";
      my $top_level_lnf = "${fub_data_dir}/${fub}.lnf";
      $fub_table{$fub}{'TAG'} = $target_cfg;
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
	
	# Verify integrity of data using ISSIN
	if ($fub_table{$fub}{'LNF'} eq 'yes') {
	  # Hack DMSPATH for specific fub
	  $MAINLOG->infoq("Compiling dmspath...");
	  my $newdmspath = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.dms.pth";
	  push(@TMPFILES, $newdmspath);
	  my $newdmsmodes = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.dms.pth.modes";
	  push(@TMPFILES, $newdmsmodes);
	  my $newcdslib = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.cds.lib";
	  push(@TMPFILES, $newcdslib);
	  my $cfgfile = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.${BASEFILE}.cfg";
	  
	  open (CFGFILE, ">$cfgfile") or die $MAINLOG->fatalq("Could not open file for writing: $cfgfile");
	  print CFGFILE "$fub_table{$fub}{'FUBLIB'}   $fub_table{$fub}{'TAG'}";
	  close (CFGFILE);
	  
	  my $cfg_option = "-usercfgfile $cfgfile";
	  &RecompileDmspath($MAINLOG, $fub_table{$fub}{'DBB'}, 'ckt_model', $newdmspath, $newcdslib, $cfg_option);
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
	    }
	    close (CELLLOG);
	  }
	}
      }
    } else {
      $MAINLOG->infoq("No target tags found");
    }
  }
  $MAINLOG->infoq("***** End Processing fub:($fub) *****");
}




# Build a hash whose primary key is the cluster
my %fub_cluster_hash;
foreach my $fub (keys %fub_table) {
  $fub_cluster_hash{$fub_table{$fub}{'CLUSTER'}}{$fub_table{$fub}{'SECTION'}}{$fub} = 1;
}


my $prefill_all_table = "${EXE_PREFIX}.prefill_all.table";
my $prefill_all_csv = "${EXE_PREFIX}.prefill_all.csv";
open (PFALLTAB, ">$prefill_all_table") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_all_table");
open (PFALLCSV, ">$prefill_all_csv") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_all_csv");
my @header = ('FUB', 'STYLE', 'CLUSTER', 'SECTION', 'TAG', 'LNF', 'ISS_OK');
my $format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

my $csv_header = join(',', @header);
printf PFALLTAB ("${format}", @header);
printf PFALLCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PFALLTAB ("${format}", @values);
  printf PFALLCSV "$csv_record\n";
}
close (PFALLTAB);
close (PFALLCSV);



my $prefill_missinglnf_table = "${EXE_PREFIX}.prefill_missinglnf.table";
my %fub_missing_lnf_hash;
open (PFLNF, ">$prefill_missinglnf_table") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_missinglnf_table");
@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PFLNF ("${format}", @header);

foreach my $fub (sort keys %fub_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  if (($fub_table{$fub}{'TAG'}) and ($fub_table{$fub}{'LNF'} eq 'no')) {
    printf PFLNF ("${format}", @values);
    $fub_missing_lnf_hash{$fub} = 1;
  } 
}

close (PFLNF);



my $prefill_badiss_table = "${EXE_PREFIX}.prefill_badiss.table";
my %fub_badiss_hash;
open (PFBADISS, ">$prefill_badiss_table") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_badiss_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PFBADISS ("${format}", @header);

foreach my $fub (sort keys %fub_table) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'ISS_OK'} eq 'no')) {
    printf PFBADISS ("${format}", @values);
    $fub_badiss_hash{$fub} = 1;
  } 
}

close (PFBADISS);




my $prefill_summary = "${EXE_PREFIX}.prefill.summary";
open (PFSUM, ">$prefill_summary") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_summary");
print PFSUM "***** prefillstat.pl summary *****\n\n";
print PFSUM "Report Generated: ${start_date}\n\n";
my $target_count = 0;
my $lnf_count = 0;
my $issok_count = 0;
my $valid_tags_count = 0;
my %fub_release_hash;
my %fub_issin_hash;
foreach my $fub (sort keys %fub_table) {
  if ($fub_table{$fub}{'LNF'} eq 'yes') {
    $lnf_count++;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'ISS_OK'} =~ /^(yes|n\/a)$/)) {
    $issok_count++;
    $fub_issin_hash{$fub} = 1;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and 
      ($fub_table{$fub}{'ISS_OK'} =~ /^(yes|n\/a)$/)) {
    $valid_tags_count++;
    $fub_release_hash{$fub} = 1;
  }
  $target_count++;
}


printf PFSUM "%-30s: %-5s of %-5s\n", 'Total prefill tags valid', "(${valid_tags_count})", "(${target_count})";
printf PFSUM "%-51s: (%s)\n", 'Total number of prefill fubs with checked-in LNF', $lnf_count;
printf PFSUM "%-51s: (%s)\n", 'Total number of prefill fubs with clean ISSIN run', $issok_count;
print PFSUM "\n\n";
print PFSUM "***** prefill tagged fubs *****\n";


my $prefill_release_list = "${EXE_PREFIX}.prefill_release.list";
open (PFRELLIST, ">$prefill_release_list") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_release_list");
foreach my $fub (sort keys %fub_release_hash) {
  printf PFSUM "%-$format_table{'FUB'}s\n", $fub;
  printf PFRELLIST "%-$format_table{'FUB'}s\n", $fub;
}
close (PFRELLIST);


my $prefill_issin_ok_table = "${EXE_PREFIX}.prefill_issin_ok.table";
my $prefill_issin_ok_list = "${EXE_PREFIX}.prefill_issin_ok.list";
my $prefill_issin_ok_cfg = "${EXE_PREFIX}.prefill_issin_ok.cfg";
open (PFISSLIST, ">$prefill_issin_ok_list") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_issin_ok_list");
open (PFISSTABLE, ">$prefill_issin_ok_table") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_issin_ok_table");
open (PFISSCFG, ">$prefill_issin_ok_cfg") or die $MAINLOG->fatalq("Could not open file for writing: $prefill_issin_ok_cfg");
@header = ('FUB');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s";
}
chomp $format;
$format .= "\n";
printf PFISSTABLE ("${format}", @header);

foreach my $fub (sort keys %fub_issin_hash) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  printf PFISSTABLE ("${format}", @values);
  printf PFISSLIST "%-$format_table{'FUB'}s\n", $fub;
  printf PFISSCFG "%-$format_table{'FUBLIB'}s %-$format_table{'TAG'}s\n", $fub_table{$fub}{'FUBLIB'}, $fub_table{$fub}{'TAG'}; 
}
close (PFISSLIST);
close (PFISSTABLE);
close (PFISSCFG);


print PFSUM "\n\n";


print PFSUM "\n\n";
print PFSUM "***** prefill fubs that have a TAG but are MISSING LNF *****\n";
foreach my $fub (sort keys %fub_missing_lnf_hash) {
  printf PFSUM "%-$format_table{'FUB'}s\n", $fub;
}

print PFSUM "\n\n";
print PFSUM "***** prefill fubs FAILING ISSIN in target cfg *****\n";
foreach my $fub (sort keys %fub_badiss_hash) {
  printf PFSUM "%-$format_table{'FUB'}s\n", $fub;
}

close (PFSUM);


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
  $$fub_table_ref{$fub}{'TAG'} = '';
  $$format_table_ref{'TAG'} = 18;
  $$fub_table_ref{$fub}{'LNF'} = 'no';
  $$format_table_ref{'LNF'} = 3;
  $$fub_table_ref{$fub}{'ISS_OK'} = 'no';
  $$format_table_ref{'ISS_OK'} = 6;
  $$fub_table_ref{$fub}{'IGNORETAG'} = '';
  $$format_table_ref{'IGNORETAG'} = 9;
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


sub by_best_tag { 
  &TagWeight($a) <=> &TagWeight($b);
}

sub TagWeight {

  my $tag = shift;
  my $core_tag;
  my $days;

  if ($tag =~ /^${PROJECT}_(\S+)\.(\d+)\.(\d)\.(\d)$/) {
    $core_tag = $1;
    $days = $2*7 + $3 + $4*.1;
  }
  
  my $final_weight;
  if (exists $tag_priority_hash{$core_tag}) {
    $final_weight =  $tag_priority_hash{$core_tag} + $days;
  } else {
    $final_weight = $tag_priority_hash{'DEFAULT'} + $days;
  }
  return $final_weight;
}


sub InitializePriority {

  my $priority_hash_ref = shift;
  my $priority_list_ref = shift;
  my $weight = shift;

  my $current_weight = $weight;
  foreach my $item (@{ $priority_list_ref }) {
    $$priority_hash_ref{$item} += $current_weight;
    $current_weight+=$weight;
  }
  $$priority_hash_ref{'DEFAULT'} += $current_weight;
}
