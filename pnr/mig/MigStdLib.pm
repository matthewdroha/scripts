# $Id: MigStdLib.pm,v 1.29 2006/03/02 02:01:58 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: MigStdLib.pm,v 1.29 2006/03/02 02:01:58 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not `be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: MigStdLib.pm
Packages: MigStdLib
Project: Penryn
Original Author: Matthew Roha

Functional Description: Standard library to support Sagantec migration work

=cut

package MigStdLib;

use strict;
use warnings;
use English;
use Env;

BEGIN {
  our ($SAGROOT, $PERLLIB);
  if (exists $ENV{'SAGROOT'}) {
    $ENV{'PERLLIB'} = "$ENV{SAGROOT}/lib";
    &Env::import('SAGROOT');
    our %mig_utils;
    if (defined $ENV{'DA_OVR'}) {
      $mig_utils{'iil'} = $ENV{'DA_OVR'};
      $mig_utils{'fm'} = $ENV{'DA_OVR'};
    } else {
      $mig_utils{'iil'} = "/nfs/iil/disks/home10/mroha/pnr/mig";
      $mig_utils{'fm'} = "/usr/users/home2/mroha/pnr/mig";
    }
    push @INC, values %mig_utils;
  } else {
    die "\n-E- MigStdLib.pm: \$SAGROOT variable does not exist\n\n";
  }
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw(&SagantecLayconv &Polar &SagPerlCifIO &Harvest1265 &ReadPdbFile &GenerateLayconvMapFile $SAGROOT %mig_utils %mig_lookup @mig_tcl_modules_list $mig_pdb_file %mig_tech_file_table $mig_input_process $mig_output_process $mig_intermediate_process %mig_mode_table @mig_stage_list &InitMigFileTable &GetMigReleaseStatus &ConvertCifToStm &GetFubCode $idc_lic_path);
}

use DAStdLib;

my $SITE = &GetSite;

our %mig_utils;
our @mig_tcl_modules_list;
@mig_tcl_modules_list = ("$mig_utils{$SITE}/mig.tcl");
our $mig_pdb_file;
$mig_pdb_file = "$mig_utils{$SITE}/mig.pdb";
our $mig_input_process;
$mig_input_process = '1264';
our $mig_output_process;
$mig_output_process = '1266';
our $mig_intermediate_process;
$mig_intermediate_process = '1265';
our $idc_lic_path;
$idc_lic_path = '1704@ilics04.iil.intel.com:1704@ilics05.iil.intel.com:1704@ilics06.iil.intel.com:1700@ilics04.iil.intel.com:1700@ilics05.iil.intel.com:1700@ilics06.iil.intel.com';

our @mig_stage_list;
@mig_stage_list = ('harvest', '1265', 'siclone', 'gridding', 'finish');

our %mig_mode_table;
opendir (MIGUTILS, $mig_utils{$SITE}) or die "\n-E- MigStdLib.pm: Could not open mig utils directory: $mig_utils{$SITE}";
my @env_files = grep /\.mig\.env$/, readdir(MIGUTILS);
foreach my $env_file (@env_files) {
  my $file_prefix = $env_file;
  $file_prefix =~ s/\.mig\.env$//;
  $mig_mode_table{$file_prefix} = "$mig_utils{$SITE}/${env_file}";
}

our %mig_lookup;
$mig_lookup{'iil'}{'release'} = '/nfs/iil/proj/mpg/mpg14/pnrmig/mig_data';
$mig_lookup{'fm'}{'release'} = '/nfs/site/disks/fm_fdc_s10079/penryn_area/mig_data';
$mig_lookup{'iil'}{'migstat'} = '/nfs/iil/disks/home10/mroha/migstat';
$mig_lookup{'fm'}{'migstat'} = '/usr/users/home2/mroha/migstat';
$mig_lookup{'iil'}{'migstat3'} = '/nfs/iil/disks/home10/mroha/migstat3';
$mig_lookup{'fm'}{'migstat3'} = '/usr/users/home2/mroha/migstat3';
$mig_lookup{'iil'}{'rcsbin'} = '/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/process/p1266/bin/RCS';
$mig_lookup{'fm'}{'rcsbin'} = '/nfs/fm/proj/pnr/fm_cad01/cad/i386_linux24/siclone/process/p1266/bin/RCS';
$mig_lookup{'iil'}{'rcssetup'} = '/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/process/p1266/setup/RCS';
$mig_lookup{'fm'}{'rcssetup'} = '/nfs/fm/proj/pnr/fm_cad01/cad/i386_linux24/siclone/process/p1266/setup/RCS';
$mig_lookup{'iil'}{"pdb${mig_input_process}"} = "$mig_utils{'iil'}/migrate${mig_input_process}.pdb";
$mig_lookup{'fm'}{"pdb${mig_input_process}"} = "$mig_utils{'fm'}/migrate${mig_input_process}.pdb";
$mig_lookup{'iil'}{"pdb${mig_output_process}"} = "$mig_utils{'iil'}/migrate${mig_output_process}.pdb";
$mig_lookup{'fm'}{"pdb${mig_output_process}"} = "$mig_utils{'fm'}/migrate${mig_output_process}.pdb";
$mig_lookup{'iil'}{'fubmap'} = '/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/fubs_map_file.txt';
$mig_lookup{'fm'}{'fubmap'} = '/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/fubs_map_file.txt';
$mig_lookup{'iil'}{'migsch'} = '/nfs/iil/proj/mpg/mpg14/pnrmig/p1266_schematic_mig/silver';
$mig_lookup{'fm'}{'migsch'} = '/nfs/site/disks/fm_fdc_s1009/penryn_area/logs/p1266_schematic_mig/silver';

