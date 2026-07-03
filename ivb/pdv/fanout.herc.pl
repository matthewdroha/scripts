#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use IO::File;

my $sumfile = shift;

my $sumfh = new IO::File;
$sumfh->open($sumfile) or die "Could not open $sumfile for reading\n";

my $found_open_section = 0;
my $found_shorts_section = 0;
my $found_trcstd_section = 0;
my $total_shorts = 0;
my $total_open_nets = 0;
my $total_non_power_connections = 0;
my %opens_hash;
my $block;
my $net;
while (<$sumfh>) {
  if (/FLOW = (\S+)/) {
    $flow = $1;
    if ($flow =~ /trcstd/) {
      $found_trcstd_section = 1;
    }
    elsif ($found_trcstd_section) {
      last;
    }
  }
  if (/OPEN_CIRCUITS:/) {
    $found_open_section = 1;
    $found_shorts_section = 0;
  }
  if (/SHORT_CIRCUITS:/) {
    $found_shorts_section = 1;
  }
  if ($found_shorts_section and $found_trcstd_section) {
    if (/^\S+\s+\S+\(\d+/) {
      $total_shorts++
    }
  }
  if ($found_open_section and $found_trcstd_section) {
    if (/^(\S+)\s+(\S+)\s+\d+\;\d+\s+\S+/) {
      $block = $1;
      $net = $2;
      if ($net !~ /v(c|s)\S+/) {
	$opens_hash{$block}{$net} += 1;
      }
    }
  }
}
foreach $block (keys %opens_hash) {
  foreach $net (keys %{ $opens_hash{$block} }) {
    push (@opens_list, "$block $net $opens_hash{$block}{$net}");
    $total_open_nets++;
    $total_non_power_connections += $opens_hash{$block}{$net} - 1;
    $block_connections{$block} += $opens_hash{$block}{$net} - 1;
    $connection_counts{$opens_hash{$block}{$net}} += 1;
  }
}

foreach $connection (@opens_list) {
  print "$connection\n";
}


print "\n\nConnections Per Block Summary\n";
print "----------------------------------------------------\n";
foreach my $block (sort keys %block_connections) {
  printf "Block->(%-32s)  Connection Count->($block_connections{$block})\n", $block;
}


print "\n\nNet Fanout Summary\n";
print "-------------------------------\n";
my $fanout;
foreach my $connection_count (sort numerically keys %connection_counts) {
  $fanout = $connection_count - 1;
  printf "Fanout->(%2d)  Net Count->($connection_counts{$connection_count})\n", $fanout;
}
print "\n\nTotal Shorts->($total_shorts)\n";
print "Total Open Nets->($total_open_nets)\n";
print "Total Non-Power Connections->($total_non_power_connections)\n";

sub by_connection {
  &ConnectionCount($b) <=> &ConnectionCount($a);
}

sub numerically {
  $b <=> $a;
}

sub ConnectionCount {
  $netstring = shift;
  @record = split(/\s+/, $netstring);
  return $record[2]
}

$sumfh->close


