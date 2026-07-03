# $Id: UE.pm,v 1.2 2011/06/09 23:16:01 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: UE.pm,v 1.2 2011/06/09 23:16:01 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: UE.pm
Packages: UE
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: Unified Setup Routines

=cut

package UE;


BEGIN {
  our ($WORK_AREA_ROOT_DIR, $DMSPATH, $CDSLIB, $DMSMODE, $DB_ROOT, $PROJECT, $MODEL, $DBB, $SYNC_DIR);
  our ($PROCESS_NAME, $DA_PROJECTS);
  my @env_list = ('WORK_AREA_ROOT_DIR', 'DMSPATH', 'CDSLIB', 'DMSMODE');
  @env_list = (@env_list, 'DB_ROOT', 'PROJECT', 'MODEL', 'DBB');
  @env_list = (@env_list, 'SYNC_DIR', 'PROCESS_NAME', 'DA_PROJECTS');
  foreach my $env_var (@env_list) {
    if (exists $ENV{$env_var}) {
      &Env::import($env_var);
    } else {
      die "\n-E- UE.pm: Something is wrong with your UE session:", "\$$env_var is not defined.\n\n";
    }
  }
  $WORK = $WORK_AREA_ROOT_DIR;
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw($WORK_AREA_ROOT_DIR $DMSPATH $CDSLIB $DMSMODE $DB_ROOT $PROJECT $MODEL $DBB $WORK $SYNC_DIR $PROCESS_NAME &RecompileDmspath);
}


use strict;
use warnings;
use English;
use Env;
use File::Basename;
use Cwd 'abs_path';
use DAStd;


sub RecompileDmspath {

  my $logfh = shift;
  my $dbb = shift;
  my $model = shift;
  my $cfgfile = shift;
  my $newdmsfile = shift;
  my $newcdsfile = shift;

  my $options_string = join(' ', @_);
  
  my $parent_flow = $logfh->flowname('RecompileDmspath');

  # Add proper variable path
  $DBB = $dbb;
  $MODEL = $model;
  if ($cfgfile) {
    $cfgfile = abs_path($cfgfile);
    if (-f $cfgfile) {
      $options_string .= " -usercfgfile $cfgfile";
    } else {
      die $logfh->fatalq("User config file does not exist:",$cfgfile);
    }
  }
  elsif ($ENV{'USERCFGFILE'}) {
    $options_string .= " -usercfgfile $ENV{'USERCFGFILE'}";
  }
  unless (&Tcsh($logfh, "$DMSMODE > ${newdmsfile}.modes")) {
    die $logfh->fatalq('DMSMODE generation returned non-zero exit status');
  }
  unless (&Tcsh($logfh, "(dmsCompiler_new.pl -dbtypes lay sch flp dev sim net ctl -createDms2opus $newcdsfile -outfile $newdmsfile $options_string) >& /dev/null")) {
    die $logfh->fatalq('DMSPATH recompilation for target cell returned non-zero exit status');
  }
  # Confirm existance of new file. Its non-existance is an unexpected condition.
  unless (-e $newdmsfile) {
    die $logfh->fatalq("New dmspth file: $newdmsfile was not created properly for dbb $dbb");
  }
  $logfh->flowname($parent_flow);
}


1;
	      
