#!/usr/intel/bin/perl

use IO::File;

while (<>) {
  chomp;
  my $idsid = $_;
  #my $phonebook = "/usr/intel/bin/phonebook -c BookName -c WWID -c IDSID -c SiteCode -c LocCountryCode -d IDSID -q $_";
  my $phonebook = "/usr/intel/bin/phonebook -c DomainAddress -c IDSID -q $idsid";
  my $phonebookfh = new IO::File;
  $phonebookfh->open("$phonebook|") or die;
  while (<$phonebookfh>) {
    if (/\t$idsid\s*$/i) {
      my @record = split;
      push @emails, $record[0];
    }
  }
}

$mail_line = join(";", @emails);
print "$mail_line\n";
