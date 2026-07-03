#!/usr/intel/pkgs/perl/5.12.2/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Pipe;

my @out_records = ();
while (<>) {
  my @names = split(/\;/, $_);
  foreach my $name (@names) {
    if ($name =~ /\<(\S+)\>/) {
      my $email = $1;
      my $infopipe = IO::Pipe->new;
      $infopipe->reader("/usr/intel/bin/phonebook -c BookName -c WWID -c IDSID -c DomainAddress -c ControlledCountry -c LocCountryCode -c OrigHomeCountryCode $email");
      while (<$infopipe>) {
	if (/WWID/) {
	  next;
	}
	my @record = split(/\|/, $_);
	my $targetstring = sprintf "%-35s %10s %10s %30s %20s %20s %20s",$record[0],$record[1],lc($record[2]),trim($record[3]), trim($record[4]),trim($record[5]),trim($record[6]);
	push @out_records, $targetstring;
      }
      $infopipe->close;
    }
  }
}

if (@out_records) {
  printf "%-35s %10s %10s %30s %20s %20s %20s\n", "Name", "WWID", "IDSID", "Domain Address", "ControlledCountry", "LocCountryCode", "OrigHomeCountryCode";
  foreach my $record (@out_records) {
    print "$record\n";
  }
} else {
  print "No records found\n";
}
print "\n";


sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
