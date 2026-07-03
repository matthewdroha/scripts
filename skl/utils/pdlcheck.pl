#!/usr/intel/pkgs/perl/5.12.2/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::File;
use IO::Pipe;


my $pdlfile = '/usr/users/home2/mroha/pdl.names';
my $orgtreefile = '/usr/users/home2/mroha/orgtree.txt';  # Tab delimited


my $start_date = `date`;
print "START: $start_date\n";

# Extract employee information from the PDL names file
my @nameaddress_list;
my %pdl;
my $pdlfilehandle = new IO::File;
my %email_hash;
$pdlfilehandle->open($pdlfile) or die "-E- Could not open $pdlfile for reading\n";
while (<$pdlfilehandle>) {
  @nameaddress_list = split(/\;/, $_);
  foreach my $nameaddress (@nameaddress_list) {
    my $email;
    if ($nameaddress =~ /\<(\S+)\>/) {
      $email = $1;
      printf "%-60s", "Target Mail->(${email})";
      if (exists $email_hash{$email}) {
	print "  *** DUPLICATE ***\n";
	next;
      } else {
	$email_hash{$email} = 1;
      }
    }
    my @record = split(',', $nameaddress);
    my $lastname = trim($record[0]);
    $lastname =~ s/\'/''/g;
    if ($lastname) {
      my $employeedata = getemployeedata($lastname, $email);
      if ($employeedata) {
	my @record = split (',', $employeedata);
	$pdl{$record[0]} = $employeedata;
	print "  *** MATCH ***\n";	
      } else {
	print "  *** PROBLEM ***\n";
      }
    }
  }
}

my $input_name_count =  scalar @nameaddress_list;
my $pdl_name_count = keys %pdl;
print "Number of Outlook names provided as input: $input_name_count\n";
print "Number of unique Outlook names: $pdl_name_count\n";



# Extract employee information from the orgtree.intel.com tab delimited file
my $orgtreefilehandle = new IO::File;
my %orgtree;
$orgtreefilehandle->open($orgtreefile) or die "-E- Could not open $orgtreefile for reading\n";
while (<$orgtreefilehandle>) {
  unless ($. == 1) {
    my @record = split(/\t/, $_);
    my $email = $record[18];
    my $lastname = $record[2];
    my $BookName = $record[0];
    my $IDSID = $record[30];
    my $MgrName = $record[28];
    my $WWID = $record[27];
    my $EmployeeType = $record[31];
    my $Status = $record[33];
    my $outrecord = join(',',$BookName, $MgrName, $WWID, $IDSID, $EmployeeType, $Status);
    $orgtree{$email} = $outrecord;
  }
}
$orgtreefilehandle->close;
my $orgtree_name_count = keys %orgtree;
print "Number of unique Orgtree names: $orgtree_name_count\n\n";


# Check which names are in orgtree but not in the pdl hash
print "*** Checking for names that are in orgtree but not in the pdl list ***\n";
foreach my $email (sort keys %orgtree) {
  unless (exists $pdl{$email}) {
    print "Missing in PDL->($orgtree{$email})\n";
  }
}
print "\n\n";


# Check which names are in the pdl hash but not in the orgtree
print "*** Checking for names that are in the PDL but not in orgtree ***\n";
foreach my $email (sort keys %pdl) {
  unless (exists $orgtree{$email}) {
    print "Missing in Orgtree->($pdl{$email})\n";
  }
}
print "\n\n";

# Check which names are interns


# Check which names are contract


# Check which names are based in Santa Clara







my $end_date = `date`;
print "END: $end_date\n";


# Extract information from orgtree .csv file 

sub getemployeedata {
  my $lastname = shift;
  my $email = shift;
  my $Emptype;
  my $BookName;
  my $DomainAddress;
  my $MgrName;
  my $WWID;
  my $IDSID;
  my $StatCode;

  my $lastnamepipe = IO::Pipe->new;
  $lastnamepipe->reader("/usr/intel/bin/cdislookup -l \"$lastname\"");
  my $multirecord = 0;
  my $wwid = 0;
  while (<$lastnamepipe>) {
    if (/\-\-\-\s*$/) {
      $multirecord = 1;
    }
    if ($multirecord) {
      if (/(\d{8})\s*$/) {
	$wwid = $1;
      }
    }
    elsif (/^\s*WWID\s*\=\s*(\d{8})\s*$/) {
      $wwid = $1;
    }
    if ($wwid) {
      my %info_hash = ();
      my $wwidpipe = IO::Pipe->new;
      $wwidpipe->reader("/usr/intel/bin/cdislookup -w $wwid");
      while (<$wwidpipe>) {
	if (/^\s*(\S+)\s*\=\s*(.+)\s*$/) {
	  $info_hash{$1} = $2;
	}
      }
      $wwidpipe->close;
      if ($info_hash{'DomainAddress'} eq $email) {
	$Emptype = $info_hash{'Emptype'};
	$BookName = $info_hash{'BookName'};
	$DomainAddress = $info_hash{'DomainAddress'};
	$MgrName = $info_hash{'MgrName'};
	$WWID = $info_hash{'WWID'};
	$IDSID = $info_hash{'IDSID'};
	$StatCode = $info_hash{'StatCode'};
	
	my $outrecord = join(',', $DomainAddress, $BookName, $MgrName, $WWID, $IDSID, $Emptype, $StatCode);
	return $outrecord;
      }
    }
  }  
  return '';
}


sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