my $sts754root = $SAGROOT;
$sts754root =~ s/\/\w+$/\/sts754patch13/;


sub GetMigReleaseStatus {

  my $loghandle = shift;
  my $release_area = shift;
  my $release_lookup_ref = shift;

  my $parent_flow = $loghandle->flowname('GetMigReleaseStatus');

  opendir (RELEASEAREA, $release_area) or die $loghandle->fatalq("Could not open dir: $release_area");
  my @releases = readdir(RELEASEAREA);
  foreach my $release (@releases) {
    if ($release =~ /(\d+_\d+_\d+)_(\S+)_(ps\d+)$/) {
      my $cell = lc($2);
      push (@{ $$release_lookup_ref{$cell} }, $release);
    }
  }
  $loghandle->flowname($parent_flow);
}


sub GetFubCode {

  my $loghandle = shift;
  my $fub = shift;

  my $parent_flow = $loghandle->flowname('GetFubCode');

  my $code = '';
  if ($fub) {
    open (FUBTABLE, $mig_lookup{$SITE}{'fubmap'}) or die $loghandle->fatalq("Could not open fub map file: $mig_lookup{$SITE}{'fubmap'}");
    while (<FUBTABLE>) {
      if (/^\s*${fub}\s+(\S+)/) {
	$code = $1;
	last;
      }
    }
    close (FUBTABLE);
  } else {
    die $loghandle->fatalq("Input value for fub is invalid: (${fub})");
  }

  if ($code) {
    $loghandle->flowname($parent_flow);
    return $code;
  } else {
    die $loghandle->fatalq("No code for fub (${fub}) was found in fub map file");
  }
}


