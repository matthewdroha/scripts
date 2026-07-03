#!/usr/intel/bin/perl 
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:DProf
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:ptkdb
# for profiling:  /usr/intel/pkgs/perl/5.6.1/bin/dprofpp tmon.out


# Ran to create ~/.hsd file
#/nfs/site/proj/vt/tools/hsd/tools/account/release/wrapper/bin/hsdresetpassword


use lib '/nfs/site/proj/vt/tools/hsd/api/release/lib';
use strict;
no strict 'refs';
use HSDQuery;
use HSDFocus;
use HSDAdmin;
use MIME::Entity;
use XML::Simple;


# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Filename: readHsd.pl                        Project: WSM
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# (C) Copyright Intel Corporation, 2008
# Licensed material -- Program property of Intel Corporation
# All Rights Reserved
#
# This program is the property of Intel Corporation and is furnished
# pursuant to a written license agreement. It may not be used, reproduced,
# or disclosed to others except in accordance with the terms and conditions
# of that agreement.
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Original Author: Mike Farabee
#
# Project: WSM
#
# Functional description:
#       
# Written by Mike Farabee  7/1/2008
# Updated by M.Roha  2009_01_05 for MMG
#
# Revision History:
#
# Comments:
# This program supports 2 styles of XML input.
#    <ticket project="WSM" stepping="a0" />
#    <ticket>
#        <project>WSM</project>
#        <stepping>a0</stepping>
#    </ticket>  
#
#
# Environment Assumptions: None
#
# Enhancements: Nothing needed
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# RCS Information:
#
#   $Author: mroha $
#   $Source: /mpg/gwa/mroha/cvsroot/ivb/oracle/readHsd.pl,v $
#     $Date: 2010/01/08 19:57:10 $
# $Revision: 1.1 $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#######################################################
#                  GLOBALS
#######################################################
my $VERSION = '$Revision: 1.1 $';
$VERSION =~ s/\$//g;
my $scriptName = $0;
$scriptName=~ s/.*\///g;
local $main::DEBUG=""; 
#######################################################
#                  Help Message       
#######################################################

my $help_message = <<HERE

    DESCRIPTION:
        This utility is used to query  or modify the HSD layout ticket database.
        Query:
          * It is possible to query a list of all fields in the database.
          * It is possible to query record any or all records in the database.

        Modify:
          * Any number of records can be added to the database by reading record information from a CSV or XML file. 
          * The program has a hard coded set of fields that must be used. Additional field can be used.
             "project","stepping","effort_category","title","layout_module","request_details","opus_sch_config","status"

    SYNTAX: $scriptName [-h][-v][-list][-stage][-xml <file> [-test]] [-csv <file> [-test]]
                        [-query [-where <pattern>]] [-hsd <database>] [-table <name>]
       -h               <- Help message. Also displayed, if no argument exist on command line.
       -v               < -prints version # of program.
       -hsd <database>  <- Name of database
                           Default: hsd_deg_physical_design
       -table <name>    <- Name of primary table
                           Default: md
       -list            <- List all fields in HSD
       -test            <- Do not add new HSD, just echo results to screen (Used with -xml or -csv option) 
       -stage           <- Use staging database instead of production database
       -xml <xml file>  <- Write data to HSD using data from XML file specified
       -csv <csv file>  <- Write data to HSD using data from CSV file specified
       -query           <- Dump data from HSD
       -where <pattern> <- used to add search pattern for query operation (Used with -query option)
              example: -where "md.updated_by='mikef'"

     EXAMPLES:

        List all fields in database:
            $scriptName -list
        Show all records in database:
            $scriptName -query
        Show record in staging database with specific ID:
            $scriptName -stage -query -where "md.id=12122"
        Show all records in staging database where the updated_by field contains the name mikef:
            $scriptName -stage -query -where "md.updated_by='mikef'"

        To test adding records using a CSV file:
        $scriptName -test -csv list_of_repeaters.csv

        To add records using a CSV file:
        $scriptName  -csv list_of_repeaters.csv

        To add records to staging database using a CSV file:
        $scriptName  -stage -csv list_of_repeaters.csv

        To add records using a xml file:
        $scriptName  -xml list_of_repeaters.xml

    Sample CSV file:
     project,stepping,status,layout_module,effort_category,title,request_details,opus_sch_config
     wsm,a0,Open,repeater.axe.repvaxe16p,Gold.repeaters,repvaxe16p repeater cleanup,Combinational repeater cleanup.,latest from dssc
     wsm,a0,Open,repeater.axe.repvaxe7p,Gold.repeaters,repvaxe7p repeater cleanup,Combinational repeater cleanup.,latest from dssc


    Sample XML file (either syntax will work):
    <AddHSD>
        <ticket project="WSM" stepping="a0" status="Open" effort_category="Library.Cell Layout" title="test from Mike" layout_module="exe.fpu.ckct0fox" request_details="test data" opus_sch_config="unknown" />
    <ticket>
        <project>WSM</project> 
        <stepping>a0</stepping>
        <status>Open</status> 
        <effort_category>Library.Cell Layout</effort_category>
        <title>test2 from Mike</title>
        <layout_module> exe.fpu.ckct0fox</layout_module>
        <request_details>test data2</request_details>
        <opus_sch_config>unknown</opus_sch_config>
    </ticket>
    </AddHSD>
    


