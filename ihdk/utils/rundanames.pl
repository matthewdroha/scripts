#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Pipe;


my $sprintf_spec = '%-35s %10s %10s %10s %30s %20s %20s %20s';

my $csvrecord = join(';','Name', 'Email', 'WWID', 'Org Unit', 'Site', 'Group Desc', 'Cost Center', 'Emp Type', 'IDSID');
print "$csvrecord\n";


my %email_hash;
while (<>) {
  my @names = split(/\;/, $_);
  foreach my $name (@names) {
    my $found_wwid = 0;
    my $wwid = '';
    if ($name =~ /\<(\S+)\>/) {
      my $email = $1;
      if (exists $email_hash{$email}) {
        next;
      } else {
        $email_hash{$email} = 1;
      }
      my $infopipe = IO::Pipe->new;
      $infopipe->reader("/usr/intel/bin/phonebook -c WWID $email");
      while (<$infopipe>) {
	      if (/(\d{8})/) {
          $wwid = $1;
        }
      }
      $infopipe->close;
      if ($wwid) {
        my %cdishash;
        my $cdispipe = IO::Pipe->new;
        $cdispipe->reader("/usr/intel/bin/cdislookup -w $wwid");
        while (<$cdispipe>) {
          if (/^\s*(\S+)\s*\=\s+(.+)$/) {
	          $cdishash{$1} = &trim($2);
          }
        }
        $cdispipe->close;
        my $middleinitial;
        if (exists $cdishash{'MI'}) {
          $middleinitial = " $cdishash{'MI'}";
        } else {
          $middleinitial = '';
        }
        my $firstplusmiddle = &trim("$cdishash{'Fname'}${middleinitial}");
        my $idsid_lc = lc($cdishash{'IDSID'});
        my $csvrecord = join('; ',
          $cdishash{'ccMailName'},
		      #qq($cdishash{'Lname'}, $firstplusmiddle),
		      $cdishash{'DomainAddress'},
          $cdishash{'WWID'},
		      $cdishash{'OrgUnitDescr'},
		      $cdishash{'SiteCode'},
          $cdishash{'GLGroupDesc'},
          $cdishash{'GLCostCenterDes'},
          $cdishash{'Emptype'},
          $idsid_lc,
        );
        print "$csvrecord\n";
      } else {
        print STDERR "ERROR BAD EMAIL; $email\n";
      }
    } else {
      print STDERR "ERROR NO EMAIL; $name\n";
    }
	}
}


sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
