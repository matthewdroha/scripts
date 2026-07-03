#!/usr/intel/pkgs/perl/5.6.1/bin/perl

$fub_section_started = 0;

while (<>) {
  if (/Fubs-Done-/) {
    $fub_section_started = 1;
  }
  if ($fub_section_started) {
    if (/^(Fub\s+)|(Fubs-Done)/) {
      next;
    }
    if (/^(\S+)\s+/) {
      $fub_hash{$1} = 1;
    }
  }
}

open (OUT1, ">runfile1") or die;
open (OUT2, ">runfile2") or die;

$write_out2 = 0;
foreach $fub (sort keys %fub_hash) {
  if ($write_out2) {
    print OUT2 "~/pnr/mig/premig.pl -cell $fub\n";
    $write_out2 = 0;
  } else {
    print OUT1 "~/pnr/mig/premig.pl -cell $fub\n";
    $write_out2 = 1;
  }
}

close (OUT1);
close (OUT2);
