# $Id: PDS.pm,v 1.1 2010/01/08 19:57:20 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: PDS.pm,v 1.1 2010/01/08 19:57:20 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: PDS.pm
Packages: PDS
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: PDS and verification based routines

=cut

package PDS;

use strict;
use warnings;
use English;
use Env;
use File::Basename;
use DAStd;


BEGIN {
  our ($PDSSTM, $PDSLOGS, $PDSPATH, $PDSSN, $PDSWORKROOT, $PDSERRFILES, $NIKE_TECH_DIR, $ICVS);
  my @env_list = ('PDSSTM', 'PDSLOGS', 'PDSPATH', 'PDSWORKROOT', 'PDSSN', 'PDSERRFILES', 'NIKE_TECH_DIR');
  @env_list = (@env_list, 'ICVS');
  foreach my $env_var (@env_list) {
    if (exists $ENV{$env_var}) {
      &Env::import($env_var);
    } else {
      die "\n-E- PdsStdLib: Something is wrong with your UE session:", "\$$env_var is not defined.\n\n";
    }
  }
  if (defined $ENV{'DA_OVR'}) {
    push @INC, $ENV{'DA_OVR'};
  } else {
    push @INC, "/nfs/iil/disks/home10/mroha/pnr/mig", "/usr/users/home2/mroha/pnr/mig";
  }

  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw($PDSSTM $PDSLOGS $PDSPATH $PDSSN $PDSWORKROOT $NIKE_TECH_DIR $ICVS %DESC_RECORD  &GenerateExplodeList &RunISS &WaiveTrcCmpErrors &RunPdsXor &GenerateSkipCellFile &AddCellsToSkipTable &RemoveCellsFromSkipTable &ReadPdsSumFile &GenerateFlowCodePairs &WriteSumCsv &ReadFilterCsv &WriteSumReports &WriteErrFiles &ReadDTTechFile %pds_lookup @CMP_RECORD_ORDER);
}

our ($DESC_KEY, $VALUE_KEY, $FLOW_KEY, $CODE_KEY);
$DESC_KEY = 'DESCRIPTION';
$VALUE_KEY = 'VALUE';
$FLOW_KEY = 'FLOW';
$CODE_KEY = 'CODE';

our %DESC_RECORD;
$DESC_RECORD{'SHORT'} = 'Text Shorts';
$DESC_RECORD{'OPEN'} = 'Text Opens';
$DESC_RECORD{'TOTAL_LAY_NODES'} = 'Total layout nodes';
$DESC_RECORD{'TOTAL_SCH_NODES'} = 'Total schematic nodes';
$DESC_RECORD{'TOTAL_LAY_DEVICES'} = 'Total layout devices';
$DESC_RECORD{'TOTAL_SCH_DEVICES'} = 'Total schematic devices';
$DESC_RECORD{'UNMATCH_LAY_NODES'} = 'Unmatched layout nodes';
$DESC_RECORD{'UNMATCH_SCH_NODES'} = 'Unmatched schematic nodes';
$DESC_RECORD{'UNMATCH_LAY_DEVICES'} = 'Unmatched layout devices';
$DESC_RECORD{'UNMATCH_SCH_DEVICES'} = 'Unmatched schematic devices';
$DESC_RECORD{'ZL'} = 'Z/L errors';
$DESC_RECORD{'BULK'} = 'Bulk connection errors';
$DESC_RECORD{'UPC'} = 'Unusable pin connection errors';
$DESC_RECORD{'TOTALS'} = 'ERROR_TOTAL';
$DESC_RECORD{'FILE'} = 'Absolute path to sumfile';
$DESC_RECORD{'BASEFILE'} = 'sumfile base name';
$DESC_RECORD{'INPUT'} = 'Input data format for PDS run';
$DESC_RECORD{'CELLNAME'} = 'Input cell name for PDS run';
$DESC_RECORD{'SUBCELLPIN'} = 'Subcell Pin Errors';
$DESC_RECORD{'TRC'} = 'Summable trcstd or trcalt errors';
$DESC_RECORD{'ERRFILES'} = 'Playerr layerr and err files from flow';
$DESC_RECORD{'ELAPSED_TIME_FORMATTED'} = 'Elapsed time formatted';
$DESC_RECORD{'ELAPSED_TIME_SECONDS'} = 'Elapsed time in seconds';


our @CMP_RECORD_ORDER;
@CMP_RECORD_ORDER = ('TOTAL_LAY_NODES', 'TOTAL_SCH_NODES', 'UNMATCH_LAY_NODES');
@CMP_RECORD_ORDER = (@CMP_RECORD_ORDER, 'UNMATCH_SCH_NODES', 'UNMATCH_LAY_DEVICES');
@CMP_RECORD_ORDER = (@CMP_RECORD_ORDER, 'UNMATCH_SCH_DEVICES', 'ZL', 'BULK', 'UPC');


our %pds_lookup;
$pds_lookup{'iil'}{"niketech1264"} = "${NIKE_TECH_DIR}/p1264.tech";
$pds_lookup{'fm'}{"niketech1264"} = "${NIKE_TECH_DIR}/p1264.tech";
$pds_lookup{'iil'}{"niketech1266"} = "/nfs/iil/disks/home10/mroha/pnr/mig/p1266.tech";
$pds_lookup{'fm'}{"niketech1266"} = "/usr/users/home2/mroha/pnr/mig/p1266.tech";



