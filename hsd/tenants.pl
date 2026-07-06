#!/usr/intel/pkgs/perl/5.14.1-threads/bin/perl

use lib "/nfs/fm/disks/fm_eig_00025/mroha/HSDES_API/1.0.28_perl/lib";

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
my $results = $queryObj->execQuery("select id,title where id = 1406558871 and tenant = 'pds_services' and subject = 'support'") or die $queryObj->getLastErrorMessage();
        
print Dumper($results);
         
          
# example of how to iterate the results
#for my $singleRow (@$results) {
#  print $singleRow->{"id"} . "\n";
#}

my $obj = $api->article();
$obj->load(1406558871) or die $obj->getLastErrorMessage();
my @cmt = $obj->getComments();
foreach my $singleComment (@cmt) {
  print "Looking at COMMENT: " . $singleComment->data()->{id} . "\n";
  print Dumper($singleComment->data());
}

print "\n\n\n\# Start Metadata\n\n\n";

my $metadata = $api->metadata();
 
my $tenant  = 'pds_services';
my $subject = 'support';
my $id      = 1406558871;
my $rev     = 2;
  
my $history = $metadata->getRecordHistory($tenant, $subject, $id, $rev) or die $metadata->getLastErrorMessage();
   
for $singleRow(@$history) {
  while ( (my $field, my $value) =  each %$singleRow) {
    print "$field => $value\n";
  }
}
