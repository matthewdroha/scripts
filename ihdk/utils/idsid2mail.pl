#!/usr/intel/pkgs/perl/5.26.1/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Pipe;

my %email_hash;
print qq(IDSID,CDIS_PULL,Email,WWID,Emptype,EmpStatus\n);
while (<>) {
  my @idsids = split(/\s+/, $_);  # allow multiple idsids on one line seperated by space
  foreach my $idsid (@idsids) {
    my %cdishash;
    my $cdispipe = IO::Pipe->new;
    $cdispipe->reader("/usr/intel/bin/cdislookup -i $idsid");
    while (<$cdispipe>) {
      if (/^\s*(\S+)\s*\=\s+(.+)$/) {
        $cdishash{$1} = &trim($2);
      }
    }
    $cdispipe->close;
    if (exists $cdishash{'WWID'}) {
      print qq($idsid,CDIS_SUCCESSFUL,$cdishash{'DomainAddress'},$cdishash{'WWID'},$cdishash{'Emptype'},$cdishash{'StatCode'}\n);
    } else {
      print qq($idsid,CDIS_FAILED,n);
    }
	}
}


sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
