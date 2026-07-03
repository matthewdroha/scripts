#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
# $Id: migstat.pl,v 1.27 2005/10/10 16:00:10 mroha Exp $


=pod
=head1 COPYRIGHT

$Id: migstat.pl,v 1.27 2005/10/10 16:00:10 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: migstat.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Queries migration release area and Merom SQL DB and generates several reports on migration
execution status

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
my $supplement_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.supplement";
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
my $ignore_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.ignore";
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
my $fubquery = "$PROJ_SKILL/gallery/bin/users_request/isFub.pl pnr";
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


# Add in the fubs that were removed in Penryn. No sense in tracking Penryn progress.
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



# Capture fubs which are CDR1 done
$fubquery = "${PROJ_SKILL}/gallery/data/macros/${PROJECT}/cdr1_status/cdr1_status.mco";
open (FUBQUERY, "$fubquery |") or die $MAINLOG->fatalq("Could not open fub query:", $fubquery);
while (<FUBQUERY>) {
  #if (/MACRO|Cluster|Fub|Totals|\/|(^\s*$)/) {
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
	$fub_table{$fub_lc}{'CDR1'} = $tag;
      }
    }
  }
}
close (FUBQUERY);


# Capture which fubs are platocbd
my $platocbd_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.platocbd";
open (PLATO, $platocbd_list) or die $MAINLOG->fatalq("Could not open platocbd list for reading: $platocbd_list");
while (<PLATO>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my ($fub) = split;
  my $fub_lc = lc($fub);
  if (defined $fub_table{$fub_lc}) {
    $fub_table{$fub_lc}{'FLOW_PLAN'} = 'plato';
  }
}
close (PLATO);

# Capture which fubs are not POR
my $nonpor_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.nonpor";
open (NONPOR, $nonpor_list) or die $MAINLOG->fatalq("Could not open nonpor list for reading: $nonpor_list");
while (<NONPOR>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my ($fub) = split;
  my $fub_lc = lc($fub);
  if (defined $fub_table{$fub_lc}) {
    $fub_table{$fub_lc}{'POR'} = 'no';
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $nonpor_list");
  }
}
close (NONPOR);


# Capture XY statistical information for PS1 and PS2
foreach my $release ('PS1', 'PS2') {
  foreach my $process ('1264', '1266') {
    if (($release eq 'PS2') and ($process eq '1266')) {
      next;
    }
    my $xy_dir = "$mig_lookup{$SITE}{'migstat'}/ctl/${release}_${process}_XY";
    opendir (XYDIR, $xy_dir) or die $MAINLOG->fatalq("Could not open xy dir for reading: $xy_dir");
    my @files = grep /\.getxy\.xy/, readdir (XYDIR);
    close (XYDIR);
    foreach my $file (@files) {
      my $fub = '';
      if ($file =~ /(\S+)\.getxy\.xy/) {
	$fub = lc($1);
	if ($fub and defined $fub_table{$fub}) {
	  my $xy_file = "${xy_dir}/${file}";
	  open (XYFILE, $xy_file) or die $MAINLOG->fatalq("Could not open xy file for reading: $xy_file");
	  while (<XYFILE>) {
	    if (/^(X|Y)=(\S+)/) {
	      my $dim = $1;
	      my $value = $2;
	      $fub_table{$fub}{"${release}_${process}_${dim}"} = sprintf "%.3f", $value;
	    }
	  }
	}
      }
    }
  }
}