sub GenerateExplodeList {

  my $loghandle = shift;
  my $explode_record_ref = shift;
  my $explodelist = shift;

  open (EXPLODELIST, ">$explodelist") or die $loghandle->fatalq("Could not open $explodelist for writing\n");
  foreach my $cell (sort keys %{ $explode_record_ref }) {
    print EXPLODELIST "$$explode_record_ref{$cell}=${cell}\n";
  }
  close (EXPLODELIST);
}


sub GenerateSkipCellFile {

  my $loghandle = shift;
  my $skipcell_table_ref = shift;
  my $skipcell_file = shift;

  open (SKIPCELLFILE, ">$skipcell_file") or die $loghandle->fatalq("Could not open $skipcell_file for writing\n");
  foreach my $cell (sort keys %{ $skipcell_table_ref }) {
    print SKIPCELLFILE "$cell\n";
  }
  close (SKIPCELLFILE);
}


sub AddCellsToSkipTable {

 my $loghandle = shift;
 my $skipcell_table_ref = shift;
 my $skipcell_file = shift;
 my $explode_action = shift;

 my $parent_flow = $loghandle->flowname('AddCellsToSkipTable');

 $loghandle->infoq("Reading cells into skip table from file: $skipcell_file");
 open (SKIPCELLFILE, $skipcell_file) or die $loghandle->fatalq("Could not open $skipcell_file for reading\n");
 while (<SKIPCELLFILE>) {
   if (/^\s*(\S+)/) {
     my $cell = $1;
     $$skipcell_table_ref{$1} = $explode_action;
   }
 }
 close (SKIPCELLFILE);
 $loghandle->flowname($parent_flow);
}


sub RemoveCellsFromSkipTable {

  my $loghandle = shift;
  my $skipcell_table_ref = shift;

  my $remove_string = join(')|(', @_);
  $remove_string = '('.${remove_string}.')';
  
  my $parent_flow = $loghandle->flowname('RemoveCellsFromSkipTable');
  
  $loghandle->infoq("The following regex is being used to remove cells from skip list: $remove_string");
  
  foreach my $cell (sort keys %{ $skipcell_table_ref }) {
    if ($cell =~ /${remove_string}/) {
      delete $$skipcell_table_ref{$cell};
      $loghandle->infoq("Cell removed from skip list: $cell");
    }
  }

  $loghandle->flowname($parent_flow);
}





sub RunPdsXor {

  my $loghandle = shift;
  my $cell1 = shift;
  my $cell2 = shift;
  my $data1 = shift;
  my $data2 = shift;
  my @remaining_options = @_;
  my $xorstatsfile = "$PDSLOGS/${cell1}_xor.stats";
  my $xorsumfile = "$PDSLOGS/pdsxor.${cell1}.${data1}.${cell2}.${data2}.log.sum";
  my $xorabortfile = "$PDSLOGS/pdsxor.${cell1}.${data1}.${cell2}.${data2}.log.abort";
  my $xorlogfile = "$PDSLOGS/XORLOGS/pdsxor.${cell1}.${data1}.${cell2}.${data2}.log";
  my $xor1tree0file = "$PDSLOGS/XORLOGS/${cell1}.tree0_cell1";
  my $xor1tree1file = "$PDSLOGS/XORLOGS/${cell1}.tree1_cell1";
  my $xor1tree2file = "$PDSLOGS/XORLOGS/${cell1}.tree2_cell1";
  my $xor2tree0file = "$PDSLOGS/XORLOGS/${cell1}.tree0_cell2";
  my $xor2tree1file = "$PDSLOGS/XORLOGS/${cell1}.tree1_cell2";
  my $xor2tree2file = "$PDSLOGS/XORLOGS/${cell1}.tree2_cell2";
  my @xorfiles;
  my $run_is_dirty = 0;

  my $parent_flow = $loghandle->flowname('RunPdsXOR');

  @xorfiles = ($xorstatsfile, $xorsumfile, $xorabortfile, $xorlogfile, $xor1tree0file);
  @xorfiles = (@xorfiles, $xor1tree1file, $xor1tree2file, $xor2tree0file, $xor2tree1file);
  @xorfiles = (@xorfiles, $xor2tree2file);

  &DeleteFiles(@xorfiles);

  system("$DA_UTILS/lv/pdsxor -cell1 $cell1 -cell2 $cell2 -data1 $data1 -data2 $data2 @remaining_options >& /dev/null");

  # Confirm sum file was created
  if (-e $xorabortfile ) {
    die $loghandle->fatalq("PDSXOR run aborted.",
	     "See $xorabortfile");
  }
  open (XORSUM, $xorsumfile) or die $loghandle->fatalq("Could not open $xorsumfile for reading");
  while (<XORSUM>) {
    if (/^\s*(DIRTY|clean|Cell Processed:|(.+)XOR MISMATCH|(.+)xor ERRORS)/) {
      chomp;
      if (/DIRTY/) {
	$run_is_dirty = 1;
      }
      $loghandle->infoq("PDSXOR: $_");
    }
  }
  close (XORSUM);
  $loghandle->flowname($parent_flow);
  return $run_is_dirty;
}


