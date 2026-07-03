#!/usr/intel/bin/perl

$metal_found = 0;
while (<>) {
  if (/^L\s+(\S+)\;?/) {
    $layer = $1;
    $layer =~ s/\;//g;
  }
  if (/gdsprop\{126\{(.+)gdsprop\{126/) {
    print "Generic Multivalue: $_\n";
    @record = split;
    %net_hash = ();
    foreach $item (@record) {
      if ($item =~ /gdsprop\{126\{(\w+)\}/) {
      	$net = $1;
	if ($net =~ /^\=/) {
	  next;
	} else {
	  $net_hash{$net} = 1;
	}
      }
    }
    if (scalar(keys %net_hash) > 1) {
      print "**** Conflict. Line $. ****\n";
      foreach $key (keys %net_hash) {
        print "Layer: $layer  Net: $key\n";
      }
    }
  }
}