# Capture floorplan 1266 XY info for later use
  my $fp_xy_file = "$mig_lookup{$SITE}{'migstat'}/ctl/floorplan.csv";
  open (FPXY, $fp_xy_file) or die $MAINLOG->infoq("Could not open floorplan xy file for reading: $fp_xy_file");
  while (<FPXY>) {
  chomp;
  my ($element, $type, $x, $y) = split(/,/, $_);
  if (($x =~ /\d+/) and ($y =~ /\d+/)) {
    my @record = split (/\//, $element);
    my $fub = pop(@record);
    if (defined $fub_table{lc($fub)}) {
      $fub_table{lc($fub)}{'FP_1266_X'} = sprintf "%.3f", $x;
      $fub_table{lc($fub)}{'FP_1266_Y'} = sprintf "%.3f", $y;
    }
  }
}



my $ps2audit_dir = "$mig_lookup{$SITE}{'migstat'}/ctl/ps2audit";
opendir (AUDITDIR, $ps2audit_dir) or die $MAINLOG->fatalq("Could not open ps2audit dir for reading: $ps2audit_dir");
my @files = grep /\.ps2audit/, readdir (AUDITDIR);
closedir (AUDITDIR);
foreach my $file (@files) {
  my $fub = '';
  if ($file =~ /(\S+)\.ps2audit/) {
    $fub = lc($1);
    if ($fub and defined $fub_table{$fub}) {
      my $ps2audit_file = "${ps2audit_dir}/${file}";
      open (AUDITFILE, $ps2audit_file) or die $MAINLOG->fatalq("Could not open ps2 audit file");
      my $header_found = 0;
      while (<AUDITFILE>) {
	if (/^\s*$/) {
	  next;
	}
	if (/^\s*ok\s*$/i) {
	  $fub_table{$fub}{'AUDIT'} = 'ok';
	} else {
	  $fub_table{$fub}{'AUDIT'} = 'ar';
	}
	last;
      }
      close (AUDITFILE);
    }
  }
}



# Capture which fubs are pvopt
my $pvopt_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.pvopt";
open (PVOPT, $pvopt_list) or die $MAINLOG->fatalq("Could not open pvopt list for reading: $pvopt_list");
while (<PVOPT>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my ($fub) = split;
  my $fub_lc = lc($fub);
  if (defined $fub_table{$fub_lc}) {
    $fub_table{$fub_lc}{'PVOPT'} = 'yes';
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $pvopt_list");
  }
}
close (PVOPT);


# Capture any fub tags which should be ignored for reporting purposes
my $ignoretag_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.ignoretag";
open (IGNORETAG, $ignoretag_list) or die $MAINLOG->fatalq("Could not open pvopt list for reading: $ignoretag_list");
while (<IGNORETAG>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my ($fub, $tag) = split;
  my $fub_lc = lc($fub);
  if (defined $fub_table{$fub_lc}) {
    $fub_table{$fub_lc}{'IGNORETAG'} = $tag;
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $ignoretag_list");
  }
}
close (IGNORETAG);



# Capture which fubs are subcell only jobs
my $subcell_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.subcell";
open (SUBCELL, $subcell_list) or die $MAINLOG->fatalq("Could not open subcell list for reading: $subcell_list");
while (<SUBCELL>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my @record = split;
  my $fub_lc = lc(shift(@record));
  if (defined $fub_table{$fub_lc}) {
    while (@record) {
      if ($record[0] =~ /s\=done/) {
 	$fub_table{$fub_lc}{'SUBCELLS_DONE'} = 'yes';
	last;
      }
      shift(@record);
    }
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $subcell_list");
  }
}
close (SUBCELL);


# Capture which fubs are LSA/SSA
my $cache_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.cache";
open (CACHE, $cache_list) or die $MAINLOG->fatalq("Could not open cache list for reading: $cache_list");
while (<CACHE>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my ($fub, $type) = split;
  unless ($type) {
    next;
  }
  my $fub_lc = lc($fub);
  if (defined $fub_table{$fub_lc}) {
    $fub_table{$fub_lc}{'CACHE'} = $type;
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $cache_list");
  }
}
close (CACHE);



# For shared library situations, read target library for those fubs
my $shared_lib_list = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.sharedlib";
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



# Capture any special directives
my $directives_list =  "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.scale_directives";
open (DIREC, $directives_list) or die $MAINLOG->fatalq("Could not open directives list for reading: $directives_list");
while (<DIREC>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my @record = split;
  my $fub = shift @record;
  my $fub_lc = lc($fub);
  if (exists $fub_table{$fub_lc}) {
    my $direc_string = join('  ', @record);
    foreach my $directive (@record) {
      if ($directive =~ /(\S+)\=(\S+)/) {
	my $varname = $1;
	my $varvalue = $2;
	$fub_table{$fub_lc}{'DIREC_LIST'}{$varname} = $varvalue;
      } else {
	die $MAINLOG->fatalq("Fub directive must be in form of VAR=VALUE: FUB:($fub)  DIRECTIVE:($directive)");
      }
    }
    $fub_table{$fub_lc}{'DIRECTIVES'} = $direc_string;
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $directives_list");
  }
}
close (DIREC);


# Read in the cluster priority lists
opendir (CTLDIR, "$mig_lookup{$SITE}{'migstat'}/ctl") or die $MAINLOG->fatalq("Could not open control dir for reading");
my @priority_files = grep /\.priority$/, readdir (CTLDIR);
foreach my $file (@priority_files) {
  my $fullpath = "$mig_lookup{$SITE}{'migstat'}/ctl/${file}";
  open (PRIFILE, $fullpath) or die $MAINLOG->fatalq("Could not open priority file for reading: $fullpath");
  my $list_number = 1;
  while (<PRIFILE>) {
    if ((/^\s*\#/) or (/^\s*$/)) {
      next;
    }
    my @record = split;
    my ($fub) = split; 
    my $fub_lc = lc($fub);
    if (exists $fub_table{$fub_lc}) {
      $fub_table{$fub_lc}{'PRIORITY'} = $list_number;
      $list_number++;
    } else {
      $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $fullpath");
    }
  }
  close (PRIFILE);
}



# Read in fub release plan
my $plan = "$mig_lookup{$SITE}{'migstat'}/ctl/fubs.plan";
open (PLAN, $plan) or die $MAINLOG->fatalq("Could not open plan for reading: $plan");
while (<PLAN>) {
  if ((/^\s*\#/) or (/^\s*$/)) {
    next;
  }
  my @record = split;
  my $fub = shift(@record);
  my $fub_lc = lc($fub);
  if (exists $fub_table{$fub_lc}) {
    while (@record) {
      if ($record[0] =~ /^\d+_\d+_\d+$/) {
	$fub_table{$fub_lc}{'PLAN_ORIG'} = $record[0];
      }
      elsif ($record[0] =~ /^r\=(\d+_\d+_\d+)$/) {
	$fub_table{$fub_lc}{'PLAN_ADJUST'} = $1;
      }
      elsif ($record[0] =~ /^e\=(\d+_\d+_\d+)$/) {
	$fub_table{$fub_lc}{'ETA'} = $1;
      }
      elsif ($record[0] =~ /^o\=(\S+)$/) {
	$fub_table{$fub_lc}{'ORDER'} = $1;
      }
      elsif ($record[0] =~ /\S+/) {
	my $comment = join(' ', @record);
	$comment =~ s/,/ /g;
	$fub_table{$fub_lc}{'COMMENT'} = $comment;
	last;
      } else {
	$MAINLOG->error("Could not match: $record[0]");
	die $MAINLOG->fatalq("Unexpected entry in fubs.plan file: $plan");
      }
      shift (@record);
    }
  } else {
    $MAINLOG->warnq("TYPO_WARNING: fub:(${fub_lc}) $plan");
  }
}
close (PLAN);
  

# Grab the tags in the pshift2 UE model file
my %lay_cfg_hash;
my $ps2_cfg_file = "${DA_PROJECTS}/${PROJECT}/${PROJECT}.pshift2.cfg";
open (PS2CFG, $ps2_cfg_file) or die $MAINLOG->fatalq("Could not open cfg file for reading: $ps2_cfg_file");
while (<PS2CFG>) {
  if (/^\s*(\S+_${PROJECT}_lay)\s+(\S+)\s+/) {
    my $lib = lc($1);
    my $tag = lc($2);
    $lay_cfg_hash{$lib} = $tag;
  }
}
close (PS2CFG);


my $fub_total = scalar keys %fub_table;
my $fubs_processed = 0;
# Check pshift2 database status
foreach my $fub (keys %fub_table) {
  $MAINLOG->newline;
  $fubs_processed++;
  my $tempstring = sprintf "***** Start Processing fub:%-15s  %3s of %3s *****", "($fub)", $fubs_processed, $fub_total;
  $MAINLOG->info($tempstring);
  if ($fub_table{$fub}{'ORDER'} eq 'subcell') {
    $MAINLOG->infoq("fub:($fub) will only have subcells migrated");
    $fub_table{$fub}{'UE_MODEL'} = "n/a";
    $fub_table{$fub}{'LIB_OK'} = "n/a";
    $fub_table{$fub}{'NTCL'} = "n/a";
    $fub_table{$fub}{'ALFTRC'} = "n/a";
    if ($fub_table{$fub}{'SUBCELLS_DONE'} eq 'yes') {
      $fub_table{$fub}{'LNF'} = 'yes';
    }
    $MAINLOG->infoq("***** End Processing fub:($fub) *****");
    next;
  }

  if ($fub_table{$fub}{'ORDER'} eq 'mig_only') {
    $MAINLOG->infoq("fub:($fub) will only be migrated, no cmp cleanup");
    $fub_table{$fub}{'NTCL'} = "n/a";
    $fub_table{$fub}{'ALFTRC'} = "n/a";
  }
  
  my $lib_prefix = $fub_table{$fub}{'FUBLIB'};
  $lib_prefix =~ s/_lay$//;
  my $lay_lib = "${DB_ROOT}/${PROJECT}/${lib_prefix}/lay";
  if (-d $lay_lib) {
    opendir (LAYLIB, $lay_lib) or die $MAINLOG->fatalq("Could not open lay lib dir for reading: $lay_lib");
    my @pshift2_dirs = grep /^pnr_pshift2/, readdir (LAYLIB);
    close (LAYLIB);
    if (scalar @pshift2_dirs) {
      my @dirs = sort @pshift2_dirs;
      my $target_cfg = pop(@dirs);
      $MAINLOG->infoq("Target Config:(${target_cfg})");
      my $fub_data_dir = "${lay_lib}/${target_cfg}/$fub_table{$fub}{'FUBLIB'}/${fub}";
      my $top_level_lnf = "${fub_data_dir}/${fub}.lnf";
      if (-e $top_level_lnf) {
	unless ($fub_table{$fub}{'IGNORETAG'} eq $target_cfg) {
	  $fub_table{$fub}{'TAG'} = $target_cfg;
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

	# Verify the proper tag is in the pshift2 UE model
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
	  
	  &RecompileDmspath($MAINLOG, $fub_table{$fub}{'DBB'}, 'pshift2', $newdmspath, $newcdslib);
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
		$fub_table{$fub}{'LIB_OK'} = 'yes';
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
	    if ($fub_table{$fub}{'LIB_OK'} eq 'yes') {
	      $MAINLOG->infoq("FUB:($fub) Total cells checked in: $total_cells");
	      $MAINLOG->infoq("FUB:($fub) Total sagantec cells checked in: $sag_cells");
	      if ($total_cells < 2) {
		die $MAINLOG->fatalq("ISSIN reported 0 errors, but no cells were in translation list.");
	      } else {
		if (${sag_cells}/${total_cells} > 0.5) {
		  $fub_table{$fub}{'FLOW_ACTUAL'} = 'sag';
		} else {
		  $fub_table{$fub}{'FLOW_ACTUAL'} = 'plato';
		}
	      }

	      my $getxy_cmd = "cd $WORK_AREA_ROOT_DIR; $mig_utils{$SITE}/getxy.pl -cell $fub_table{$fub}{'FUB'} -dbb $fub_table{$fub}{'DBB'}";
	      my @getxy_out;
	      my $xy_file = "${WORK_AREA_ROOT_DIR}/$fub_table{$fub}{'FUB'}.getxy.xy";
	      &DeleteFiles($xy_file);
	      &Pipe($MAINLOG, $getxy_cmd, '', \@getxy_out);
	      open (XYFILE, $xy_file) or die $MAINLOG->fatalq("Could not open XY file for reading: $xy_file");
	      while (<XYFILE>) {
		chomp;
		if (/^PS1_STAGE=(\S+)/) {
		  $MAINLOG->infoq("FUB:($fub) $_");
		  $fub_table{$fub}{'PS1_STAGE'} = $1;
		}
		if (/^(X|Y)=(\S+)/) {
		  $MAINLOG->infoq("FUB:($fub) $_");
		  $fub_table{$fub}{"PS2_1266_${1}"} = $2;
		}
	      }
	    }
	  }
	}

	if ($fub_table{$fub}{'ORDER'} eq 'mig_only') {
	  $MAINLOG->infoq("***** End Processing fub:($fub) *****");
	  next;
	}

	# Verify the extraction data is checked into the tag and is later than the LNF checkin
	my @extraction_extensions = ('crdpfz', 'crntclz', 'crsn', 'ctk');
	my @config_list = ($target_cfg, 'latest');
	
	foreach my $config (@config_list) {
	  my $files_found = 0;
	  $fub_data_dir = "${lay_lib}/${config}/$fub_table{$fub}{'FUBLIB'}/${fub}";
	  foreach my $extension (@extraction_extensions) {
	    if (-e "${fub_data_dir}/${fub}.${extension}") {
	      $files_found++;
	    }
	  }
	  if ($files_found == scalar @extraction_extensions) {
	    # Open ntcl file and check date against pshift2 tag
	    my $ntclz_file = "${fub_data_dir}/${fub}.crntclz";
	    open (NTCLFH, "gzip -dc $ntclz_file | ") or die $MAINLOG->fatalq("Could not open gzipped file for reading: $ntclz_file");
	    my $ntclz_time = '';
	    while (<NTCLFH>) {
	      if (/^\s*\$\s+CREATED:\s+\S+\s+(\S+)\s+(\S+)\s+(\S+):(\S+):(\S+)\s+(\S+)/) {
		my $month_name = $1;
		my $mday = $2;
		my $hour = $3;
		my $minute = $4;
		my $second = $5;
		my $year = $6;
		my $month = &ConvertMonthStringToInt($month_name);
		$ntclz_time = timelocal($second,$minute,$hour,$mday,$month,$year);
		$MAINLOG->infoq("NTCL-> CONFIG:($config) FUB:($fub) SEC:($second) MIN:($minute) HOUR:($hour) MDAY:($mday) MONTH:($month) YEAR:($year)");
		$MAINLOG->infoq("NTCL-> CONFIG:($config) FUB:(${fub}) NTCL_TIME:($ntclz_time)");
		last;
	      }
	    }
	    close (NTCLFH);
	    if ($ntclz_time) {
	      if (($lnf_time < $ntclz_time) and ($config eq $target_cfg)) {
		$fub_table{$fub}{'NTCL'} = 'yes';
	      }
	    } else {
	      $MAINLOG->warnp("No time stamp was extracted from ntclz file: $ntclz_file");
	    }
	  }
	}
	# PLACEHOLDER: Verify the alftrcbu data is checked into the tag and is later than the LNF checkin
	my @alftrc_extensions = ('alftrcbu');
	foreach my $config (@config_list) {
	  my $files_found = 0;
	  $fub_data_dir = "${lay_lib}/${config}/$fub_table{$fub}{'FUBLIB'}/${fub}";
	  foreach my $extension (@alftrc_extensions) {
	    if (-e "${fub_data_dir}/${fub}.${extension}") {
	      $files_found++;
	    }
	  }
	  if ($files_found == scalar @alftrc_extensions) {
	    # Open alftrc file and check date against pshift2 tag
	    my $alftrc_file = "${fub_data_dir}/${fub}.alftrcbu";
	    open (ALFTRC, $alftrc_file) or die $MAINLOG->fatalq("Could not open file for reading: $alftrc_file");
	    my $alftrc_time = '';
	    while (<ALFTRC>) {
	      if (/^\(304\s+(\d+)\s+\d+\)\s*$/) {
		$alftrc_time = $1;
		$MAINLOG->infoq("ALFTRC-> CONFIG:($config) FUB:(${fub}) ALFTRC_TIME:($alftrc_time)");
		last;
	      }
	    }
	    close (ALFTRC);
	    unless ($alftrc_time) {
	      die $MAINLOG->fatalq("No time stamp was extracted from alftrc file: $alftrc_file");
	    }
	    if (($lnf_time < $alftrc_time) and ($config eq $target_cfg)) {
	      $fub_table{$fub}{'ALFTRC'} = 'yes';
	    }
	  }
	}
      }
    }
  }
  $MAINLOG->infoq("***** End Processing fub:($fub) *****");
}




# Build a hash whose primary key is the date 
my %fub_schedule_hash;
foreach my $fub (keys %fub_table) {
  if ($fub_table{$fub}{'PLAN_ADJUST'}) {
    $fub_schedule_hash{$fub_table{$fub}{'PLAN_ADJUST'}}{$fub} = 1;
  } else {
    $fub_schedule_hash{$fub_table{$fub}{'PLAN_ORIG'}}{$fub} = 1; 
  }
}

# Build a hash whose primary key is the cluster
my %fub_cluster_hash;
foreach my $fub (keys %fub_table) {
  $fub_cluster_hash{$fub_table{$fub}{'CLUSTER'}}{$fub_table{$fub}{'SECTION'}}{$fub} = 1;
}


# Calculate scale factors
foreach my $release ('PS1', 'PS2') {
  foreach my $dim ('X', 'Y') {
    foreach my $fub (keys %fub_table) {
      my $val1264 = $fub_table{$fub}{"${release}_1264_${dim}"};
      my $val1266 = $fub_table{$fub}{"${release}_1266_${dim}"};
      if (($val1264 =~ /\d/) and ($val1266 =~ /\d/)) {
	my $scale = ${val1266}/${val1264};
	$fub_table{$fub}{"${release}_SCALE_${dim}"} = sprintf "%.3f", $scale;
      }
    }
  }
}

foreach my $dim ('X', 'Y') {
  foreach my $fub (keys %fub_table) {
    my $fp_val = $fub_table{$fub}{"FP_1266_${dim}"};
    my $ps2_val = $fub_table{$fub}{"PS2_1266_${dim}"};
    my $ps1_val = $fub_table{$fub}{"PS1_1266_${dim}"};
    if (($fp_val =~ /\d/) and ($ps2_val =~ /\d/)) {
      my $delta = $ps2_val - $fp_val;
      $fub_table{$fub}{"PS2_FP_${dim}_DELTA"} = sprintf "%.3f", $delta;
    }
    if (($ps1_val =~ /\d/) and ($ps2_val =~ /\d/)) {
      my $delta = $ps2_val - $ps1_val;
      $fub_table{$fub}{"PS2_PS1_${dim}_DELTA"} = sprintf "%.3f", $delta;
    }
  }
}
    

my @xy_field_list = ('PS1_1264_X', 'PS1_1266_X', 'PS1_1264_Y', 'PS1_1266_Y', 'PS2_1264_X', 'PS2_1266_X', 'PS2_1264_Y', 'PS2_1266_Y', 'FP_1266_X', 'FP_1266_Y');
my @scale_list = ('PS1_SCALE_X', 'PS2_SCALE_X', 'PS1_SCALE_Y', 'PS2_SCALE_Y');
my @delta_list = ('PS2_PS1_X_DELTA', 'PS2_PS1_Y_DELTA', 'PS2_FP_X_DELTA', 'PS2_FP_Y_DELTA');


my $ps2_all_table = "${EXE_PREFIX}.pshift2_all.table";
my $ps2_all_csv = "${EXE_PREFIX}.pshift2_all.csv";
open (PS2ALLTAB, ">$ps2_all_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_all_table");
open (PS2ALLCSV, ">$ps2_all_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_all_csv");
my @header = ('FUB', 'STYLE', 'CLUSTER', 'SECTION', 'PRIORITY', 'PVOPT', 'CACHE', 'FLOW_PLAN', 'FLOW_ACTUAL', 'PLAN_ORIG', 'PLAN_ADJUST', 'ETA', 'ORDER', 'CDR1', 'LNF', 'UE_MODEL', 'LIB_OK', 'NTCL', 'ALFTRC', 'AUDIT', 'TAG', @xy_field_list, @scale_list, @delta_list, 'COMMENT');
my $format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

my $csv_header = join(',', @header);
printf PS2ALLTAB ("${format}", @header);
printf PS2ALLCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS2ALLTAB ("${format}", @values);
  printf PS2ALLCSV "$csv_record\n";
}
close (PS2ALLTAB);
close (PS2ALLCSV);


my $ps2_status_table = "${EXE_PREFIX}.pshift2_status.table";
my $ps2_status_csv = "${EXE_PREFIX}.pshift2_status.csv";
open (PS2STATUSTAB, ">$ps2_status_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_status_table");
open (PS2STATUSCSV, ">$ps2_status_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_status_csv");
@header = ('FUB', 'STYLE', 'CLUSTER', 'CACHE', 'FLOW_PLAN', 'FLOW_ACTUAL', 'ORDER', 'CDR1', 'LNF', 'UE_MODEL', 'LIB_OK', 'NTCL', 'ALFTRC', 'AUDIT', 'TAG', 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS2STATUSTAB ("${format}", @header);
printf PS2STATUSCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS2STATUSTAB ("${format}", @values);
  printf PS2STATUSCSV "$csv_record\n";
}
close (PS2STATUSTAB);
close (PS2STATUSCSV);


my $ps2_todo_table = "${EXE_PREFIX}.pshift2_todo.table";
my $ps2_todo_csv = "${EXE_PREFIX}.pshift2_todo.csv";
open (PS2TODOTAB, ">$ps2_todo_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_todo_table");
open (PS2TODOCSV, ">$ps2_todo_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_todo_csv");
@header = ('FUB', 'CLUSTER', 'PRIORITY', 'FLOW_PLAN', 'ORDER', 'CDR1', 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS2TODOTAB ("${format}", @header);
printf PS2TODOCSV "$csv_header\n";

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    unless ($fub_table{$fub}{'TAG'}) {
      my @values;
      foreach my $field (@header) {
	push @values, $fub_table{$fub}{$field};
      }
      my $csv_record = join(',', @values);
      printf PS2TODOTAB ("${format}", @values);
      printf PS2TODOCSV "$csv_record\n";
    }
  }
}
close (PS2TODOTAB);
close (PS2TODOCSV); 