# Valid waive codes are found above as keys of %DESC_RECORD 
sub WaiveTrcCmpErrors {

  my $loghandle = shift;
  my $pdssum = shift;
  my @waive_list = sort (@_);

  my $parent_flow = $loghandle->flowname('WaiveTrcCmpErrors');


  my %waiver_ok;
  foreach my $code (@waive_list) {
    $waiver_ok{$code} = 1;
  }
  
  $loghandle->infoq("The following errors will be waived if present: " .join(' ', @waive_list));

  my $run_is_dirty = 1;  # Assume dirty until proven otherwise
  my %error_record;
  open (PDSSUM, $pdssum) or die;
  while (<PDSSUM>) {
    # If there are summable trc errors (like illegal devices or fntap violations), run is dirty
    if (/^DIRTY\s+trc(alt|std)\S*\s+(\d+)/) {
      $error_record{'TRC'} = 1;
    }
    # Can not tolerate text shorts
    if (/SHORT_CIRCUITS:/) {
      $error_record{'SHORTS'} = 1;
    }
    if (/OPEN_CIRCUITS:/) {
      $error_record{'OPENS'} = 1;
    }
    # Z/Ls waivable, all others must be clean    
    if (/^Total(\s+\d+){9}/) {
	my @record = split;
	chomp;
	shift(@record);
	foreach my $code (@CMP_RECORD_ORDER) {
	  if ($code =~ /^TOTAL_/) {
	    shift(@record);
	  } else {
	    my $cmp_value = shift(@record);
	    if ($cmp_value > 0) {
	      $error_record{$code} = 1;
	    }
	  }
	}
      }
    if (/SEVERE ERRORS:/) {
      $error_record{'SUBCELLPIN'} = 1;
    }
  }
  close (PDSSUM);

  my @waived_errors;
  my @unwaived_errors;
  foreach my $error (sort keys %error_record) {
    if (exists $waiver_ok{$error}) {
      push (@waived_errors, $error);
    } else {
      push (@unwaived_errors, $error);
    }
  }
  if (scalar @waived_errors) {
    $loghandle->warnq("The following errors were detected and waived: " .join(' ', @waived_errors));
  }
  if (scalar @unwaived_errors) {
    $loghandle->warnq("The following errors were detected and NOT waived: " .join(' ', @unwaived_errors));
  } else {
    $loghandle->warnq("All errors waived.");
    $run_is_dirty = 0;
  }

  $loghandle->flowname($parent_flow);
  return $run_is_dirty;
}



sub RunISS {

  my $loghandle = shift;
  my $debug = shift;
  my $cell = shift;
  my $inputtype = shift;
  my $pdsflow = shift;
  my $explodelist = shift;
  my $use_gdsintp = shift;
  my $pdscellfile = "$PDSLOGS/${cell}.cell.log";
  my $pdsdatafile = "$PDSLOGS/${cell}.data.log";
  my $pdsexpfile = "$PDSLOGS/${cell}.explode.list";
  my $pdslogfile = "$PDSLOGS/${cell}.${pdsflow}.iss.log";
  my $pdssumfile = "$PDSLOGS/${cell}.${pdsflow}.iss.log.sum";
  my $pdsstdcmpfile = "$PDSLOGS/${cell}.standard.iss.cmp";
  my $pdsstdcmpallfile = "$PDSLOGS/${cell}.standard.iss.cmpall";
  my $pdsaltcmpfile = "$PDSLOGS/${cell}.alternate.iss.cmp";
  my $pdsaltcmpallfile = "$PDSLOGS/${cell}.alternate.iss.cmpall";
  my $pdsanfile = "$PDSLOGS/${cell}.analysis";
  my $pdslnsfile = "$PDSLOGS/${cell}.iss.lns";
  my $pdspinsfile = "$PDSLOGS/${cell}.sch_pins";
  my $pdsstatsfile = "$PDSLOGS/${cell}_trcstd.stats";
  my $pdsabortfile = "$PDSLOGS/${cell}.${pdsflow}.iss.log.abort";
  my @pdsfiles;
  my $run_is_dirty = 0;
  my $pds_sum_or_abort = '';
  my $parent_flow = $loghandle->flowname("RunISS-${pdsflow}");
  @pdsfiles = ($pdscellfile, $pdsdatafile, $pdsexpfile, $pdslogfile, $pdssumfile);
  @pdsfiles = (@pdsfiles, $pdsstdcmpfile, $pdsstdcmpallfile, $pdsanfile, $pdslnsfile);
  @pdsfiles = (@pdsfiles, $pdspinsfile, $pdsstatsfile,  $pdsabortfile);
 
  &DeleteFiles(@pdsfiles);
  # Decide which files to delete later

  # Oh brother
  if ($inputtype =~ /lnf/i) {$inputtype = 'LNF'};
  if ($inputtype =~ /stm/i) {$inputtype = 'stm'};
  if ($inputtype =~ /alf/i) {$inputtype = 'alf'};

  if ($use_gdsintp) {
    $ENV{'GDSINTP'} = 'YES';
  } else {
    $ENV{'GDSINTP'} = 'NO';
  }

  unless (-f $explodelist) {
    $explodelist = 'DEFAULT';
  }

  # Since we could be running the same block on the same machine, but in different work areas, set a random number for the PDSWORKROOT (which shared on the local disk)
  my $pdsworkroot_area_set = 0;
  my $pdsworkroot_suffix;
  my $orig_pdsworkroot = $PDSWORKROOT;
  my $newpdsworkroot;
  my $random_pdsroot_suffix_range = 10000;
  until ($pdsworkroot_area_set) {
    srand;
    $pdsworkroot_suffix = int(rand($random_pdsroot_suffix_range));
    $newpdsworkroot = "${PDSWORKROOT}/RUNISS_${cell}_${pdsworkroot_suffix}";
    $newpdsworkroot =~ s/\/\//\//g;
    $loghandle->infoq("Trying to assign new PDSWORKROOT area: $newpdsworkroot");
    unless (-d $newpdsworkroot) {
      &CreateDirTrees($newpdsworkroot);
      $PDSWORKROOT = $newpdsworkroot;
      $pdsworkroot_area_set = 1;
      $loghandle->infoq("New PDSWORKROOT area set: $ENV{'PDSWORKROOT'}");
    }
  }
  my $saveworkdir;
  if ($debug) {
    $saveworkdir = 'yes';
  } else {
    $saveworkdir = 'no';
  }

  unless (&Tcsh($loghandle, "$PDSPATH/_pdsbuilder.new -database ' ' -laytopcell $cell -mode $pdsflow -saveworkdir $saveworkdir -mailuser no -ecn ECNOFF -runmode local -incremental no -newinc ' ' -autotail no -signallist ' ' -verifytool cmp -inputtype $inputtype -trcpin top -commandfile ' ' -laychangefile ' ' -topframe nocheck -outtype apl -sigfiles ' ' -skipcvsin no -calcres no -batch1 HIDE -skewtype TTTT -tooltype iss -explode $explodelist -autohmsprt no -smshopt relax -dvssmshfile none -ltlinpath none -ltloutpath none -groupdir none -chkptdir none -libspec $cell -lnpath ' ' -batch2 HIDE -batch3 HIDE -onecell no -crosscap none -make_sn 1 -fg yes -snname DEFAULT >& /dev/null")) {
    $loghandle->warnq("PDS builder call returned non-zero exit status. See logfile.");
  }

  
  unless ($debug) {
    &DeleteDirTrees($newpdsworkroot);
  }

  # Confirm sum file was created and has valid contents
  if (-e $pdsabortfile ) {
    $loghandle->warnq("PDS $pdsflow run aborted.");
    $run_is_dirty = 1;
    $pds_sum_or_abort = $pdsabortfile;
  } else {
    open (PDSSUM, $pdssumfile) or die $loghandle->fatalq("Could not open $pdssumfile for reading");
    #Summary
    while (<PDSSUM>) {
      if (/^\s*(DIRTY|clean|(Total\s+\d+\s+\d+))|lay\s+sch|[dD]evices|Unmatched|Nodes|(Input Data Type)|(FLOW = cvscmp)|Flow|Tool|(SHORT|OPEN)_CIRCUITS:|(SubCell Pin error in layout cells)/) {
	chomp;
	if (/DIRTY/) {
	  $run_is_dirty = 1;
	}
	$loghandle->infoq($_); 
      }
    }
    close (PDSSUM);
    open (PDSLOG, $pdslogfile) or die $loghandle->fatalq("Could not open $pdslogfile for reading");
    while (<PDSLOG>) {
      if (/Library Byte Count/) {
	chomp;
	$loghandle->infoq($_);
	last;
      }
    }
    close (PDSLOG);
    $pds_sum_or_abort = $pdssumfile;
  }
  
  $PDSWORKROOT = $orig_pdsworkroot;
  $loghandle->flowname($parent_flow);
  return ($run_is_dirty, $pds_sum_or_abort);
}


