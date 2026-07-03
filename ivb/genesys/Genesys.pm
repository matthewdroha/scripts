# $Id: Genesys.pm,v 1.1 2010/01/08 19:57:06 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: Genesys.pm,v 1.1 2010/01/08 19:57:06 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: Genesys.pm
Packages: Genesys
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: PDS and verification based routines

=cut

package Genesys;


BEGIN {
  our ($GENESYS, $GENESYS_MACROS, $GENESYS_DIR);
  my @env_list = ('GENESYS', 'GENESYS_MACROS', 'GENESYS_DIR');
  foreach my $env_var (@env_list) {
    if (exists $ENV{$env_var}) {
      &Env::import($env_var);
    } else {
      die "\n-E- Genesys.pm: Something is wrong with your UE session:", "\$$env_var is not defined.\n\n";
    }
  }
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw($GENESYS $GENESYS_MACROS $GENESYS_DIR &GenesysOpenSession &GenesysCloseSession &GenesysTouchAndWaitForFile &GenesysOpenCell &GenesysDiscardAll &GenesysCommandLine &GenesysLoadModules &GenesysSaveAllWithPrefix &GenesysSaveStm &CheckGenesysPreProcess &RunGenesysMacro);
}


use strict;
use warnings;
use English;
use Env;
use File::Basename;
use DAStd;
use UE;


sub GenesysOpenSession {

  my $logfh = shift;
  my $genesyslog = shift;
  my $parentfh = select;  # Capture existing value
  my $genesys_cmd_line;

  local *GENESYSFH;

  $genesys_cmd_line = "$GENESYS_DIR/ConfigFiles/nike.wrapper $GENESYS_DIR/bin/genesys -nullgt";
  open (GENESYSFH, "| $genesys_cmd_line > $genesyslog 2>&1") or die
    $logfh->fatalq("Could not open a pipe to Genesys");
  select(GENESYSFH);
  $| = 1;

  select($parentfh);
  return *GENESYSFH;
}


sub GenesysCloseSession {

  my $logfh = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);   

  print "exit -noask\n";
  close ($genesysfh);
  select($parentfh);
}


sub GenesysTouchAndWaitForFile {

  my $logfh = shift;
  my $genesysfh = shift;
  my $flagfile = shift;
  my $poll_interval = shift;
  my $parentfh = select($genesysfh);
  
  if (-e $flagfile) {
    die $logfh->fatalq("Flagfile detected before polling started:", $flagfile);
  }
  print "exec touch $flagfile\n";
  &PollForFile($flagfile, $poll_interval);

  select($parentfh);
}


sub GenesysOpenCell {

  my $logfh = shift;
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
    # Never did figure out what -noask does, it does not work
    # Flag this when commands get wrapped
    print "no\n";
  }
  select($parentfh);
}


sub GenesysDiscardAll {

  my $logfh = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);

  print "DiscardAll\n";
  print "yes\n";

  select($parentfh);
}


sub GenesysCommandLine {

  my $logfh = shift;
  my $genesysfh = shift;
  my $genesys_command = shift;
  my $parentfh = select($genesysfh);

  print "\n$genesys_command\n";

  select($parentfh);
}


sub GenesysLoadModules {

  my $logfh = shift;
  my $genesysfh = shift; 
  my $tcl_module_list_ref = shift;
  my $parentfh = select($genesysfh);
  my $tclfile;
  my $at_least_one_module_bad = 0;

  # Very dirty way for doing this right now...
  # Assume if the file exists it is OK
  foreach $tclfile (@{$tcl_module_list_ref}) {
    if (-e $tclfile) {
      print "source $tclfile\n";
      $logfh->infod("Sourcing TCL module:", $tclfile);
    } else {
      $logfh->fatalq("Could not load TCL module into Genesys:", $tclfile);
      my $at_least_one_module_bad = 1;
    }
  }
  if ($at_least_one_module_bad) {
    die $logfh->fatalq("At least one TCL file not sourced properly into Genesys");
  }
  select($parentfh);
}


sub GenesysSaveAllWithPrefix {

  my $logfh = shift;
  my $basefile = shift;
  my $tmpfiles_ref = shift;
  my $cell = shift;
  my $view = shift;
  my $prefix = shift;
  my $outdir = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  my $dir;
  my $expected_outfile;
  my $saveall_flag = "${WORK}/genesys/${basefile}.saveall_flag";
  my $prefix_with_flag;

  &DeleteFiles($saveall_flag);
  push (@{$tmpfiles_ref}, $saveall_flag);
  if (&CreateDirTrees($outdir)) {
    die $logfh->fatalq("Could not create directory for lnf save:", $outdir);
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
    die $logfh->fatalq("Genesys output not written out. Expected:", $expected_outfile);
  }

  select($parentfh);
}


sub GenesysSaveStm {
  my $logfh = shift;
  my $cell = shift;
  my $path = shift;
  my $genesysfh = shift;
  my $parentfh = select($genesysfh);
  
  print "\nSaveAs -cellname $cell -viewname stm -convertToCuts -path ${path}/${cell}.stm\n";
  select ($parentfh);
}


sub CheckGenesysPreProcess {

  my $logfh = shift;
  my $tmpfiles_ref = shift;
  my $genesyslog = shift;

  my $parent_flow = $logfh->flowname('CheckGenesysPreProcess');

  open (GENESYSLOG, $genesyslog) or die $logfh->fatalq("Could not open $genesyslog for reading");
  
  while (<GENESYSLOG>) {
    if (/getCellHeightWidth/) {
      chomp;
      $logfh->infoq($_);
    }
    if (/invalid command name(.+)Baa/) {
      chomp;
      $logfh->infoq($_);
      die $logfh->fatalq("Problem occurred during LNF pre-processing. See Genesys log file:", $genesyslog);
    }
    if (/Error messages will be written to (GDSII\S+)\s+$/) {
      push (@{$tmpfiles_ref}, "${WORK}/${1}");
    }
  }
  close (GENESYSLOG);
  
  $logfh->flowname($parent_flow);
}


sub RunGenesysMacro {

  my $logfh = shift;
  my $tmpfiles_ref = shift;
  my $commandfile = shift;
  my $command = shift;
  my $localmacrofile = shift;
  my $outputlog = shift;
  my $parent_flow = $logfh->flowname('RunMacroFile');

  my $localmacrofilefh = new IO::File;
  $localmacrofilefh->open(">$localmacrofile") or die $logfh->fatalq("Could not open file for writing: $localmacrofile");
  $localmacrofilefh->printf("source $commandfile\n");
  $localmacrofilefh->printf("$command\n");
  $localmacrofilefh->printf("exit -noask\n");
  $localmacrofilefh->close;

  my $genesys_command = "\$GENESYS_DIR/ConfigFiles/nike.wrapper \$GENESYS_DIR/bin/genesys -nullgt -file $localmacrofile >& $outputlog";
  &Tcsh($logfh, $genesys_command);

  $logfh->flowname($parent_flow);
}


1;
	      