my @fp_xy_field_list = ('PS2_1266_X', 'PS2_1266_Y', 'FP_1266_X', 'FP_1266_Y');
my @fp_xy_delta_list = ('PS2_FP_X_DELTA', 'PS2_FP_Y_DELTA');
my $ps2_fpxy_table = "${EXE_PREFIX}.pshift2_fpxy.table";
my $ps2_fpxy_csv = "${EXE_PREFIX}.pshift2_fpxy.csv";
open (PS2FPXYTAB, ">$ps2_fpxy_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_fpxy_table");
open (PS2FPXYCSV, ">$ps2_fpxy_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_fpxy_csv");
@header = ('FUB', 'FLOW_ACTUAL', @fp_xy_field_list, @fp_xy_delta_list, 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS2FPXYTAB ("${format}", @header);
printf PS2FPXYCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS2FPXYTAB ("${format}", @values);
  printf PS2FPXYCSV "$csv_record\n";
}
close (PS2FPXYTAB);
close (PS2FPXYCSV);


my @ps_xy_field_list = ('PS1_1266_X', 'PS1_1266_Y', 'PS2_1266_X', 'PS2_1266_Y');
my @ps_xy_delta_list = ('PS2_PS1_X_DELTA', 'PS2_PS1_Y_DELTA');
my $ps2_psxy_table = "${EXE_PREFIX}.pshift2_psxy.table";
my $ps2_psxy_csv = "${EXE_PREFIX}.pshift2_psxy.csv";
open (PS2PSXYTAB, ">$ps2_psxy_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_psxy_table");
open (PS2PSXYCSV, ">$ps2_psxy_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_psxy_csv");
@header = ('FUB', 'FLOW_ACTUAL', @ps_xy_field_list, @ps_xy_delta_list, 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS2PSXYTAB ("${format}", @header);
printf PS2PSXYCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS2PSXYTAB ("${format}", @values);
  printf PS2PSXYCSV "$csv_record\n";
}
close (PS2PSXYTAB);
close (PS2PSXYCSV);