sub ReadPdsSumFile {

  my $loghandle = shift;
  my $sumfile = shift;
  my $data_table_ref = shift;
  my $duplicate_code_record_ref = shift;
  my $debug = shift;
  my $flow;
  my $in_flow_section = 0;
  my $value;
  my $code;
  my $description;
  my $cmp_value;
  my $extension;
  my @record;
  my $totals_code;
  my $totals_description;
  my $warn_if_duplicate_code;
  my $record_only;

  my $current_routine = 'ReadPdsSumFile';

  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname($current_routine);

  open(SUMFILE, $sumfile) or die $loghandle->fatalq("Could not open sumfile for reading: $sumfile");
  while (<SUMFILE>) {
    if (/Input Data Type = (\S+)/) {
      $flow = $current_routine;
      $$data_table_ref{$sumfile}{$flow}{'INPUT'}{$DESC_KEY} = $DESC_RECORD{'INPUT'};
      $$data_table_ref{$sumfile}{$flow}{'INPUT'}{$VALUE_KEY} = $1;
    }
    if (/Cell Processed:\s+(\S+)/) {
      $flow = $current_routine;
      $$data_table_ref{$sumfile}{$flow}{'CELLNAME'}{$DESC_KEY} = $DESC_RECORD{'CELLNAME'};
      $$data_table_ref{$sumfile}{$flow}{'CELLNAME'}{$VALUE_KEY} = $1;
    }
    if (/Wallclock Time:\s+(.+)/) {
      my $wallclock_time = $1;
      chomp($wallclock_time);
      $wallclock_time =~ s/,/ /;
      my @record = split (/\s+/, $wallclock_time);
      my $days = $record[0];
      my $hours = $record[2];
      my $minutes = $record[4];
      my $seconds = $record[7];
      my $total_seconds = &ConvertElapsedTimeToSeconds($days, $hours, $minutes, $seconds);
      $flow = $current_routine;
      $$data_table_ref{$sumfile}{$flow}{'ELAPSED_TIME_FORMATTED'}{$DESC_KEY} = $DESC_RECORD{'ELAPSED_TIME_FORMATTED'};
      $$data_table_ref{$sumfile}{$flow}{'ELAPSED_TIME_FORMATTED'}{$VALUE_KEY} = $wallclock_time;
      $$data_table_ref{$sumfile}{$flow}{'ELAPSED_TIME_SECONDS'}{$DESC_KEY} = $DESC_RECORD{'ELAPSED_TIME_SECONDS'};
      $$data_table_ref{$sumfile}{$flow}{'ELAPSED_TIME_SECONDS'}{$VALUE_KEY} = $total_seconds;
    } 
    if (/\* FLOW =\s+(\S+)\s+(\w+)?/) {
      $flow = "XOR";
      $extension = $2;
      $loghandle->infod("Flow found:  Flow=${flow}") if $debug;
      if ($extension) {
	$loghandle->infod("Extension=${extension}") if $debug;
	$flow .= "_${extension}";
      }
      $totals_code = "$DESC_RECORD{'TOTALS'}_${flow}";
      $totals_description = "Total error markers for flow: $flow";
      $in_flow_section = 1;
    } 
    if ($in_flow_section) {
      if (/^\s*(\d+)\s+(\S+)\s+(.*)/) {
	$value = $1;
	$code = $2;
	$description = $3;
	chomp($description);
	$description =~ s/\,/ /g;
	if ($code =~ /^grid$/) {
	  $code = 'OFF-GRID';
	  $description = 'grid violations found.';
	}
	elsif ($code =~ /Bad_Gap/) {
	  if ($description =~ /(PRD|NRD)/) {
	    $code .= "_${1}";
	  }
	}
	elsif ($code !~ /(\S+_\S+)|(UNK)|(illdev)/) {
	  $code .= " $description";
	  $description = $code;
	}
	if ($description =~ /TOTAL\s+\S+\s+ERRORS/) {
	  $code = $totals_code;
	  $description = $totals_description;
	}
	$loghandle->infod("Found DRC style error code: Code: $code   Descrip: $description") if $debug;

	$warn_if_duplicate_code = 1;
	$record_only = 1;
	&RecordValue($loghandle, $data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, $value, $code, $description, $record_only, $warn_if_duplicate_code);
      }
      elsif (/SHORT_CIRCUITS:/) {
	$code = 'SHORT';
	$description = $DESC_RECORD{$code};
	$$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
	$$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = 0;
      }
      elsif (/OPEN_CIRCUITS:/) {
	$code = 'OPEN';
	$description = $DESC_RECORD{$code};
	$$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
	$$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = 0;
      }
      # Text short or text open format
      elsif (/^\S+\s+\S+((\(\d+\;\d+\)\s+\S+\(\d+\;\d+\))|(\s+\d+\;\d+))/) {
	chomp;
	if ($debug) {
	  $loghandle->infod("Found TRC style error code: $code", $_);
	}
	$warn_if_duplicate_code = 0;
	$record_only = 0;
	&RecordValue($loghandle, $data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, 1, $code, $description, $record_only, $warn_if_duplicate_code);
	# For trc, opens and shorts don't get tallied in the totals section, so add them here
	&RecordValue($loghandle, $data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, 1, $totals_code, $totals_description, $record_only, $warn_if_duplicate_code);
      }
      elsif (/^\S+: (\d+) total (schematic|layout) devices\s*$/) {
	$value = $1;
	if ($2 eq 'schematic') {
	  $code = 'TOTAL_SCH_DEVICES';
	} else {
	  $code = 'TOTAL_LAY_DEVICES';
	}
	$description = $DESC_RECORD{$code};
	$warn_if_duplicate_code = 1;
	$record_only = 1;
	&RecordValue($loghandle, $data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, $value, $code, $description, $record_only, $warn_if_duplicate_code);
      }
      elsif (/^Total(\s+\d+){9}/) {
	@record = split;
	chomp;
	if ($debug) {
	  $loghandle->infod("Found CMP style error code", $_);
	}
	shift(@record);
	my $total_cmp_errors = 0;
	foreach $code (@CMP_RECORD_ORDER) {
	  $cmp_value = shift(@record);
	  $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	  $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = $cmp_value;
	  $total_cmp_errors += $cmp_value;
	}
	$code = $totals_code;
	$description = $totals_description;
	$warn_if_duplicate_code = 1;
	$record_only = 1;
	&RecordValue($loghandle, $data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, $total_cmp_errors, $code, $description, $record_only, $warn_if_duplicate_code);	
      }
      elsif (/\.(play|lay|h)err\s*$/) {
	@record = split;
	$value = pop(@record);
	$value = basename($value);
	$code = 'ERRFILES';
	$$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $DESC_RECORD{$code};
	$$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} .= "${value} ";
      }
    }
  }
  close (SUMFILE);
  
  my $base_sumfile = basename($sumfile);
  $flow = $current_routine;
  $$data_table_ref{$sumfile}{$flow}{'FILE'}{$DESC_KEY} = $DESC_RECORD{'FILE'};
  $$data_table_ref{$sumfile}{$flow}{'FILE'}{$VALUE_KEY} = $sumfile;
  $$data_table_ref{$sumfile}{$flow}{'BASEFILE'}{$DESC_KEY} = $DESC_RECORD{'BASEFILE'};
  $$data_table_ref{$sumfile}{$flow}{'BASEFILE'}{$VALUE_KEY} = $base_sumfile;

  $loghandle->flowname($parent_flow);
}