HERE
;
$help_message =~ s/\t/    /g; # Replace tabs with 4 spaces

# Prints hash, array ,hash of hash, or any combination. Optional 2nd arg is the name of the hash
# usage example: printAny(\%data,"data");
#                printAny(\@data,"data");
sub printAny {
    my ($data,$dataname)=@_;
    my ($key,$index)=(undef) x 2;
    if(ref $data eq "ARRAY"){
        if($dataname eq "" && ref $data eq "ARRAY"){
            $dataname="ARRAY";
        }
        for($index=0;$index<=$#{@$data};++$index){
            if(ref $$data[$index] eq "HASH"){
                &printAny(\%{$$data[$index]},"$dataname\[$index\]");
            }elsif(ref $$data[$index] eq "ARRAY"){
                &printAny(\@{$$data[$index]},"$dataname\[$index\]");
            }else{
                 print STDERR "$dataname\[$index\]=$$data[$index]\n";
            }
        }
    }
    if(ref $data eq "HASH"){
        if($dataname eq "" && ref $data eq "HASH"){
            $dataname="HASH";
        }
        foreach $key (keys %$data){
            if(ref $$data{$key} eq "HASH"){
                &printAny(\%{$$data{$key}},"$dataname\{$key\}");
            }elsif(ref $$data{$key} eq "ARRAY"){
                &printAny(\@{$$data{$key}},"$dataname\{$key\}");
            }else{
             print STDERR "$dataname\{$key\}=$$data{$key}\n";
            }
            }
    }
}


=pod
The following is for Debug
=cut


# can salt the dPrint statements throughout the code and turn them
# on and off with changing the values in the $main::DEBUG Variable
# The first argument can be a key word to specify when the print happens
# If this key is undef , it will always print when debug is on
# usage: dPrint("key","Data to %s","print");
my $deBugOn = sub  {
    my ($level,$string,@args) =@_;
    my($pkg,$file,$line)=caller();
    if(!defined $level || $main::DEBUG eq $level){
        printf(STDERR "-DEBUG- line $line: $string\n",@args);
    }
};
my $deBugOff = sub {};
if(!defined $main::DEBUG || $main::DEBUG eq "") {*dPrint=$deBugOff;} else {*dPrint= $deBugOn;}



sub numerically {$a <=> $b;}
sub reverse_numerically {$b <=> $a;}

##############################################################
# Subroutine: listHsdFields
# Description: Prints out all fields in the defined table
##############################################################
sub listHsdFields {
    my ($hsdDatabase,$table)=@_;
    my ($query,$fcount,$fname,$i)=(undef)x4;

    # Initialize a new query
    $query = new HSDQuery;
    # Open HSD database
    $query->openDB($hsdDatabase) or 
           die "Operation failed openDB() - " . $query->getLastErrMsg() . "\n";

    # Collect all fields from table
    $query->execQuery("select * from $table");
    $fcount = $query->getFieldCount();

    #loop through all records and print out Query information
    for($i=0;$i<$fcount;$i++) {
        $fname = $query->getName($i);
        printf ("Field = $table.%s\n",$fname);
    }
    printf("\n");

    # Close DB
    $query->closeDB() or 
       die "Operation failed closeDB() - " . 
       $query->getLastErrMsg() . "\n";
}


