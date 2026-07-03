#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w

use Cwd 'abs_path';

$harvestdir = shift;
$arch = shift;

opendir (HARVESTDIR, $harvestdir) or die;
@files = grep /\.harvest\.log$/, readdir (HARVESTDIR);
closedir (HARVESTDIR);

$realdir = abs_path($harvestdir);

foreach $file (sort @files) {
  open (FILE, $file) or die;
  $trcalt = '';
  $pre1265_trcstd = '';
  $chenwei_trcstd = '';
  $migsn_run_active = 0;
  $pre1265_run_active = 0;
  while (<FILE>) {
    if (/ISS TRCSTD \(LNF Input\-All Data\) run CLEAN for\s+cell:\((\S+)\)\s+model:\((\S+)\)\s+(.+)$/) {
      $cell = $1;
      $model = $2;
      $config_string = $3;
      chomp $config_string;
    }
    if (/isFUB\.pl Query:\s+\S+\s+(\S+)/) {
      $type = $1;
    }
    if (/Migration SN config:\((\S+)\)/) {
      $chenwei_sn_cfg = $1;
    }
    if (/Migrated SN found: (\S+)/) {
      $chenwei_sn = $1;
    }
    if (/Running ISS TRCSTD \(LNF-CellsRemoved\-MigratedSN/) {
      $migsn_run_active = 1;
    }
    if (/Running ISS TRCSTD \(STM-GeneratedFrom1264CIF/) {
      $pre1265_run_active = 1;
    }
    if ((/RunISS-trcstd: Total/) and $pre1265_run_active) {
      s/-I- RunISS-trcstd: //;
      chomp;
      $pre1265_trcstd = "TRCSTD-Pre1265 (1264 SN) : $_";
      $pre1265_run_active = 0;
    }
    if ((/RunISS-trcstd: Total/) and $migsn_run_active) {
      s/-I- RunISS-trcstd: //;
      chomp;
      $chenwei_trcstd = "TRCSTD (Chenwei 1266 SN) : $_";
      $migsn_run_active = 0;
    }
    if (/RunISS-trcalt: Total/) {
      s/-I- RunISS-trcalt: //;
      $trcalt = "TRCALT-Post1265 (1264 SN): ${_}${trcalt}";
    }
    if (/RunISS-trcalt: (OPEN_CIRCUITS:|SHORT_CIRCUITS:)/) {
      s/-I- RunISS-trcalt: //;
      $trcalt .= "TRCALT-Post1265 (1264 SN): $_";
    }
    if (/run complete for cell:/) {
      print "\n***** $cell (${model}) (${type}) *****\n";
      print "Harvest 1264 CFG: $config_string\n";
      print "Chenwei 1266 CFG: $chenwei_sn_cfg\n\n";
      print "$chenwei_trcstd\n";
      print "$pre1265_trcstd\n";
      print "$trcalt\n";
      if ($arch) {
	$realdir =~ s/\/logs//;
	print "1264 SN : ${realdir}/sn/${cell}.sn.${model}.nobonus.1264\n";
	print "1266 SN : $chenwei_sn\n";
	print "1264 CIF: ${realdir}/cif/${cell}.cif.${model}.1264\n";
	print "1265 CIF: ${realdir}/cif/${cell}.cif.${model}.1265\n" if $trcalt;
	print "\n\n";
      } else {
	print "1264 SN : ${realdir}/netlists/cvssch/${cell}.sn.${model}.1264\n";
	print "1266 SN : $chenwei_sn\n";
	print "1264 CIF: ${realdir}/mig/${cell}/src-1264/${cell}.cif\n";
	print "1265 CIF: ${realdir}/mig/${cell}/src-1265/${cell}.cif\n" if $trcalt;
	print "\n";
      }
    }
  }
  close (FILE);
}