sub RecordValue {

  my $loghandle = shift;
  my $data_table_ref = shift;
  my $duplicate_code_record_ref = shift;
  my $sumfile = shift;
  my $flow = shift;
  my $value = shift;
  my $code = shift;
  my $description = shift;
  my $record_only = shift;
  my $warn_if_duplicate_error = shift;

  if (exists $$duplicate_code_record_ref{$sumfile}{$flow}{$code}) {
    $loghandle->warn("A duplicate error code was parsed from sum file: $sumfile", "Code: $code") if $warn_if_duplicate_error;
    if ($record_only) {
      my $max_dup_index = 0;
      foreach my $codestring (sort keys %{ $$data_table_ref{$sumfile}{$flow} }) {
	if ($codestring =~ /${code}_ISSDUP(\d+)$/) {
	  if ($1 > $max_dup_index) {
	    $max_dup_index = $1;
	  }
	}
      }
      $max_dup_index++;
      $code = "${code}_ISSDUP${max_dup_index}";
      $$duplicate_code_record_ref{$sumfile}{$flow}{$code} = 1;
      $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = $value;
      $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
      $loghandle->warn("Duplicate key found. Synthesized new error code: $code") if $warn_if_duplicate_error;
    } else {
      $loghandle->warn("Adding conflicting error counts") if $warn_if_duplicate_error;
      $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
      $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} += $value;
    }
  } else {
    $$duplicate_code_record_ref{$sumfile}{$flow}{$code} = 1;
    $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY} = $description;
    $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} = $value;
  }
}