my $ps2_scxy_table = "${EXE_PREFIX}.pshift2_scxy.table";
my $ps2_scxy_csv = "${EXE_PREFIX}.pshift2_scxy.csv";
open (PS2SCXYTAB, ">$ps2_scxy_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_scxy_table");
open (PS2SCXYCSV, ">$ps2_scxy_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_scxy_csv");
@header = ('FUB', 'FLOW_ACTUAL', @scale_list, 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS2SCXYTAB ("${format}", @header);
printf PS2SCXYCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS2SCXYTAB ("${format}", @values);
  printf PS2SCXYCSV "$csv_record\n";
}
close (PS2SCXYTAB);
close (PS2SCXYCSV);



my $ps2_xy_table = "${EXE_PREFIX}.pshift2_xy.table";
my $ps2_xy_csv = "${EXE_PREFIX}.pshift2_xy.csv";
open (PS2XYTAB, ">$ps2_xy_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_xy_table");
open (PS2XYCSV, ">$ps2_xy_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_xy_csv");
@header = ('FUB', 'FLOW_ACTUAL', @xy_field_list, @scale_list, @delta_list, 'COMMENT');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

$csv_header = join(',', @header);
printf PS2XYTAB ("${format}", @header);
printf PS2XYCSV "$csv_header\n";

