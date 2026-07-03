#!/usr/bin/perl -w 

use strict ;
use lib "/usr/users/home2/mroha";
#use lib "\/nfs\/user\/home\/rlstamne\/SCRIPTS\/BIG_BROTHER\/query_scripts" ;
#use lib "$DA_UTILS\/md_trk_db\/" ;


use resource ;

#### Get and set environment vars ####

use Env qw(WORK DBB DMSPATH CURRENT_TOOL PROJECT USER DA_UTILS) ;

#my $iss_flow = "rlsallfe0" ;  ###################Can use an input for this or list.....##############
my $iss_flow = "fuballfe0" ;
my $mkisp_sn = "$WORK/netlists/mkisp/$DBB.sn" ;
my $pds_sn   = "$WORK/netlists/cvssch/$DBB.sn" ;
my $sum_file = "$WORK/pds/logs/$DBB.$iss_flow.iss.log.sum" ;
my $SQL_DB   = "/tmp/$USER/" ;
my $sql_cmd  = "$DA_UTILS/md_trk_db/md_act_track.pl" ;



########  Check netlists exist and setup is correct  ##########################


my_regex_hash::check_everything ( $mkisp_sn, $pds_sn, $WORK, $DBB, $CURRENT_TOOL, $PROJECT ) ;

if ($CURRENT_TOOL eq "opus_lay" || $CURRENT_TOOL eq "arls") {
    print "-I- The current tool is: $CURRENT_TOOL.\n" ;
}

######## Generate the query and write to DB #############
my $bar = ret_regex my_regex_hash ( ) ;
chomp (my $date =`date +"%b-%d-%Y"`) ;
chomp (my $time =`date +"%k:%M:%S"`) ;
$bar->store_error($PROJECT, $DBB, $iss_flow, $date, $time, $sum_file, $SQL_DB, $sql_cmd) ;
