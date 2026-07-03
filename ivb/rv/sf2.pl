#!/usr/intel/bin/perl

use IO::Dir;

while (<>) {
  @record = split;
  $mode = $record[0];
  $dir = $record[2];
  $dir =~ s/totemdir\/$/rv/;
  print "$dir\n";
  if (-d $dir) {
    $dir_h = IO::Dir->new($dir);
    my @sfactor_files = grep /\.sfactor.drv_out$/, $dir_h->read();
    foreach my $file (@sfactor_files) {
      print "$file\n";
    }
    $dir_h->close;
  }
}
#  if (/\d+\./) {
#    $total_sfactor_count++;
#    @record = split(/\|/, $_);
#    if ($record[4] > 3) {
#      $sfactor_gte_3++;
#    } else {
#      $sfactor_lt_3++;
#    }
#  }
#}
#print "$total_sfactor_count $sfactor_gte_3 $sfactor_lt_3\n";
