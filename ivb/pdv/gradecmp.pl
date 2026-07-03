#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

while (<>) {
  chomp;
  if (/Cell Processed:\s+(\S+)/) {
    $cell = $1;
  }
  if (/Total\s+\d+/) {
    if (/Total\s+\d+\s+\d+(\s+0){7}/) {
      $_ .= " CLEAN";
    }
    elsif (/Total\s+\d+\s+\d+(\s+0){4}\s+\d+(\s+0){2}/) {
      $_ .= " ZL";
    } else {
      $_ .= " MISMATCH";
    }
    printf "%-32s %s\n", $cell, $_;
  }
}
