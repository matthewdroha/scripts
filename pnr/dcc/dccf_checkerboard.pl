#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w


for ($i=0; $i<=95; $i++) {
  if ($i%2 == 0) {
    print "\#ROWBARYD/WRENP0[$i]\n";
    print "ROWBARYD/WRENP1[$i]\n";
    print "\#ROWBARYD/WRENP2[$i]\n";
    print "ROWBARYD/WRENP3[$i]\n";
  } else {
    print "ROWBARYD/WRENP0[$i]\n";
    print "\#ROWBARYD/WRENP1[$i]\n";
    print "ROWBARYD/WRENP2[$i]\n";
    print "\#ROWBARYD/WRENP3[$i]\n";
  }
}