##############################################################
# Subroutine: queryHsd
# Description: Dumps to STDOUT, all records in the database.
# * Allows the ability to refine output by using the SQL WHERE
#   option to refine the search. This utility will add the "WHERE"
#   keyword, but the rest of the search has to be SQL correct including
#   adding the table name if required.
# * This always dumps all fields in the record. only the records
#   are limited by the search.
##############################################################
sub queryHsd {
    my ($hsdDatabase,$table,$search)=@_;
    my ($query,$fcount,$fname,$i)=(undef)x4;

    if($search ne "" ){
        $search = "where ".$search;
    }
    # Initialize a new query
    $query = new HSDQuery;
    # Open HSD database
    $query->openDB($hsdDatabase) or 
           die "Operation failed openDB() - " . $query->getLastErrMsg() . "\n";

    # Collect all fields from table
    $query->execQuery("select * from $table $search");
    $fcount = $query->getFieldCount();

    #loop through all records and print out Query information
    while ($query->read()) {
        print "============================================================\n";
        printf("                    ID %s \n",$query->getVal("id"));
        print "============================================================\n";
        for($i=0;$i<$fcount;$i++) {
            $fname = $query->getName($i);
            printf ("Field=%s Value=%s\n",$fname,$query->getVal($fname));
        }
        printf("\n");
    }

    # Close DB
    $query->closeDB() or 
       die "Operation failed closeDB() - " . 
       $query->getLastErrMsg() . "\n";
}


##############################################################
# Subroutine: verifyRequiredFields
# Description: Checks if all fields exists.
#   Returns an empty string if hash is OK, else it returns a list of missing fields
##############################################################
sub verifyRequiredFields{
my ($hash,$fieldList)=@_;
my ($results,$field)=(undef)x2;

    $results="";
    foreach $field (@$fieldList){
        if(!exists $$hash{$field}){
            $results .= " $field"
        }
    }
    return($results);
}

##############################################################
# Subroutine: writeHsd
# Description: Will create HSD tickets  based on data stored in the hash pointer "$ticketHash"
#   * This module checks to be sure all requred fields exist in the hash before generating the 
#     ticket.
#   * A test mode is provided that allows echoing the data. If the $testMode variable
#     is defined, the output will go to the screen and no HSD ticket will be generated.
##############################################################
sub writeHsd {
my ($hsdDatabase,$table,$ticketHash,$requiredList,$testMode)=@_;
    my ($hsdFocus,$newRecordId,$ticket,$field,$index,$isValid)=(undef)x6;

    # Check if in test mode, If in test mode, do not create new HSD focus
    if(!defined $testMode){
    $hsdFocus = new HSDFocus($table,$hsdDatabase) or
           die "Failed to init - " . HSDFocus::getLastErrMsg() . "\n";
    }

    # The ivariable $index is used to keep track of which record had a problem, 
    # used for printing and error reports 
    $index=1; 
    # loop though all records (tickets) in the ticket hash
    foreach $ticket (@{$$ticketHash{ticket}}){
        # Check if any required field are missing
        $isValid=&verifyRequiredFields($ticket,$requiredList);
        if($isValid eq ""){ # if no fields are missing

            # again check if in test mode, if not create a record otherwise print out the record
            if(!defined $testMode){
                # clear contents of focus
                $hsdFocus->clearRec() or
                   die "failed to prepNewRec - " . 
                   $hsdFocus->getLastErrMsg() . "\n";

                # loop through all fields defined in the ticket hash and assign the data
                foreach $field (keys %$ticket){
                    if(ref $$ticket{$field} eq "ARRAY"){ # support 2 forms of input (see top of file)
                        $hsdFocus->setVal($field,$$ticket{$field}[0]);
                    }else{
                        $hsdFocus->setVal($field,$$ticket{$field});
                    }
                }

                #Insert the new record into HSD
                $newRecordId = $hsdFocus->insertRec(1);
                if($newRecordId==0){
                    printf("%s\n",$hsdFocus->getLastErrMsg());
                }else{
                    printf("Inserted: %d\n",$newRecordId);
                }
            }else { # in test mode
                # loop through all fields defined in the ticket hash and prin them
                foreach $field (keys %$ticket){
                    if(ref $$ticket{$field} eq "ARRAY"){# support 2 forms of input (see top of file)
                        printf("Ticket #%d: %s=%s\n",$index,$field,$$ticket{$field}[0]);
                    }else{
                        printf("Ticket #%d: %s=%s\n",$index,$field,$$ticket{$field});
                    }
                }
            }
        }else{ # Found an error (one or more required fields were not defined in hash entry
            printf STDERR ("-E- Error: Ticket #%d submission skipped because it is missing one or more required field(s):\n",$index);
            printf STDERR ("   %s\n",$isValid);
        }
        ++$index;
    }

}

##############################################################
# Subroutine: readCSV
# Description: Reads a CSV file containing new ticket information
# The first line of the CSV file needs to contain the header information
#
##############################################################
sub readCSV{
    my ($infile,$hash)=@_;
    my ($lineNo,$ticket,$index)=(undef)x3;
    my @header=();
    my @data=();
	if (! -e $infile){
		print STDERR "ERROR: $infile can't open for read!\n";
		exit 1;
	}

    $lineNo=0;
    $ticket=0;
	open(FILE, $infile)|| die "Can't open:  $infile";
	while(<FILE>) {
		chomp;
        s///;
        if($lineNo==0){
           @header=split(',');
        }else{
           @data=split(',');
           for($index=0;$index<=$#data;++$index){
            $$hash{ticket}[$ticket]{$header[$index]}=$data[$index];
           }
           ++$ticket;
        }
        ++$lineNo;

	}
	close FILE;
}

