#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Pipe;


my %email_hash;
my $type;
while (<>) {
  my @names = split(/\;/, $_);
  foreach my $name (@names) {
    if ($name =~ /(.+)\s+(\S+\@\S+)/) {
      my $fullname = $1;
      my $mail = $2;
      if ($fullname !~ /[a-z]/) {
        $type = q(mailing_list);
      } else {
        $type = q(individual);
      }
      $name = trim($name); 
      print "${mail},${type}\n";
    }
	}
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
