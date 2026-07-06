#!/usr/intel/pkgs/perl/5.26.1/bin/perl
# -d:ptkdb

#/usr/intel/pkgs/perl/5.14.1-threads/bin/perl

use lib "/nfs/fm/disks/w.mroha.102/HSDES_API/1.0.33_perl/lib";

use UsrIntel::R1;
 
use HSDES::Api;
use Data::Dumper;


###################################
# Obtain kerberos token
###################################
   
system('kinit -R >/dev/null 2>&1');
if ( $? ) {
  system('kinit');
}
    
     
my $api = HSDES::Api->new();
      
# PRODUCTION is production
# PREPRODUCTION is staging
$api->init("PRODUCTION");
      
my $queryObj = $api->query();
my $results = $queryObj->execQuery(qq(select id,rev,title,status_reason,submitted_date where status IS_NOT_EMPTY and tenant = 'pds_services' and subject = 'support' and id = '1604260368')) or die $queryObj->getLastErrorMessage();
        
#print Dumper($results);
print STDERR "$start $end Ticket Count:". scalar(@$results) . "\n";
          
# example of how to iterate the results
my $rev;
my %tickets;
my $status_reason;
exit;
for my $singleRow (@$results) {
  my $id = $singleRow->{"id"};
#  print "$id\n";
  my $status_reason = $singleRow->{"status_reason"};
#  print "$status_reason\n";
  $rev = $singleRow->{"rev"} . "\n";
#  print "$rev\n";
  $submitted_date = $singleRow->{"submitted_date"} . "\n";
#  print "$submitted_date\n";

  my $metadata = $api->metadata();
  my $tenant  = 'pds_services';
  my $subject = 'support';
  my $id      = $id;
  for (my $rev_iter = 1; $rev_iter <= $rev; $rev_iter++) {
    my $history = $metadata->getRecordHistory($tenant, $subject, $id, $rev_iter) or print STDERR "Problem with $id $rev_iter\n";
    next unless $history;
    for $singleRow(@$history) {
      while ( (my $field, my $value) =  each %$singleRow) {
        if ($field =~ /^status_reason$/) {
          $tickets{$id}{$value} = 1;
#print "$field => $value\n";
        }
      }
    }
  }
}

foreach my $ticket (sort keys %tickets) {
  foreach my $status_reason (sort keys %{ $tickets{$ticket} }) {
    print "${ticket},${status_reason}\n";
  }
}
