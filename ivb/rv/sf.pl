#!/usr/intel/bin/perl

while (<>) {
  if (/\d+\./) {
    $total_sfactor_count++;
    @record = split(/\|/, $_);
    if ($record[4] > 3) {
      $sfactor_gte_3++;
    } else {
      $sfactor_lt_3++;
    }
  }
}
print "$total_sfactor_count $sfactor_gte_3 $sfactor_lt_3\n";