foreach my $fub (sort keys %fub_table) {
  my @values;
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  my $csv_record = join(',', @values);
  printf PS2XYTAB ("${format}", @values);
  printf PS2XYCSV "$csv_record\n";
}
close (PS2XYTAB);
close (PS2XYCSV);



my $ps2_sagtodo_table = "${EXE_PREFIX}.pshift2_sag_todo.table";
my $ps2_platotodo_table = "${EXE_PREFIX}.pshift2_plato_todo.table";
open (PS2SAG, ">$ps2_sagtodo_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_sagtodo_table");
open (PS2PLATO, ">$ps2_platotodo_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_platotodo_table");
@header = ('FUB', 'CLUSTER', 'SECTION', 'ORDER', 'CDR1', 'DIRECTIVES');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2SAG ("${format}", @header);
printf PS2PLATO ("${format}", @header);


foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    unless ($fub_table{$fub}{'TAG'}) {
      my @values = ();
      foreach my $field (@header) {
	push @values, $fub_table{$fub}{$field};
      }
      if ($fub_table{$fub}{'FLOW_PLAN'} eq 'plato') {
	printf PS2PLATO ("${format}", @values);
      } else {
	printf PS2SAG ("${format}", @values);
      }
    }
  }
}

close (PS2SAG);
close (PS2PLATO);




my $ps2_missinglnf_table = "${EXE_PREFIX}.pshift2_missinglnf.table";
my %fub_missing_lnf_hash;
open (PS2LNF, ">$ps2_missinglnf_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_missinglnf_table");
@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2LNF ("${format}", @header);

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    my @values = ();
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    if (($fub_table{$fub}{'TAG'}) and ($fub_table{$fub}{'LNF'} eq 'no')) {
      printf PS2LNF ("${format}", @values);
      $fub_missing_lnf_hash{$fub} = 1;
    } 
  }
}

close (PS2LNF);


my $ps2_missingmodel_table = "${EXE_PREFIX}.pshift2_missingmodel.table";
my %fub_missing_model_hash;
open (PS2MODEL, ">$ps2_missingmodel_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_missingmodel_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2MODEL ("${format}", @header);

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    my @values = ();
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'no')) {
      printf PS2MODEL ("${format}", @values);
      $fub_missing_model_hash{$fub} = 1;
    } 
  }
}

close (PS2MODEL);


my $ps2_badlnf_table = "${EXE_PREFIX}.pshift2_badlnf.table";
my %fub_badlnf_hash;
open (PS2BADLNF, ">$ps2_badlnf_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_badlnf_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2BADLNF ("${format}", @header);

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    my @values = ();
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'yes') and ($fub_table{$fub}{'LIB_OK'} eq 'no')) {
      printf PS2BADLNF ("${format}", @values);
      $fub_badlnf_hash{$fub} = 1;
    } 
  }
}

close (PS2BADLNF);


my $ps2_missingntcl_table = "${EXE_PREFIX}.pshift2_missingntcl.table";
my %fub_missing_ntcl_hash;
open (PS2NTCL, ">$ps2_missingntcl_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_missingntcl_table");

@header = ('FUB', 'FUBLIB', 'TAG', 'FLOW_ACTUAL');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2NTCL ("${format}", @header);

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    my @values = ();
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'yes') and ($fub_table{$fub}{'LIB_OK'} eq 'yes') and ($fub_table{$fub}{'NTCL'} eq 'no')) {
      printf PS2NTCL ("${format}", @values);
      $fub_missing_ntcl_hash{$fub} = 1;
    } 
  }
}

close (PS2NTCL);


my $ps2_missingalftrc_table = "${EXE_PREFIX}.pshift2_missingalftrc.table";
my %fub_missing_alftrc_hash;
open (PS2ALFTRC, ">$ps2_missingalftrc_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_missingalftrc_table");

@header = ('FUB', 'FUBLIB', 'TAG');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2ALFTRC ("${format}", @header);

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    my @values = ();
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'yes') and ($fub_table{$fub}{'LIB_OK'} eq 'yes') and ($fub_table{$fub}{'ALFTRC'} eq 'no')) {
      printf PS2ALFTRC ("${format}", @values);
      $fub_missing_alftrc_hash{$fub} = 1;
    } 
  }
}

