#!/usr/intel/bin/perl
$infile = shift;

open (INFILE, $infile) or die;

while (<INFILE>) {
  if (/^\s*\(\s+\d+\s+\d+\s+(\"\S+\")\s+\"\S+\"\s+(\".+\")/) {
    $code = $1;
    $desc = $2;
    print "${code},enable,${desc}\n";
  }
}