sub MergeLogDataIntoDataTable {

  my $loghandle = shift;
  my $data_table_ref = shift;
  my $log_record_ref = shift;
  my $duplicate_code_record_ref = shift;
  my $debug = shift;
  my $sumfile;
  my $flow;
  my $code;
  my $value;
  my $description;
  
  my $record_only = 1;
  my $warn_if_duplicate_code = 1;

  foreach $sumfile (sort keys %{ $data_table_ref }) {
    foreach $flow (sort keys %{ $log_record_ref }) {
      foreach $code (sort keys %{ $$log_record_ref{$flow} }) {
	$value = $$log_record_ref{$flow}{$code}{$VALUE_KEY};
	$description = $$log_record_ref{$flow}{$code}{$DESC_KEY};
	&RecordValue($data_table_ref, $duplicate_code_record_ref, $sumfile, $flow, $value, $code, $description, $record_only, $warn_if_duplicate_code);
	$loghandle->infod("Logged value into data table: Flow: $flow  Code: $code  Value: $value") if $debug;
      }
    }
  }
}


sub GenerateFlowCodePairs {

  my $data_table_ref = shift;
  my $merged_codes_table_ref = shift;
  my $sumfile;
  my $flow;
  my $code;
  
  foreach $sumfile (keys %{$data_table_ref}) {
    foreach $flow (keys %{$$data_table_ref{$sumfile}}) {
      foreach $code (keys %{$$data_table_ref{$sumfile}{$flow}}) {
	$$merged_codes_table_ref{$flow}{$code} = 
	  $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY};
      }
    }
  }
}


sub WriteSumCsv {

  my $loghandle = shift;
  my $csvoutfile = shift;
  my $sumfile_list_ref = shift;
  my $data_table_ref = shift;
  my $merged_codes_table_ref = shift;
  my @value_list = ();
  my $record;
  my $sumfile;
  my $flow;
  my $code;
  my $value;
    
  open (CSVOUT, ">$csvoutfile") or die $loghandle->fatalq("Could not open csv outfile for writing: $csvoutfile");
  my @header;
  my $field;
  my @csvfield_list = ($FLOW_KEY, $CODE_KEY, @{$sumfile_list_ref}, $DESC_KEY);
  foreach $field (@csvfield_list) {
    if ( $$data_table_ref{$field}) {
      push(@header, $$data_table_ref{$field}{'ReadPdsSumFile'}{'BASEFILE'}{$VALUE_KEY});
    } else {
      push(@header, $field);
    }
  }
  
  $record = join(',', @header);
  print CSVOUT "$record\n";
  foreach $flow (sort keys %{$merged_codes_table_ref}) {
    foreach $code (sort keys %{$$merged_codes_table_ref{$flow}}) {
      @value_list = ($flow, $code);
      foreach $sumfile (@ {$sumfile_list_ref}) {
	$value = 0;
	# You have to do this
	if (exists $$data_table_ref{$sumfile}) {
	  if (exists $$data_table_ref{$sumfile}{$flow}) {
	    if (exists $$data_table_ref{$sumfile}{$flow}{$code}) { 
	      if (exists $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY}) {
		$value = $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY};
	      }
	    } 
	  }
	}
	push (@value_list, $value);
      }
      push (@value_list, $$merged_codes_table_ref{$flow}{$code});
      $record = join(',', @value_list);
      print CSVOUT "$record\n";
      @value_list = ();
    }
  }
  close (CSVOUT);  
}


sub ReadFilterCsv {

  my $loghandle = shift;
  my $filtercsv = shift;
  my $filter_table_ref = shift;

  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname('ReadFilterCsv');

  my @field_list;
  open (FILTERCSV, $filtercsv) or die $loghandle->fatalq("Could not open filter csv file for read: $filtercsv");
  while (<FILTERCSV>) {
    my @record = split(/,/, $_);
    if ($. == 1) {
      for (my $i=0; $i<=$#record; $i++) {
	if ($record[$i] =~ /\w/) {
	  if ($record[$i] =~ /comment/i) {
	    last;
	  } else {
	    $field_list[$i] = $record[$i];
	  }
	} else {
	  die $loghandle->fatalq("Invalid field header value in input CSV");
	}
      }
    } else {
      my $flow = $record[0];
      my $error_code = $record[1];
      for (my $i=2; $i<=$#field_list; $i++) {
	$$filter_table_ref{$field_list[$i]}{$error_code} = $record[$i];
      }
    }
  }
  close (FILTERCSV);

  $loghandle->flowname($parent_flow);
}