#sub adminHsd{
#my ($hsdDatabase,$table)=@_;
#
#    my ($gadmin,$fcount,$i)=(undef)x3;
#    my @flist=();
#    my %lookup=();
#    $gadmin = new HSDAdmin;
#    $gadmin->init($hsdDatabase) or die "Operation failed - init() " . $gadmin->getLastErrMsg() . "\n"; 
#    $fcount = $gadmin->getFieldCount("md");
#    printf("->field count = %d\n",$fcount);
#   
#=pod 
#    my @flist = @{$gadmin->getFieldList("md")};
#    for($i=0;$i<=$#flist;$i++) {
#        print "FieldName=", $flist[$i]->[0], "\n";
#        print "Default Value=", $flist[$i]->[1], "\n";
#        print "DataType=", $flist[$i]->[2], "\n";
#        print "MaxLeng=", $flist[$i]->[3], "\n";
#        print "ColDescription=", $flist[$i]->[4], "\n";
#    }
#=cut
#    # get the lookup value for layout_module 
#    %lookup = $gadmin->getLUVal("md", "effort_category") or die "Operation failed - getLUVal() " . $gadmin->getLastErrMsg() . "\n";
#    foreach $i (keys %lookup) {
#        print "Field=$i \t\t Comment=", $lookup{$i} , "\n";
#    }
#
#    $gadmin->addLUVal("md", "effort_category", "testing.mf") or die "Operation failed - addLUVal() " . $gadmin->getLastErrMsg() . "\n";
#
#}

#######################################################
#######################################################
#                       MAIN
#######################################################
#######################################################

my ($hsd,$query,$listFields,$xml,$testMode,$table,$csv,$admin)=(undef)x8;
my @infiles=();
my ($search)=("")x1;
my $xmlData=();
my %csvData=();
my @requiredFields=("project","stepping","effort_category","title","layout_module","request_details","opus_sch_config","status");

$hsd="hsd_mmg_physical_design";
$table= "md";

&dPrint(undef,"In DEBUG Mode:");  

print STDERR "IN $0: @ARGV\n";
$ARGV[0]= "-help"  if $#ARGV <0; # displays help message id no args are defined
while ($ARGV[0]){
    if($ARGV[0] =~ /^-hsd/){ #
        shift;
        $hsd= $ARGV[0];
    }elsif ($ARGV[0] =~ /^-h(.*)/){  #
        print STDERR "$help_message";
        exit 1;
    }elsif($ARGV[0] =~ /^-v(.*)/){ #
        print "$scriptName: $VERSION\n";
        exit;
    }elsif($ARGV[0] =~ /^-where(.*)/){ #
        shift;
        $search = $ARGV[0];
    }elsif($ARGV[0] =~ /^-query(.*)/){ #
        $query=1;
#    }elsif($ARGV[0] =~ /^-admin(.*)/){ #
#        $admin= 1;
    }elsif($ARGV[0] =~ /^-csv(.*)/){ #
        shift;
        $csv= $ARGV[0];
    }elsif($ARGV[0] =~ /^-xml(.*)/){ #
        shift;
        $xml= $ARGV[0];
    }elsif($ARGV[0] =~ /^-test/){ #
        $testMode=1;
    }elsif($ARGV[0] =~ /^-list(.*)/){ #
        $listFields=1;
    }elsif($ARGV[0] =~ /^-stag(.*)/){ #
        $hsd .= "_pre";
    }elsif($ARGV[0] =~ /^-table/){ #
        shift;
        $table=$ARGV[0];
    }else{
    printf("-E- Error: Unknown argument ($ARGV[0])\n");
        print STDERR "$help_message";
        exit 1;
    }
    shift;
}

if(defined $listFields){
    &listHsdFields($hsd,$table);
#}elsif(defined $admin){
#    &adminHsd($hsd,$table);
}elsif(defined $query){
    &queryHsd($hsd,$table,$search);
}elsif(defined $csv){
    &readCSV($csv,\%csvData);
    &writeHsd($hsd,$table,\%csvData,\@requiredFields,$testMode);
}elsif(defined $xml){
    $xmlData=XMLin($xml, searchpath =>".", ForceArray=>1);
    &writeHsd($hsd,$table,$xmlData,\@requiredFields,$testMode);
}

exit;