sub InitMigFileTable {

  my $cell = shift;
  my $targetdir = shift;
  my $mig_file_table_ref = shift;
  my %stage_hash = @_;

  foreach my $stage (keys %stage_hash) {
    if ($stage eq 'harvest') {
      my $sourcedir =  $stage_hash{'harvest'};

      $$mig_file_table_ref{'harvest'}{'sn'}{'ward'}{'source'} = "${sourcedir}/netlists/cvssch";
      $$mig_file_table_ref{'harvest'}{'sn'}{'ward'}{'target'} = "${targetdir}/netlist/cvssch";
      $$mig_file_table_ref{'harvest'}{'sn'}{'ward'}{'filepattern'} = ${cell}.'\.sn\..+\.nobonus\.'."${mig_input_process}\$";
      $$mig_file_table_ref{'harvest'}{'sn'}{'arch'}{'source'} = "${sourcedir}/sn";
      $$mig_file_table_ref{'harvest'}{'sn'}{'arch'}{'target'} = "${targetdir}/sn";
      $$mig_file_table_ref{'harvest'}{'sn'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'sn'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'harvest'}{'mkispsn'}{'ward'}{'source'} = "${sourcedir}/netlists/mkisp";
      $$mig_file_table_ref{'harvest'}{'mkispsn'}{'ward'}{'target'} = "${targetdir}/netlist/mkisp";
      $$mig_file_table_ref{'harvest'}{'mkispsn'}{'ward'}{'filepattern'} = ${cell}.'\.sn\.withbonus\.'."${mig_input_process}\$";
      $$mig_file_table_ref{'harvest'}{'mkispsn'}{'arch'}{'source'} = "${sourcedir}/sn";
      $$mig_file_table_ref{'harvest'}{'mkispsn'}{'arch'}{'target'} = "${targetdir}/sn";
      $$mig_file_table_ref{'harvest'}{'mkispsn'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'mkispsn'}{'ward'}{'filepattern'};

      
      $$mig_file_table_ref{'harvest'}{'stm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'harvest'}{'stm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'harvest'}{'stm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.gentext$';
      $$mig_file_table_ref{'harvest'}{'stm'}{'ward'}{'namematch'} = '\.stm\.gentext$';
      $$mig_file_table_ref{'harvest'}{'stm'}{'ward'}{'namereplace'} = ".stm.${mig_input_process}.gentext";
      $$mig_file_table_ref{'harvest'}{'stm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'harvest'}{'stm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'harvest'}{'stm'}{'arch'}{'filepattern'} = ${cell}.'\.stm\.'.${mig_input_process}.'\.gentext$';
      
      $$mig_file_table_ref{'harvest'}{'log'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'harvest'}{'log'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'harvest'}{'log'}{'ward'}{'filepattern'} = ${cell}.'\.harvest\.log$';
      $$mig_file_table_ref{'harvest'}{'log'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'harvest'}{'log'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'harvest'}{'log'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'log'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'harvest'}{'lnf'}{'ward'}{'source'} = "${sourcedir}/genesys/lnf/${cell}_harvest_lnf_${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{'lnf'}{'ward'}{'target'} = "${targetdir}/genesys/lnf/${cell}_harvest_lnf_${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{'lnf'}{'ward'}{'filepattern'} = '.+\.lnf$';
      $$mig_file_table_ref{'harvest'}{'lnf'}{'arch'}{'source'} = "${sourcedir}/lnf/${cell}_harvest_lnf_${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{'lnf'}{'arch'}{'target'} = "${targetdir}/lnf/${cell}_harvest_lnf_${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{'lnf'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'lnf'}{'ward'}{'filepattern'};
  
      $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/src-${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'ward'}{'filepattern'} = "${cell}\.cif\..+\.${mig_input_process}\$";
      $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'arch'}{'source'} = "${sourcedir}/cif";
      $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'arch'}{'target'} = "${targetdir}/cif";
      $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{"cif${mig_input_process}"}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/src-${mig_intermediate_process}";
      $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'ward'}{'filepattern'} = ${cell}.'\.cif\..+\.'."${mig_intermediate_process}\$";
      $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'arch'}{'source'} = "${sourcedir}/cif";
      $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'arch'}{'target'} = "${targetdir}/cif";
      $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{"cif${mig_intermediate_process}"}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'harvest'}{'snlog'}{'ward'}{'source'} = "${sourcedir}/netlists/cvssch/${cell}_harvest_sn_${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{'snlog'}{'ward'}{'target'} = "${targetdir}/netlists/cvssch/${cell}_harvest_sn_${mig_input_process}";
      $$mig_file_table_ref{'harvest'}{'snlog'}{'ward'}{'filepattern'} = ${cell}.'__cdba_to_Sn__nike_netlister\.log$';
      $$mig_file_table_ref{'harvest'}{'snlog'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'harvest'}{'snlog'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'harvest'}{'snlog'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'snlog'}{'ward'}{'filepattern'};
   
      $$mig_file_table_ref{'harvest'}{'skipcell'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'harvest'}{'skipcell'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'harvest'}{'skipcell'}{'ward'}{'filepattern'} = ${cell}.'\.harvest\.skipcell$';
      $$mig_file_table_ref{'harvest'}{'skipcell'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'harvest'}{'skipcell'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'harvest'}{'skipcell'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'skipcell'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'harvest'}{'fubcfg'}{'ward'}{'source'} = $sourcedir; 
      $$mig_file_table_ref{'harvest'}{'fubcfg'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'harvest'}{'fubcfg'}{'ward'}{'filepattern'} = ${cell}.'\..+\.cfg$';
      $$mig_file_table_ref{'harvest'}{'fubcfg'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'harvest'}{'fubcfg'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'harvest'}{'fubcfg'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'harvest'}{'fubcfg'}{'ward'}{'filepattern'};
    }
    elsif ($stage eq 'siclone') {
      my $sourcedir = $stage_hash{$stage};

      $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.siclone\.cleaned'. ".${mig_output_process}.".'gentext$';
      $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'siclone'}{'cleanedstm'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'siclone'}{'ciflog'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'siclone'}{'ciflog'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'siclone'}{'ciflog'}{'ward'}{'filepattern'} = ${cell}.'\.mkcif\.siclone\.log$';
      $$mig_file_table_ref{'siclone'}{'ciflog'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'siclone'}{'ciflog'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'siclone'}{'ciflog'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'siclone'}{'ciflog'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'siclone'}{'lnf'}{'ward'}{'source'} = "${sourcedir}/genesys/lnf/${cell}_siclone_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'siclone'}{'lnf'}{'ward'}{'target'} = "${targetdir}/genesys/lnf/${cell}_siclone_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'siclone'}{'lnf'}{'ward'}{'filepattern'} = '.+\.lnf$';
      $$mig_file_table_ref{'siclone'}{'lnf'}{'arch'}{'source'} = "${sourcedir}/lnf/${cell}_siclone_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'siclone'}{'lnf'}{'arch'}{'target'} = "${targetdir}/lnf/${cell}_siclone_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'siclone'}{'lnf'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'siclone'}{'lnf'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif\.siclone\.cleaned\.'.${mig_output_process}.'$';
      $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'arch'}{'source'} = "${sourcedir}/cif";
      $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'arch'}{'target'} = "${targetdir}/cif";
      $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'siclone'}{'cleanedcif'}{'ward'}{'filepattern'};
 
      # Should be identical to the harvest SN... will diff later
      $$mig_file_table_ref{'siclone'}{'sn'}{'ward'}{'source'} = "${sourcedir}/netlists/cvssch";
      $$mig_file_table_ref{'siclone'}{'sn'}{'ward'}{'target'} = "${targetdir}/netlists/cvssch";
      $$mig_file_table_ref{'siclone'}{'sn'}{'ward'}{'filepattern'} = ${cell}.'\.sn\.siclone\.cleaned\.'.${mig_input_process}.'$';
      $$mig_file_table_ref{'siclone'}{'sn'}{'arch'}{'source'} = "${sourcedir}/sn";
      $$mig_file_table_ref{'siclone'}{'sn'}{'arch'}{'target'} = "${targetdir}/sn";
      $$mig_file_table_ref{'siclone'}{'sn'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'siclone'}{'sn'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'siclone'}{'rawstm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'rawstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'rawstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.siclone\.'.${mig_output_process}.'$';
      $$mig_file_table_ref{'siclone'}{'rawstm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'siclone'}{'rawstm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'siclone'}{'rawstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'siclone'}{'rawstm'}{'ward'}{'filepattern'};

      $$mig_file_table_ref{'siclone'}{'resultstm'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/work-firstSC";
      $$mig_file_table_ref{'siclone'}{'resultstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'siclone'}{'resultstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.firstSC_results$';
      $$mig_file_table_ref{'siclone'}{'resultstm'}{'ward'}{'noarchive'} = 1;
      
      $$mig_file_table_ref{'siclone'}{'resultcif'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/result-firstSC";
      $$mig_file_table_ref{'siclone'}{'resultcif'}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'siclone'}{'resultcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif$';
      $$mig_file_table_ref{'siclone'}{'resultcif'}{'ward'}{'noarchive'} = 1;
    }
    elsif ($stage eq 'gridding') {
      my $sourcedir = $stage_hash{$stage};

      $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.gridding\.cleaned'. ".${mig_output_process}.".'gentext$';
      $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'gridding'}{'cleanedstm'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'gridding'}{'ciflog'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'gridding'}{'ciflog'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'gridding'}{'ciflog'}{'ward'}{'filepattern'} = ${cell}.'\.mkcif\.gridding\.log$';
      $$mig_file_table_ref{'gridding'}{'ciflog'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'gridding'}{'ciflog'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'gridding'}{'ciflog'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'gridding'}{'ciflog'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'gridding'}{'lnf'}{'ward'}{'source'} = "${sourcedir}/genesys/lnf/${cell}_gridding_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'gridding'}{'lnf'}{'ward'}{'target'} = "${targetdir}/genesys/lnf/${cell}_gridding_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'gridding'}{'lnf'}{'ward'}{'filepattern'} = '.+\.lnf$';
      $$mig_file_table_ref{'gridding'}{'lnf'}{'arch'}{'source'} = "${sourcedir}/lnf/${cell}_gridding_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'gridding'}{'lnf'}{'arch'}{'target'} = "${targetdir}/lnf/${cell}_gridding_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'gridding'}{'lnf'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'gridding'}{'lnf'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif\.gridding\.cleaned\.'.${mig_output_process}.'$';
      $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'arch'}{'source'} = "${sourcedir}/cif";
      $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'arch'}{'target'} = "${targetdir}/cif";
      $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'gridding'}{'cleanedcif'}{'ward'}{'filepattern'};
 
      # Should be identical to the harvest SN... will diff later
      $$mig_file_table_ref{'gridding'}{'sn'}{'ward'}{'source'} = "${sourcedir}/netlists/cvssch";
      $$mig_file_table_ref{'gridding'}{'sn'}{'ward'}{'target'} = "${targetdir}/netlists/cvssch";
      $$mig_file_table_ref{'gridding'}{'sn'}{'ward'}{'filepattern'} = ${cell}.'\.sn\.gridding\.cleaned\.'.${mig_input_process}.'$';
      $$mig_file_table_ref{'gridding'}{'sn'}{'arch'}{'source'} = "${sourcedir}/sn";
      $$mig_file_table_ref{'gridding'}{'sn'}{'arch'}{'target'} = "${targetdir}/sn";
      $$mig_file_table_ref{'gridding'}{'sn'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'gridding'}{'sn'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'gridding'}{'rawstm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'rawstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'rawstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.gridding\.'.${mig_output_process}.'$';
      $$mig_file_table_ref{'gridding'}{'rawstm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'gridding'}{'rawstm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'gridding'}{'rawstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'gridding'}{'rawstm'}{'ward'}{'filepattern'};

      $$mig_file_table_ref{'gridding'}{'resultstm'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/work-fubXgrid";
      $$mig_file_table_ref{'gridding'}{'resultstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'gridding'}{'resultstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.gridding_results$';
      $$mig_file_table_ref{'gridding'}{'resultstm'}{'ward'}{'noarchive'} = 1;

      $$mig_file_table_ref{'gridding'}{'resultcif'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/result-Xgrid";
      $$mig_file_table_ref{'gridding'}{'resultcif'}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'gridding'}{'resultcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif$';
      $$mig_file_table_ref{'gridding'}{'resultcif'}{'ward'}{'noarchive'} = 1;

    }
    elsif ($stage eq 'finish') {
      my $sourcedir = $stage_hash{$stage};

      $$mig_file_table_ref{'finish'}{'cleanedstm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'cleanedstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'cleanedstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.finish\.cleaned'. ".${mig_output_process}.".'gentext$';
      $$mig_file_table_ref{'finish'}{'cleanedstm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'finish'}{'cleanedstm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'finish'}{'cleanedstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'cleanedstm'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'finish'}{'ciflog'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'finish'}{'ciflog'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'finish'}{'ciflog'}{'ward'}{'filepattern'} = ${cell}.'\.mkcif\.finish\.log$';
      $$mig_file_table_ref{'finish'}{'ciflog'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'finish'}{'ciflog'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'finish'}{'ciflog'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'ciflog'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'finish'}{'lnf'}{'ward'}{'source'} = "${sourcedir}/genesys/lnf/${cell}_finish_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'finish'}{'lnf'}{'ward'}{'target'} = "${targetdir}/genesys/lnf/${cell}_finish_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'finish'}{'lnf'}{'ward'}{'filepattern'} = '.+\.lnf$';
      $$mig_file_table_ref{'finish'}{'lnf'}{'arch'}{'source'} = "${sourcedir}/lnf/${cell}_finish_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'finish'}{'lnf'}{'arch'}{'target'} = "${targetdir}/lnf/${cell}_finish_cleaned_lnf_${mig_output_process}";
      $$mig_file_table_ref{'finish'}{'lnf'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'lnf'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'finish'}{'cleanedcif'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'cleanedcif'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'cleanedcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif\.finish\.cleaned\.'.${mig_output_process}.'$';
      $$mig_file_table_ref{'finish'}{'cleanedcif'}{'arch'}{'source'} = "${sourcedir}/cif";
      $$mig_file_table_ref{'finish'}{'cleanedcif'}{'arch'}{'target'} = "${targetdir}/cif";
      $$mig_file_table_ref{'finish'}{'cleanedcif'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'cleanedcif'}{'ward'}{'filepattern'};
 
      # Should be identical to the harvest SN... will diff later
      $$mig_file_table_ref{'finish'}{'sn'}{'ward'}{'source'} = "${sourcedir}/netlists/cvssch";
      $$mig_file_table_ref{'finish'}{'sn'}{'ward'}{'target'} = "${targetdir}/netlists/cvssch";
      $$mig_file_table_ref{'finish'}{'sn'}{'ward'}{'filepattern'} = ${cell}.'\.sn\.finish\.cleaned\.'.${mig_input_process}.'$';
      $$mig_file_table_ref{'finish'}{'sn'}{'arch'}{'source'} = "${sourcedir}/sn";
      $$mig_file_table_ref{'finish'}{'sn'}{'arch'}{'target'} = "${targetdir}/sn";
      $$mig_file_table_ref{'finish'}{'sn'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'sn'}{'ward'}{'filepattern'};
      
      $$mig_file_table_ref{'finish'}{'rawstm'}{'ward'}{'source'} = "${sourcedir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'rawstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'rawstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.finish\.'.${mig_output_process}.'$';
      $$mig_file_table_ref{'finish'}{'rawstm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'finish'}{'rawstm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'finish'}{'rawstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'rawstm'}{'ward'}{'filepattern'};

      $$mig_file_table_ref{'finish'}{'filterstm'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'finish'}{'filterstm'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'finish'}{'filterstm'}{'ward'}{'filepattern'} = ${cell}.'\.sum2csv\.report\.finish\.rawstm$';
      $$mig_file_table_ref{'finish'}{'filterstm'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'finish'}{'filterstm'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'finish'}{'filterstm'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'filterstm'}{'ward'}{'filepattern'};

      $$mig_file_table_ref{'finish'}{'filterlnf'}{'ward'}{'source'} = $sourcedir;
      $$mig_file_table_ref{'finish'}{'filterlnf'}{'ward'}{'target'} = $targetdir;
      $$mig_file_table_ref{'finish'}{'filterlnf'}{'ward'}{'filepattern'} = ${cell}.'\.sum2csv\.report\.finish\.lnf$';
      $$mig_file_table_ref{'finish'}{'filterlnf'}{'arch'}{'source'} = "${sourcedir}/logs";
      $$mig_file_table_ref{'finish'}{'filterlnf'}{'arch'}{'target'} = "${targetdir}/logs";
      $$mig_file_table_ref{'finish'}{'filterlnf'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'finish'}{'filterlnf'}{'ward'}{'filepattern'};

      $$mig_file_table_ref{'finish'}{'resultstm'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/work-finish";
      $$mig_file_table_ref{'finish'}{'resultstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'finish'}{'resultstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.finish_results$';
      $$mig_file_table_ref{'finish'}{'resultstm'}{'ward'}{'noarchive'} = 1;

      $$mig_file_table_ref{'finish'}{'resultcif'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/result-finish";
      $$mig_file_table_ref{'finish'}{'resultcif'}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'finish'}{'resultcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif$';
      $$mig_file_table_ref{'finish'}{'resultcif'}{'ward'}{'noarchive'} = 1;
    }
    elsif ($stage eq 'lib') {
      my $sourcedir = $stage_hash{$stage};

      $$mig_file_table_ref{'lib'}{'stm'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}";
      $$mig_file_table_ref{'lib'}{'stm'}{'ward'}{'target'} = "${targetdir}/mig/${cell}/work-${cell}";
      $$mig_file_table_ref{'lib'}{'stm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.libFinish$';
      $$mig_file_table_ref{'lib'}{'stm'}{'ward'}{'namematch'} = '\.stm$';
      $$mig_file_table_ref{'lib'}{'stm'}{'ward'}{'namereplace'} = ".stm.libFinish.${mig_output_process}";
      $$mig_file_table_ref{'lib'}{'stm'}{'arch'}{'source'} = "${sourcedir}/stm";
      $$mig_file_table_ref{'lib'}{'stm'}{'arch'}{'target'} = "${targetdir}/stm";
      $$mig_file_table_ref{'lib'}{'stm'}{'arch'}{'filepattern'} = ${cell}.'\.stm\.libFinish\.'.${mig_output_process}.'$';

      $$mig_file_table_ref{'lib'}{'cif'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/result-finish";
      $$mig_file_table_ref{'lib'}{'cif'}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'lib'}{'cif'}{'ward'}{'filepattern'} = ${cell}.'\.cif$';
      $$mig_file_table_ref{'lib'}{'cif'}{'ward'}{'namematch'} = '\.cif$';
      $$mig_file_table_ref{'lib'}{'cif'}{'ward'}{'namereplace'} = ".cif.resultfinish.${mig_output_process}";
      $$mig_file_table_ref{'lib'}{'cif'}{'arch'}{'source'} = "${sourcedir}/cif";
      $$mig_file_table_ref{'lib'}{'cif'}{'arch'}{'target'} = "${targetdir}/cif";
      $$mig_file_table_ref{'lib'}{'cif'}{'arch'}{'filepattern'} =  ${cell}.'\.cif\.resultfinish\.'.${mig_output_process}.'$';

      $$mig_file_table_ref{'lib'}{'lnf'}{'ward'}{'source'} = "${sourcedir}/pie/lnf/${cell}_lnf";
      $$mig_file_table_ref{'lib'}{'lnf'}{'ward'}{'target'} = "${targetdir}/genesys/lnf/${cell}_libflow";
      $$mig_file_table_ref{'lib'}{'lnf'}{'ward'}{'filepattern'} = '.+\.lnf$';
      $$mig_file_table_ref{'lib'}{'lnf'}{'arch'}{'source'} = "${sourcedir}/lnf/${cell}_lib_lnf_${mig_output_process}";
      $$mig_file_table_ref{'lib'}{'lnf'}{'arch'}{'target'} = "${targetdir}/lnf/${cell}_lib_lnf_${mig_output_process}";
      $$mig_file_table_ref{'lib'}{'lnf'}{'arch'}{'filepattern'} = $$mig_file_table_ref{'lib'}{'lnf'}{'ward'}{'filepattern'};

      $$mig_file_table_ref{'lib'}{'resultstm'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}";
      $$mig_file_table_ref{'lib'}{'resultstm'}{'ward'}{'target'} = "${targetdir}/pds/stream";
      $$mig_file_table_ref{'lib'}{'resultstm'}{'ward'}{'filepattern'} = ${cell}.'\.stm\.libFinish$';
      $$mig_file_table_ref{'lib'}{'resultstm'}{'ward'}{'noarchive'} = 1;

      $$mig_file_table_ref{'lib'}{'resultcif'}{'ward'}{'source'} = "${sourcedir}/mig/${cell}/work-${cell}/result-finish";
      $$mig_file_table_ref{'lib'}{'resultcif'}{'ward'}{'target'} = "${targetdir}/mig/${cell}/src";
      $$mig_file_table_ref{'lib'}{'resultcif'}{'ward'}{'filepattern'} = ${cell}.'\.cif$';
      $$mig_file_table_ref{'lib'}{'resultcif'}{'ward'}{'noarchive'} = 1;
    }
  }
}



sub SagantecLayconv {
  my $loghandle = shift;
  my $inputfile = shift;
  my $inputformat = shift;
  my $outputfile = shift;
  my $outputformat = shift;
  my $pdbfile = shift;
  
  my $other_args = join(' ', @_);

  my $parent_flow = $loghandle->flowname('SagantecLayconv');

  #my $origroot = $SAGROOT;
  #$SAGROOT = $sts754root;

  if ($inputformat =~ /stm|gds/i) {$inputformat = '-ig'}
  if ($inputformat =~ /cif/i) {$inputformat = '-ic'}
  if ($outputformat =~ /stm|gds/i) {$outputformat = '-og'}
  if ($outputformat =~ /cif/i) {$outputformat = '-oc'}

  unless (-e $inputfile) {
    die $loghandle->fatalq("Could not locate input file for layconv:", $inputfile);
  }
  unless (-e $pdbfile) {
    die $loghandle->fatalq("Could not locate pdb file for layconv:", $pdbfile);
  }
  
  my $layconvcmd = "${SAGROOT}/bin/layconv $inputformat $inputfile $outputformat $outputfile -p $pdbfile $other_args";
  $loghandle->infoq("Running command: $layconvcmd");

  my $run_dirty = 0;
  open (LAYCONV, "$layconvcmd 2>&1 |") or die $loghandle->fatalq("Could not open layconv process:", $layconvcmd);
  while (<LAYCONV>) {
    chomp;
    $loghandle->infoq($_);
    if (/List of calls to symbols which are not defined in the input file|F-Layconv/) {
      $run_dirty = 1;
    }
  }
  close (LAYCONV);

  
  if ($run_dirty) {
    die $loghandle->fatalq("Fatal error detected during layconv run. See log file.");
  }

  unless (-e $outputfile) {
    die $loghandle->fatalq("Could not find output file from layconv run. See log file.");
  }

  #$SAGROOT = $origroot;
  $loghandle->flowname($parent_flow);
}


sub SagPerl {

  my $loghandle = shift;
  my $command = shift;

  my $parent_flow = $loghandle->flowname('SagPerl');

  my $perlcmd = "${SAGROOT}/bin/sagperl -I${SAGROOT}/lib -I/usr/intel/pkgs/perl/5.8.2/lib/5.8.2 $command";

  $loghandle->infoq("Running command: $perlcmd");

  &Pipe($loghandle, $perlcmd, '');

  $loghandle->flowname($parent_flow);
}



sub Polar {

  my $loghandle = shift;
  my $incif = shift;
  my $outcif = shift;
  my $pdb = shift;
  my $pdb_section = shift;
  my $other_options = join(' ', @_);
 
  my $parent_flow = $loghandle->flowname('Polar');

  my $polarcmd = "${SAGROOT}/bin/polar -i $incif -o $outcif -p $pdb -l $pdb_section $other_options";

  $loghandle->infoq("Running command: $polarcmd");
  
  &Pipe($loghandle, $polarcmd, '');

  $loghandle->flowname($parent_flow);
}

sub SagPerlCifIO {


  my $loghandle = shift;
  my $function = shift;
  my $cell = shift;
  my $incif = shift;
  my $outcif = shift;
  my $other_options = join(' ', @_);

  my $parent_flow = $loghandle->flowname("SagPerlCifIO: $function");

  my $cmd = "$mig_utils{$SITE}/SagStd.pl -${function} $cell $incif $outcif $other_options";

  if (-e $incif) {
    &SagPerl($loghandle, $cmd);
  } else {
    die $loghandle->fatalq("Input CIF file does not exist: $incif");
  }
  unless (-e $outcif) {
    die $loghandle->fatalq("Output CIF file not created: $outcif");
  }

  $loghandle->flowname($parent_flow);
}


sub Harvest1265 {

  my $loghandle = shift;
  my $mig_work = shift;
  my $pdb = shift;

  my $parent_flow = $loghandle->flowname('Harvest1265');

  chdir ($mig_work) or die $loghandle->fatalq("Could not change work directory to $mig_work");

  $ENV{'GRIDDING_RUN'} = 'NO';
  $ENV{'FINISH_RUN'} = 'NO';
  $ENV{'ENFORCE_ALL'} = 'YES';

  my $migrate_cmd = "$SAGROOT/bin/migrate -p $pdb";
  
  open (MIGRATE, "$migrate_cmd 2>&1 |") or die $loghandle->fatalq("Could not start migrate process for command:", $migrate_cmd);
  while (<MIGRATE>) {
    chomp;
    $loghandle->infoq($_);
  }
  $loghandle->flowname($parent_flow);
}

sub ReadPdbFile {

  my $loghandle = shift;
  my $pdbfile = shift;
  my $tech_table_ref = shift;
  my $debug = shift;
  my $tag;
  my $value;
  my $posible_layer;
  my $layer;
  my $indent_count = 0;
  my $layernum = -1;
  my $datatype = -1;
  
  my $parent_flow = $loghandle->flowname('ReadPdbFile');

  my $in_section_process = 0;
  my $in_section_layer = 0;
  my $streamin_found = 0;
  open (PDBFILE, $pdbfile) or die $loghandle->fatalq("Could not open input PDB file for reading: $pdbfile");
  while (<PDBFILE>) {
    if (/^\s*\#/) {
      next;
    }
    if (/^\s+process\s+\{/i) {
      $in_section_process = 1;
    }
    if ($in_section_process) {
      if (/^\s+layers\s+\{/i) {
        $in_section_layer = 1;
        $indent_count = 0;
      }
      if ($in_section_layer) {
        if ((/^\s+(\S+)\s+\{/i) and ($indent_count==1)) {
          $layer = $1;
        }
        if (/streamin/i) {
          $streamin_found = 1;
        }
        if (/^\s+gds2_nr\s+\{\s*(\d+)\s*\}/) {
          $layernum = int($1);
        }
        if (/^\s+gds2_datatype\s+\{\s*(\d+)\s*\}/) {
          $datatype = int($1);
        }
        if (/\{/) {
          $indent_count++;
        }
        if (/\}/) {
          $indent_count--;
          if ($indent_count == 1) {
            if ($streamin_found) {
	      if ($debug) {
		$loghandle->infod("Recording PDB record for layer: $layer datanum: $layernum datatype: $datatype");
	      }
              unless ($layernum == -1 or $datatype == -1) {
                $$tech_table_ref{'PDB'}{$layer}{'LAYERNUM'} = $layernum;
                $$tech_table_ref{'PDB'}{$layer}{'DATATYPE'} = $datatype;
                $streamin_found = 0;
                $layernum = -1;
                $datatype = -1;
              } else {
		$loghandle->warnq("Found invalid layernum or datatype in PDB, line ${.}. Skipping entry.",
				"PDB: $pdbfile");
              }
            } else {
              $loghandle->warnq("Got through a layer without a streamin def found: $layer");
            }
          }
          elsif ($indent_count == 0) {
	    if ($streamin_found) {
	      last;
	    } else {
	      $in_section_layer = $in_section_process = 0;
	    }
          }
        }
      }
    }
  }
  $loghandle->flowname($parent_flow);
}


sub GenerateLayconvMapFile {

  my $loghandle = shift;
  my $tech_table_ref = shift;
  my $outmapfile = shift;
  my $debug = shift;
  my $dtlayernum;
  my $dtdatatype;
  my $pdblayernum;
  my $pdbdatatype;
  my $dt_layer_and_datatype_in_pdb = 0;

  my $parent_flow = $loghandle->flowname('GenerateLayconvMapFile');

  open (OUTMAP, ">$outmapfile") or die $loghandle->fatalq("Could not open $outmapfile for writing");
  foreach my $dtlayer (sort keys %{ $$tech_table_ref{'MODTECH'} }) {
    $dt_layer_and_datatype_in_pdb = 0;
    if (exists $$tech_table_ref{'MODTECH'}{$dtlayer}{'LAYERNUM'}) {
      $dtlayernum = $$tech_table_ref{'MODTECH'}{$dtlayer}{'LAYERNUM'};
    } else {
      unless ($dtlayer eq 'PORT') {
        die $loghandle->fatalq("DT Tech -> layer: $dtlayer does not have a LAYERNUM entry");
      } 
    }
    if (exists $$tech_table_ref{'MODTECH'}{$dtlayer}{'DATATYPE'}) {
      $dtdatatype = $$tech_table_ref{'MODTECH'}{$dtlayer}{'DATATYPE'};
    } else {
      die $loghandle->fatalq("DT Tech -> layer: $dtlayer does not have a DATATYPE entry");
    }
    foreach my $pdblayer (sort keys %{ $$tech_table_ref{'PDB'} }) {
      if (exists $$tech_table_ref{'PDB'}{$pdblayer}{'LAYERNUM'}) {
        $pdblayernum = $$tech_table_ref{'PDB'}{$pdblayer}{'LAYERNUM'};
      } else {
        die $loghandle->fatalq("PDB Tech -> layer: $pdblayer does not have a LAYERNUM entry");
      }
      if (exists $$tech_table_ref{'PDB'}{$pdblayer}{'DATATYPE'}) {
        $pdbdatatype = $$tech_table_ref{'PDB'}{$pdblayer}{'DATATYPE'};
      } else {
        die $loghandle->fatalq("PDB Tech -> layer: $pdblayer does not have a DATATYPE entry");
      }    
      if (($dtlayernum == $pdblayernum) and ($dtdatatype == $pdbdatatype)) {
	if ($debug) {
	  $loghandle->infod("DT layernum and datatype is in PDB: layer: $dtlayer layernum: $dtlayernum  dataype: $dtdatatype");
	}
        $dt_layer_and_datatype_in_pdb = 1;
        last;
      }
    }
    unless (($dt_layer_and_datatype_in_pdb) or ($dtlayer eq 'PORT')) {
      my $outstring = lc("$dtlayer $dtlayernum $dtdatatype");
      print OUTMAP "$outstring\n";
    }
  }
  close (OUTMAP);

  $loghandle->flowname($parent_flow);
}


sub ConvertCifToStm {
  
  my $loghandle = shift;
  my $cell = shift;
  my $incif = shift;
  my $outstm = shift;
  my $migratepdb = shift;
  my $debug = shift;

  my @tmpfiles;
  
  my $parent_flow = $loghandle->flowname('ConvertCifToStm');

  foreach my $file ($incif, $migratepdb) {
    unless (-e $file) {
      die $loghandle->fatalq("Input file does not exist: $file\n");
    }
  }

  my $post1265_cif = "${incif}.post1265";
  push(@tmpfiles, $post1265_cif);
  &Polar($loghandle, $incif, $post1265_cif,  $migratepdb, 'post1265');
 
  my $propdrop_cif = "${incif}.propdrop";
  push(@tmpfiles, $propdrop_cif);
  my $cmd = "$mig_utils{$SITE}/hierarTraverse.pl --i $post1265_cif --o $propdrop_cif --propertyDrop";
  &SagPerl($loghandle, $cmd);

  my $prop2text_cif = "${incif}.prop2text";
  push(@tmpfiles, $prop2text_cif);
  $cmd = "$mig_utils{$SITE}/hierarTraverse.pl --i $propdrop_cif --o $prop2text_cif --prop2text";
  &SagPerl($loghandle, $cmd);

  my $generateports_cif = "${incif}.generatePorts";
  push(@tmpfiles, $generateports_cif);
  &SagPerlCifIO($loghandle, 'GeneratePortsInCif', $cell, $prop2text_cif, $generateports_cif);
  #&Polar($loghandle, $prop2text_cif, $generateports_cif,  $migratepdb, 'generatePorts');

  &SagantecLayconv($loghandle, $generateports_cif, 'cif', $outstm, 'gds', $migratepdb);

  unless (-e $outstm) {
    die $loghandle->fatalq("Output STM file not created: $outstm");
  }

  $loghandle->flowname($parent_flow);
}


1;