close (PS2ALFTRC);


my $ps2_mismatchflow_table = "${EXE_PREFIX}.pshift2_mismatchflow.table";
my %fub_mismatchflow_hash;
open (PS2MISMATCH, ">$ps2_mismatchflow_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_mismatchflow_table");
@header = ('FUB', 'FUBLIB', 'TAG', 'FLOW_PLAN', 'FLOW_ACTUAL');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

printf PS2MISMATCH ("${format}", @header);

foreach my $date (sort keys %fub_schedule_hash) {
  foreach my $fub (sort keys %{ $fub_schedule_hash{$date} }) {
    my @values = ();
    foreach my $field (@header) {
      push @values, $fub_table{$fub}{$field};
    }
    if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} eq 'yes') and ($fub_table{$fub}{'LIB_OK'} eq 'yes')
	and ($fub_table{$fub}{'FLOW_PLAN'} ne $fub_table{$fub}{'FLOW_ACTUAL'})) {
      printf PS2MISMATCH ("${format}", @values);
      $fub_mismatchflow_hash{$fub} = 1;
    } 
  }
}
close (PS2MISMATCH);


my $ps2_release_summary = "${EXE_PREFIX}.pshift2_release.summary";
open (PS2SUM, ">$ps2_release_summary") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_release_summary");
print PS2SUM "***** migstat.pl pshift2 summary *****\n\n";
print PS2SUM "Report Generated: ${start_date}\n\n";
my $target_count = 0;
my $lnf_count = 0;
my $ue_count = 0;
my $libok_count = 0;
my $ntcl_count = 0;
my $alftrc_count = 0;
my $released_count = 0;
my $sag_release_count = 0;
my $plato_release_count = 0;
my $sag_total_count = 0;
my $plato_total_count = 0;
my %fub_release_hash;
my %fub_issin_hash;
foreach my $fub (sort keys %fub_table) {
  if ($fub_table{$fub}{'LNF'} eq 'yes') {
    $lnf_count++;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'UE_MODEL'} =~ /^(yes|n\/a)$/)) {
    $ue_count++;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'LIB_OK'} =~ /^(yes|n\/a)$/)) {
    $libok_count++;
    $fub_issin_hash{$fub} = 1;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'ALFTRC'} =~ /^(yes|n\/a)$/)) {
    $alftrc_count++;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and ($fub_table{$fub}{'NTCL'} =~ /^(yes|n\/a)$/)) {
    $ntcl_count++;
  }
  if (($fub_table{$fub}{'LNF'} eq 'yes') and
      ($fub_table{$fub}{'UE_MODEL'} =~ /^(yes|n\/a)$/) and
      ($fub_table{$fub}{'NTCL'} =~ /^(yes|n\/a)$/) and
      ($fub_table{$fub}{'LIB_OK'} =~ /^(yes|n\/a)$/) and
      ($fub_table{$fub}{'ALFTRC'} =~ /^(yes|n\/a)$/)) {
    $released_count++;
    if ($fub_table{$fub}{'FLOW_ACTUAL'} eq 'plato') {
      $plato_release_count++;
    } else {
      $sag_release_count++;
    }
    $fub_release_hash{$fub} = 1;
  }
  $target_count++;
  if ($fub_table{$fub}{'FLOW_PLAN'} eq 'plato') {
    $plato_total_count++;
  } else {
    $sag_total_count++;
  }
}

printf PS2SUM "%-30s: %-5s of %-5s\n", 'Total pshift2 fubs released', "(${released_count})", "(${target_count})";
printf PS2SUM "%-30s: %-5s of %-5s\n", 'Sagantec pshift2 fubs released', "(${sag_release_count})", "(${sag_total_count})";
printf PS2SUM "%-30s: %-5s of %-5s\n", 'Platocbd pshift2 fubs released', "(${plato_release_count})", "(${plato_total_count})";
printf PS2SUM "\n";
printf PS2SUM "%-51s: (%s)\n", 'Total number of pshift2 fubs with checked-in LNF', $lnf_count;
printf PS2SUM "%-51s: (%s)\n", 'Total number of pshift2 fubs in pshift2 UE model', $ue_count;
printf PS2SUM "%-51s: (%s)\n", 'Total number of pshift2 fubs with clean ISSIN run', $libok_count;
printf PS2SUM "%-51s: (%s)\n", 'Total number of pshift2 fubs with checked-in NTCL', $ntcl_count;
printf PS2SUM "%-51s: (%s)\n", 'Total number of pshift2 fubs with checked-in ALFTRC', $alftrc_count;
print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fully released fubs (access in UE with pnr -m pshift2 -b <fub>) *****\n";


