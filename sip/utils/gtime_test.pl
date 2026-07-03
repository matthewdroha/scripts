#!/usr/intel/bin/perl

my $test = system(q(/usr/intel/bin/gtime -f "elap:%e" sleep 5));
print "$test\n";
$test = system(q(/usr/intel/bin/gtime sleep 5t >& /dev/null));
print "$test\n";

my $cmd = q(/usr/intel/bin/gtime -f "elap:%e" sleep 7);
my @stdout_and_err = ();
open (PIPE, "$cmd 2>&1 |") or die "Command count not run: $cmd\n";
while (<PIPE>) {
  push @stdout_and_err, $_;
}
close (PIPE);
my $exit_value = $? >> 8;
my $signal_num = $? & 127;
my $dumped_core = $? & 128;

if ($exit_value) {
  print qq(Pipe call returned non-zero exit status. Exit: $exit_value  Signal: $signal_num Core: $dumped_core);
} else {
  print qq(@@stdout_and_err);
}

@stdout_and_err = ();
$cmd = q(/usr/intel/bin/gtime -f "elap:%e" sleep 7t);
open (PIPE, "$cmd 2>&1 |") or die "Command count not run: $cmd\n";
while (<PIPE>) {
  push @stdout_and_err, $_;
}
close (PIPE);
$exit_value = $? >> 8;
$signal_num = $? & 127;
$dumped_core = $? & 128;

if ($exit_value) {
  print qq(Pipe call returned non-zero exit status. Exit: $exit_value  Signal: $signal_num Core: $dumped_core);
} else {
  print qq(@@stdout_and_err);
}