sub WriteSumReports {

  my $loghandle = shift;
  my $file_prefix = shift;
  my $sumfile_list_ref = shift;
  my $data_table_ref = shift;
  my $filter_table_ref = shift;
  my $flowre = shift;

  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname('WriteSumReports');

  unless ($flowre) {
    $flowre = '.';
  }  
  foreach my $filter (sort keys %{ $filter_table_ref }) {
    my $reportfile = "${file_prefix}.report.${filter}";
    my $reportfilecsv = "${file_prefix}.report.${filter}.csv";
    open (REPORTFILE, ">$reportfile") or die $loghandle->fatalq("Could not open report file for output: $reportfile");
    open (REPORTCSV, ">$reportfilecsv") or die $loghandle->fatalq("Could not open csv report for output: $reportfilecsv");
    my @header = ('SUMFILE', 'CELL', 'FLOW', 'ERROR', 'COUNT', 'DESCRIPTION');
    print REPORTCSV join(',', @header) . "\n";
    foreach my $sumfile (sort keys %{ $data_table_ref }) {
      my $reportsum = $$data_table_ref{$sumfile}{'ReadPdsSumFile'}{'BASEFILE'}{$VALUE_KEY};
      my $reportcell = $$data_table_ref{$sumfile}{'ReadPdsSumFile'}{'CELLNAME'}{$VALUE_KEY};
      print REPORTFILE "##### Sum File: $reportsum #####\n";
      print REPORTFILE "##### Cell: $reportcell #####\n\n";
      foreach my $flow (sort keys %{ $$data_table_ref{$sumfile} }) {
	if (($flow =~ /$flowre/) and ($flow ne 'ReadPdsSumFile')) {
	  my $filter_error_sum = 0;
	  my $original_flow_total = 'NOT AVAILABLE';
	  print REPORTFILE "### Flow: $flow ###\n";
	  foreach my $code (sort keys %{ $$data_table_ref{$sumfile}{$flow} }) {
	    my $code_with_dups_removed = $code;
	    $code_with_dups_removed =~ s/(_ISSDUP\d+)$//;
	    unless ((exists $$filter_table_ref{$filter}{$code_with_dups_removed}) and ($$filter_table_ref{$filter}{$code_with_dups_removed} =~ /disable/i)) {
	      my $filter_multiplier = 1;
	      
	      if (exists $$filter_table_ref{$filter}{$code_with_dups_removed} and $$filter_table_ref{$filter}{$code_with_dups_removed} =~ /^\d*\.\d+$/) {
		$filter_multiplier = $$filter_table_ref{$filter}{$code_with_dups_removed};
	      }
	      if ($$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY} =~ /^\d+$/) {
		if ($code =~ /^ERROR_TOTAL_/) {
		  $original_flow_total = $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY};
		} else {
		  my $scaled_error_count = &Round($filter_multiplier * $$data_table_ref{$sumfile}{$flow}{$code}{$VALUE_KEY});
		  my $newcode = $code;
		  if ($filter_multiplier =~ /^(\d*)\.\d+$/) {
		    $newcode = "${code}($filter_multiplier)";
		  }
		  printf REPORTFILE "%-20s %-25s %-10s %-s\n", $flow, $newcode, $scaled_error_count, $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY};
		  my @csvrecord = ($reportsum, $reportcell, $flow, $newcode, $scaled_error_count, $$data_table_ref{$sumfile}{$flow}{$code}{$DESC_KEY});
		  print REPORTCSV join(',', @csvrecord) . "\n";
		  $filter_error_sum += $scaled_error_count;
		}
	      }
	    }
	  }
	  my $filter_error_sum_div_4;
	  my $original_flow_total_div_4;
	  # Just want to make sure that 3 errors or less is still a div4 error
	  if (${filter_error_sum} < 4) {
	    $filter_error_sum_div_4 = ${filter_error_sum}%4;
	  } else {
	    $filter_error_sum_div_4 = int(${filter_error_sum}/4);
	  }
	  if (${original_flow_total} < 4) {
	    $filter_error_sum_div_4 = ${original_flow_total}%4;
	  } else {
	    $original_flow_total_div_4 = int(${original_flow_total}/4);
	  }
	  my $printstring = sprintf "### Errors To Fix  : %-20s %-25s %-17s %-s", "filter->($filter)", "flow->($flow)", "total->($filter_error_sum)", "Div4->($filter_error_sum_div_4)";
	  printf REPORTFILE "\n$printstring\n";
	  $loghandle->infop($printstring);
	  unless ($original_flow_total eq 'NOT AVAILABLE') {
	    printf REPORTFILE "### Original Errors: %-20s %-25s %-17s %-s\n", "filter->(none)", "flow->($flow)", "total->($original_flow_total)", "Div4->($original_flow_total_div_4)";
	  }
	  print REPORTFILE "\n";
	}
      }
      print REPORTFILE "\n";
    }
    close (REPORTFILE);
  }
  $loghandle->flowname($parent_flow);
}