my $ps2_release_list = "${EXE_PREFIX}.pshift2_release.list";
open (PS2RELLIST, ">$ps2_release_list") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_release_list");
foreach my $fub (sort keys %fub_release_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
  printf PS2RELLIST "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}
close (PS2RELLIST);


my $ps2_issin_ok_table = "${EXE_PREFIX}.pshift2_issin_ok.table";
my $ps2_issin_ok_list = "${EXE_PREFIX}.pshift2_issin_ok.list";
open (PS2ISSLIST, ">$ps2_issin_ok_list") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_issin_ok_list");
open (PS2ISSTABLE, ">$ps2_issin_ok_table") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_issin_ok_table");
@header = ('FUB', 'FLOW_ACTUAL');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";
printf PS2ISSTABLE ("${format}", @header);

foreach my $fub (sort keys %fub_issin_hash) {
  my @values = ();
  foreach my $field (@header) {
    push @values, $fub_table{$fub}{$field};
  }
  printf PS2ISSTABLE ("${format}", @values);
  printf PS2ISSLIST "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}
close (PS2ISSLIST);
close (PS2ISSTABLE);


print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fubs with MISMATCH between expected flow and actual flow *****\n";
foreach my $fub (sort keys %fub_mismatchflow_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s plan=%s actual=%s\n", $fub, $fub_table{$fub}{'FLOW_PLAN'}, $fub_table{$fub}{'FLOW_ACTUAL'};
}


print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fubs that have TAG but are MISSING LNF *****\n";
foreach my $fub (sort keys %fub_missing_lnf_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}

print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fubs MISSING UE model *****\n";
foreach my $fub (sort keys %fub_missing_model_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}

print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fubs FAILING ISSIN *****\n";
foreach my $fub (sort keys %fub_badlnf_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}

print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fubs MISSING NTCL checkin *****\n";
foreach my $fub (sort keys %fub_missing_ntcl_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}

print PS2SUM "\n\n";
print PS2SUM "***** pshift2 fubs MISSING ALFTRC checkin *****\n";
foreach my $fub (sort keys %fub_missing_alftrc_hash) {
  printf PS2SUM "%-$format_table{'FUB'}s %s\n", $fub, $fub_table{$fub}{'FLOW_ACTUAL'};
}
close (PS2SUM);


my $total_por = 0;
my $total_nonpor = 0;
my $total_por_rel = 0;
my $total_nonpor_rel = 0;
my $sag_por = 0;
my $sag_por_rel = 0;
my $sag_nonpor = 0;
my $sag_nonpor_rel = 0;
my $plato_por = 0;
my $plato_por_rel = 0;
my $plato_nonpor = 0;
my $plato_nonpor_rel = 0;
foreach my $fub (sort keys %fub_table) {
  if ($fub_table{$fub}{'POR'} eq 'yes') {
    $total_por++;
    if ($fub_table{$fub}{'FLOW_PLAN'} eq 'sag') {
      $sag_por++;
      if ($fub_table{$fub}{'LNF'} eq 'yes') {
	$sag_por_rel++;
	$total_por_rel++
      }	
    } else {
      $plato_por++;
      if ($fub_table{$fub}{'LNF'} eq 'yes') {
	$plato_por_rel++;
	$total_por_rel++;
      }
    }
  } else {
    $total_nonpor++;
    if ($fub_table{$fub}{'FLOW_PLAN'} eq 'sag') {
      $sag_nonpor++;
      if ($fub_table{$fub}{'LNF'} eq 'yes') {
	$sag_nonpor_rel++;
	$total_nonpor_rel++
	}	
    } else {
      $plato_nonpor++;
      if ($fub_table{$fub}{'LNF'} eq 'yes') {
	$plato_nonpor_rel++;
	$total_nonpor_rel++;
      }
    }
  }
}


my $ps2_por_summary = "${EXE_PREFIX}.pshift2_por.summary";

open (PS2POR, ">$ps2_por_summary") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_por_summary");
print PS2POR "***** migstat.pl pshift2 POR status *****\n\n";
print PS2POR "Report Generated: ${start_date}\n\n";

printf PS2POR "%-53s: %-5s of %-5s\n", 'TOTAL fubs with pshift2 LNF checked in/tagged', "($lnf_count)", "(${target_count})";printf PS2POR "\n";
printf PS2POR "%-53s: %-5s of %-5s\n", 'POR TOTAL fubs with pshift2 LNF checked in/tagged', "($total_por_rel)", "($total_por)";
printf PS2POR "%-53s: %-5s of %-5s\n", 'POR SAG fubs with pshift2 LNF checked in/tagged', "($sag_por_rel)", "($sag_por)";
printf PS2POR "%-53s: %-5s of %-5s\n", 'POR PLATO fubs with pshift2 LNF checked in/tagged', "($plato_por_rel)", "($plato_por)";


printf PS2POR "\n";
printf PS2POR "%-53s: %-5s of %-5s\n", 'NON-POR TOTAL fubs with pshift2 LNF checked in/tagged', "($total_nonpor_rel)", "($total_nonpor)";
printf PS2POR "%-53s: %-5s of %-5s\n", 'NON-POR SAG fubs with pshift2 LNF checked in/tagged', "($sag_nonpor_rel)", "($sag_nonpor)";
printf PS2POR "%-53s: %-5s of %-5s\n", 'NON-POR PLATO fubs with pshift2 LNF checked in/tagged', "($plato_nonpor_rel)", "($plato_nonpor)";
printf PS2POR "\n";

@header = ('FUB', 'STYLE', 'CLUSTER', 'SECTION');
$format = '';
foreach my $field (@header) {
  $format .= "%-$format_table{$field}s ";
}
chomp $format;
$format .= "\n";

foreach my $flow ('sag', 'plato') {
  foreach my $por ('yes', 'no') {
    my $flow_uc = uc($flow);
    my $por_string;
    if ($por eq 'yes') {
      $por_string = 'POR';
    } else {
      $por_string = 'NON-POR';
    }
    print PS2POR "\n\n";
    print PS2POR "***** $flow_uc $por_string (Full List) *****\n";
    foreach my $fub (sort keys %fub_table) {
      my @values = ();
      if (($fub_table{$fub}{'FLOW_PLAN'} eq $flow) and ($fub_table{$fub}{'POR'} eq $por)) {
	foreach my $field (@header) {
	  push @values, $fub_table{$fub}{$field};
	}
	printf PS2POR ("${format}", @values);
      }
    }
  }
}


my $ps2_audit_summary = "${EXE_PREFIX}.pshift2_audit.summary";
my $ps2_audit_csv = "${EXE_PREFIX}.pshift2_audit.csv";
open (PS2AUDITSUM, ">$ps2_audit_summary") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_audit_summary");
open (PS2AUDITCSV, ">$ps2_audit_csv") or die $MAINLOG->fatalq("Could not open file for writing: $ps2_audit_csv");
close (PS2AUDITCSV);
print PS2AUDITSUM "***** migstat.pl pshift2 audit summary *****\n\n";
print PS2AUDITSUM "Report Generated: ${start_date}\n\n";

my $audit_ok_count = 0;
my $ar_count = 0;
my $no_audit_count = 0;


my %cluster_table;
foreach my $fub (keys %fub_table) {
  my $cluster = $fub_table{$fub}{'CLUSTER'};
  $cluster_table{$cluster}{'FUB COUNT'}++;
  $cluster_table{$cluster}{'FUB STATUS'}{$fub} = 'no pshift2 data';
  if ($fub_table{$fub}{'LNF'} eq 'yes') {
    $cluster_table{$cluster}{'LNF COUNT'}++; 
    if ($fub_table{$fub}{'AUDIT'} eq 'no') {
      $cluster_table{$cluster}{'NO AUDIT TURNIN'}++;
      $no_audit_count++;
      $cluster_table{$cluster}{'FUB STATUS'}{$fub} = 'no audit results';
    }
    elsif ($fub_table{$fub}{'AUDIT'} eq 'ok') {
      $cluster_table{$cluster}{'AUDIT OK'}++;
      $audit_ok_count++;
      $cluster_table{$cluster}{'FUB STATUS'}{$fub} = 'ok';
    }
    elsif ($fub_table{$fub}{'AUDIT'} eq 'ar') {
      $cluster_table{$cluster}{'OPEN PS2 TEAM AR'}++;
      $ar_count++;
      $cluster_table{$cluster}{'FUB STATUS'}{$fub} = 'open audit ARs';
    }
  }
}

printf PS2AUDITSUM "%-51s: (%s)\n", 'Total number of fubs targeted for pshift2', $target_count;
printf PS2AUDITSUM "%-51s: (%s)\n", 'Total number of fubs with checked-in pshift2 LNF', $lnf_count;
printf PS2AUDITSUM "%-51s: (%s)\n", 'Total number of fubs with completed PS2 audits', $audit_ok_count;
printf PS2AUDITSUM "%-51s: (%s)\n", 'Total number of fubs with open PS2 audit ARs', $ar_count;
printf PS2AUDITSUM "%-51s: (%s)\n\n", 'Total number of fubs with no PS2 audit results', $no_audit_count;

print PS2AUDITSUM "***** By Cluster Status *****\n\n";
@header = ('Cluster', 'Total Fubs', 'PS2 LNF Tagged', 'PS2 Audit Complete', 'PS2 Open Audit ARs', 'No PS2 Audit Results');
printf PS2AUDITSUM "%-12s %-12s %-16s %-20s %-20s %-22s\n", @header; 
foreach my $cluster (sort keys %cluster_table) {
  $cluster_table{$cluster}{'LNF COUNT'}+=0;
  $cluster_table{$cluster}{'AUDIT OK'}+=0;
  $cluster_table{$cluster}{'OPEN PS2 TEAM AR'}+=0;
  $cluster_table{$cluster}{'NO AUDIT TURNIN'}+=0;
  my @record = ($cluster, $cluster_table{$cluster}{'FUB COUNT'},  $cluster_table{$cluster}{'LNF COUNT'}, $cluster_table{$cluster}{'AUDIT OK'});
  @record = (@record, $cluster_table{$cluster}{'OPEN PS2 TEAM AR'}, $cluster_table{$cluster}{'NO AUDIT TURNIN'});
  printf PS2AUDITSUM "%-12s %-12s %-16s %-20s %-20s %-22s\n", @record;
}
print PS2AUDITSUM "\n\n";

foreach my $cluster (sort keys %cluster_table) {
  print PS2AUDITSUM "***** FUB Status For CLUSTER: (${cluster}) *****\n\n";
  if (defined $cluster_table{$cluster}{'FUB STATUS'}) {
    foreach my $fub (sort keys %{ $cluster_table{$cluster}{'FUB STATUS'} }) {
      printf PS2AUDITSUM "%-15s %-s\n", $fub, $cluster_table{$cluster}{'FUB STATUS'}{$fub};
    }
  } else {
    die $MAINLOG->fatalq("Undefined FUB status for cluster $cluster. Should not have cluster without fub");
  }
  print PS2AUDITSUM "\n\n";
}

close PS2AUDITSUM; 

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
  $$fub_table_ref{$fub}{'CACHE'} = '';
  $$format_table_ref{'CACHE'} = 5;
  $$fub_table_ref{$fub}{'POR'} = 'yes';
  $$format_table_ref{'POR'} = 3;
  $$fub_table_ref{$fub}{'SUBCELLS_DONE'} = 'no';
  $$format_table_ref{'SUBCELLS_DONE'} = 13;
  $$format_table_ref{'POR'} = 3;
  $$fub_table_ref{$fub}{'CDR1'} = '-';
  $$format_table_ref{'CDR1'} = 6;
  $$fub_table_ref{$fub}{'PLAN_ORIG'} = '2005_06_01';
  $$format_table_ref{'PLAN_ORIG'} = 10;
  $$fub_table_ref{$fub}{'PLAN_ADJUST'} = '';
  $$format_table_ref{'PLAN_ADJUST'} = 11;
  $$fub_table_ref{$fub}{'ETA'} = '';
  $$format_table_ref{'ETA'} = 10;
  $$fub_table_ref{$fub}{'FLOW_PLAN'} = 'sag';
  $$format_table_ref{'FLOW_PLAN'} = 9;
  $$fub_table_ref{$fub}{'FLOW_ACTUAL'} = '-';
  $$format_table_ref{'FLOW_ACTUAL'} = 11;
  $$fub_table_ref{$fub}{'ORDER'} = '';
  $$format_table_ref{'ORDER'} = 11;
  $$fub_table_ref{$fub}{'PRIORITY'} = '9999';
  $$format_table_ref{'PRIORITY'} = 8;
  $$fub_table_ref{$fub}{'TAG'} = '';
  $$format_table_ref{'TAG'} = 18;
  $$fub_table_ref{$fub}{'LNF'} = 'no';
  $$format_table_ref{'LNF'} = 3;
  $$fub_table_ref{$fub}{'NTCL'} = 'no';
  $$format_table_ref{'NTCL'} = 4;
  $$fub_table_ref{$fub}{'ALFTRC'} = 'no';
  $$format_table_ref{'ALFTRC'} = 6;
  $$fub_table_ref{$fub}{'UE_MODEL'} = 'no';
  $$format_table_ref{'UE_MODEL'} = 8;
  $$fub_table_ref{$fub}{'LIB_OK'} = 'no';
  $$format_table_ref{'LIB_OK'} = 6;
  $$fub_table_ref{$fub}{'PVOPT'} = 'no';
  $$format_table_ref{'PVOPT'} = 5;
  $$fub_table_ref{$fub}{'DIRECTIVES'} = '';
  $$format_table_ref{'DIRECTIVES'} = 20;
  $$fub_table_ref{$fub}{'AUDIT'} = 'no';
  $$format_table_ref{'AUDIT'} = 5;
  $$fub_table_ref{$fub}{'PS1_STAGE'} = '';
  $$format_table_ref{'PS1_STAGE'} = 9;
  foreach my $release ('PS1', 'PS2') {
    foreach my $dim ('X', 'Y') {
      foreach my $process ('1264', '1266') {
	$$fub_table_ref{$fub}{"${release}_${process}_${dim}"} = '-';
	$$format_table_ref{"${release}_${process}_${dim}"} = 10;
      }
      $$fub_table_ref{$fub}{"${release}_SCALE_${dim}"} = '-';
      $$format_table_ref{"${release}_SCALE_${dim}"} = 11;
    }
  }
  $$fub_table_ref{$fub}{'PS2_PS1_X_DELTA'} = '-';
  $$format_table_ref{'PS2_PS1_X_DELTA'} = 14;
  $$fub_table_ref{$fub}{'PS2_PS1_Y_DELTA'} = '-';
  $$format_table_ref{'PS2_PS1_Y_DELTA'} = 14;
  $$fub_table_ref{$fub}{'FP_1266_X'} = '-';
  $$format_table_ref{'FP_1266_X'} = 10;
  $$fub_table_ref{$fub}{'FP_1266_Y'} = '-';
  $$format_table_ref{'FP_1266_Y'} = 10;
  $$fub_table_ref{$fub}{'PS2_FP_X_DELTA'} = '-';
  $$format_table_ref{'PS2_FP_X_DELTA'} = 14;
  $$fub_table_ref{$fub}{'PS2_FP_Y_DELTA'} = '-';
  $$format_table_ref{'PS2_FP_Y_DELTA'} = 14;
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




