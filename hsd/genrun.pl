#!/usr/intel/bin/perl

my $startmonth = 6;
my $finishmonth = 11;
for (my $j = $startmonth; $j<=$finishmonth; $j++) {
  for (my $i = 1; $i<31; $i++) {
    my $startday = sprintf("%02d", $i);
    my $finishday = sprintf("%02d", $i+1);
    my $startmonth = sprintf("%02d", $startmonth);
    my $finishmonth = sprintf("%02d", $finishmonth);
    my $nextmonth = $j+1;
    print qq(gtime states.pl '${j}/${startday}/2020' '${j}/${finishday}/2020' > tickets_${j}_${i}\n);
    if ($i==30) {
      print qq(gtime states.pl '${j}/${finishday}/2020' '${nextmonth}/01/2020' > tickets_${j}_32\n);
    }
  }
}