sub WriteErrFiles {

  my $loghandle = shift;
  my $sumfile_list_ref = shift;
  my $data_table_ref = shift;
  my $filter_table_ref = shift;
  my $flowre = shift;

  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname('WriteSumReports');

  unless ($flowre) {
    $flowre = '.';
  }
  
  foreach my $filter (sort keys %{ $filter_table_ref }) {
    foreach my $sumfile (sort keys %{ $data_table_ref }) {
      my $cell = $$data_table_ref{$sumfile}{'ReadPdsSumFile'}{'CELLNAME'}{$VALUE_KEY};
      foreach my $flow (sort keys %{ $$data_table_ref{$sumfile} }) {
	if (($flow =~ /$flowre/) and ($flow ne 'ReadPdsSumFile')) {
	  opendir (PDSLOGS, $PDSLOGS) or die $loghandle->fatalq("Could not open pdslogs dir for reading: $PDSLOGS");
	  if (defined $$data_table_ref{$sumfile}{$flow}{'ERRFILES'}{$VALUE_KEY}) {
	    my $err_string = $$data_table_ref{$sumfile}{$flow}{'ERRFILES'}{$VALUE_KEY};
	    my @record = split(/\s+/, $err_string);
	    foreach my $errfile (@record) {
	      my $origerr = "${PDSERRFILES}/${errfile}";
	      $loghandle->infoq("Reading err file: $origerr");
	      my $filtererr = $origerr;
	      $filtererr =~ s/\.(\w+)$/_${filter}\.${1}/;
	      unless (-e $origerr) {
		$loghandle->warnq("Could not open err file that is listed in .sum file. Skipping: $origerr");
		&DeleteFiles($filtererr);
		next;
	      }
	      open (ORIGERR, $origerr) or die $loghandle->fatalq("Could not open original err file for read: $origerr");
	      open (FILERR, ">$filtererr") or die $loghandle->fatalq("Could not open filter err file for write: $filtererr");
	      my $nonfiltered_error_detected = 0;
	      my $write_error = 1;
	      my $start_paren_count = 0;
	      my $paren_depth = 0;
	      while (<ORIGERR>) {
		if (/^\s+\(ErrorSet \"(\S+)\"\s+\"\d+\"\s*$/) {
		  $start_paren_count = 1;
		  my $error_code = $1;
		  if ((exists $$filter_table_ref{$filter}{$error_code}) and ($$filter_table_ref{$filter}{$error_code} =~ /disable/i)) {
		    $write_error = 0;
		  } else {
		    $nonfiltered_error_detected = 1;
		    $write_error = 1;
		  }
		}
		if ($write_error) {
		  print FILERR $_;
		}
	      }
	      unless ($write_error) {
		print FILERR ")\n";
	      }
	      close (ORIGERR);
	      close (FILERR);
	      if ($nonfiltered_error_detected) {
		$loghandle->infoq("Filtered err file written: $filtererr");
	      } else {
		$loghandle->warnq("No valid errors for filter:($filter) in err file. Deleting: $filtererr");
		&DeleteFiles($filtererr);
	      }
	    }
	  }
	}
      }
    }
  }
}
		

sub ReadDTTechFile {

  my $loghandle = shift;
  my $techfile = shift;
  my $tech_table_ref = shift;
  
  my $parent_flow = $loghandle->flowname('ReadDTTechFile');
  open (TECHFILE, $techfile) or die;
  while (<TECHFILE>) {
    if (/^\s*\#/) {
      next;
    }
    if (/\((\s*)generic\s+(\S+)\s+(\d+)\s+/) {
      my $tag = $2;
      my $value = int($3);
      if ($tag =~ /LAYERNUM|DATATYPE/i) {
        $$tech_table_ref{'DTTECH'}{uc($tag)} = $value;
      }
    }
  }
  close (TECHFILE);
  
  my $newtag;
  my $layer;
  my $type;
  foreach my $tag (sort keys %{ $$tech_table_ref{'DTTECH'} }) {
    $newtag = $tag;
    $newtag =~ s/DEVICE|WIRE|TAP//;
    $newtag =~ s/ICVSDEBUG/FUSEID/;
    $newtag =~ s/NWELLRESISTOR/WELLRESID/;
    $newtag =~ s/V00RECTVIA0/VIA0VIRTUAL/;
    $newtag =~ s/V00RECTVIA1/VIA1VIRTUAL/;
    $newtag =~ s/HORIZRM1PIN/RM1PIN/;
    $newtag =~ s/PD(LAYERNUM|DATATYPE)/PORTDRAWING${1}/;
    $newtag =~ s/VIA9/PADC4/;
    $newtag =~ s/ASYM/C4BUMP/;
    $newtag =~ s/BITCELL0_EDGE/ARRAYIDPORTDRAWING/;
    if ($newtag =~ /(\S+)(LAYERNUM|DATATYPE)/) {
      $layer = $1;
      $type = $2;
      $$tech_table_ref{'MODTECH'}{$layer}{$type} = $$tech_table_ref{'DTTECH'}{$tag};
    } else {
      die $loghandle->fatalq("Something is wrong, unexpected value.  Tag: $newtag");
    }
  }
  # Manufacture port data type
  foreach $layer (sort keys %{ $$tech_table_ref{'MODTECH'} }) {
    if ($$tech_table_ref{'MODTECH'}{$layer}{'DATATYPE'} == 0) {
      my $portlayer = "${layer}PORTDRAWING";
      $$tech_table_ref{'MODTECH'}{$portlayer}{'LAYERNUM'} = $$tech_table_ref{'MODTECH'}{$layer}{'LAYERNUM'};
      $$tech_table_ref{'MODTECH'}{$portlayer}{'DATATYPE'} = $$tech_table_ref{'DTTECH'}{'PORTDATATYPE'};
    }
  }

  $loghandle->flowname($parent_flow);
}


1;
	      
