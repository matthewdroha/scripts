#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w

open (ASSIGN, $ARGV[0]) or die;
while (<ASSIGN>) {
  if (/((\*\/\s+)|(^\s+))(\S+)\s+\(\s+\d+\s+\;\s+\d+\s+\)/) {
    s/\/\*.+\*\///;
    ($layer_lc) = split;
    $layer_uc = uc($layer_lc);
    $layer_uc =~ s/METAL/MET/;
    $layer_hash{$layer_uc} = $layer_lc;
    print "$layer_uc=$layer_lc\n";
  }
}
close (ASSIGN);


open (INEV, $ARGV[1]) or die;
open (OUTEV, ">$ARGV[1].mapassign") or die;

while (<INEV>) {
  foreach $layer (keys %layer_hash) {
    s/(\s+|\"|^)$layer(\s+|\")/${1}$layer_hash{$layer}${2}/gi;
    #To test replacement
    #s/(\s+|\"|^)$layer(\s+|\"|$)/${1}$layer${2}/gi;
  }
  print OUTEV $_;
}

close (INEV);
close (OUTEV);

