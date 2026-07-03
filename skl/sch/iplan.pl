#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# $Id: iplan.pl,v 1.7 2009/07/20 17:32:49 agoel4 Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#Akanksha Goel & Pranav Bhatt
#Intel Corporation
#2008-2009 iPlan backend code

################
# Program Info #
################

use strict;
use warnings;
use English;
use IO::File;
use IO::Dir;
use Time::Local;
use File::Copy; 
use File::stat;

my $script_version = '$Revision: 1.7 $';  #'
$script_version =~ s/\$//g;
$script_version =~ s/Revision: //g;
print STDERR "Version: $script_version\n";


my $fubname = shift;
my $user_home = $ENV{"HOME"};
my $project = $ENV{"PROJECT"};
my $db_root = $ENV{"DB_ROOT"};
my $work_area = $ENV{"WORK"};
my $pds_logs = $ENV{"PDSLOGS"};
my $pds_workroot = $ENV{"PDSWORKROOT"};
my $user_name = $ENV{"USER"};

if(exists $ENV{"DB_ROOT"} ){ 
     unless ( $fubname ){
          die "\n  Fubname not specified please run the script with fubname => script <fubname> \n\n";
     }

     print "\n\nEnter the gallery check list number for the fub and press ENTER.\n\n";

     print "1 -> LOR1-FUB \n";
     #print "2 ->LOR1-Pshift-FUB \n";
     #print "3 -> LOR1-Redraw-FUB/Eden-FUB \n";
     #print "4 -> Post-Pshift-Cleanup \n";
     print "2 -> No Gallery steps \n";
     print "\n\nEnter the check list number here:";
     my $chklist ;
     chomp($chklist = <>);
     my @chklist_array =split("", $chklist);
     my $chklist_array_lenght = @chklist_array;
     if ($chklist_array_lenght >1){
          #print "lenght error\n";
          die "Please enter a valid check list number and re-run the script\n\n";
     }
     my $steps;
     my @gallerysteps;
     
     #print "checklist = $chklist  hello\n";
     
     if($chklist !~ /\d+/){
          #print"ennter loop non digit\n";
          die"Please enter a valid check list number and re-run the script\n\n";
     }
     elsif($chklist == 1 ){
          #print"ennter loop 1\n";
          my $dirname ="/nfs/fm/proj/mpg/proc/data/gallery/ivb4cg/gallery_data/chklsts/LOR1";
          my $logfile ="init.txt";
          my $logfilefh = IO::File->new;
          $logfilefh->open("$dirname/$logfile")or die "could not open the file for reading: $logfile";
          while(<$logfilefh>){
               my  @record = split(/\s*=/,$_);
               $steps = $record[0];
               push( @gallerysteps ,  $steps);
          }        
     }
    # elsif($chklist == 2){ 
          #print"ennter loop 2\n";
     #     my $dirname ="/nfs/fm/proj/mpg/proc/data/gallery/ivb4cg/gallery_data/chklsts/LOR1/LOR1-Pshift-FUB";
      #    my $logfile ="init.txt";
       #   my $logfilefh = IO::File->new;
        #  $logfilefh->open("$dirname/$logfile")or die "could not open the file for reading: $logfile";
         # while(<$logfilefh>){
          #     my  @record = split(/\s*=/,$_);
           #    $steps = $record[0];
            #   push( @gallerysteps ,  $steps);
         # }
    # }
    # elsif($chklist == 3){
          #print"ennter loop 3\n";
     #     my $dirname ="/nfs/fm/proj/mpg/proc/data/gallery/ivb4cg/gallery_data/chklsts/LOR1/LOR1-Redraw-FUB/Eden-FUB";
      #    my $logfile ="init.txt";
       #   my $logfilefh = IO::File->new;
        #  $logfilefh->open("$dirname/$logfile")or die "could not open the file for reading: $logfile";
         # while(<$logfilefh>){
          #     my  @record = split(/\s*=/,$_);
           #    $steps = $record[0];
            #   push( @gallerysteps ,  $steps);
         # }
    # }
   #  elsif($chklist == 4){
          #print"ennter loop 4\n";
    #      my $dirname ="/nfs/fm/proj/mpg/proc/data/gallery/ivb4cg/gallery_data/chklsts/LOR1/Post-Pshift-Cleanup";
     #     my $logfile ="init.txt";
      #    my $logfilefh = IO::File->new;
       #   $logfilefh->open("$dirname/$logfile")or die "could not open the file for reading: $logfile"; 
        #  while(<$logfilefh>){
         #      my  @record = split(/\s*=/,$_);
          #     $steps = $record[0];
           #    push( @gallerysteps ,  $steps);
        #  }          
    # }
     elsif($chklist == 2){
          #print"ennter loop 5\n";
     
     }
     elsif($chklist > 2){
          #print"ennter loop >5\n";
          die"hello Please enter a valid check list number and re-run the script\n\n";
     }
    
   
     elsif($chklist =~/|\n|\t|\r|\f|\a|\e/){
          #print"ennter loop n t r\n";
          die"Please enter a valid check list number and re-run the script\n\n";
     }
   

     my $tree_dirname ="$pds_workroot/$user_name.$fubname.drc_V8.iss/run_details.drc_V8";
     my $tree_filename;
     my $scanned_fubname;
     my @fub_tree;
     
     system("/nfs/site/proj/gsr/common/da_utils/lv/ivb_1.0/pdscommand.pl -saveworkdir yes -c $fubname -mode drc_V8");
     opendir(TREEDIR, $tree_dirname)or die "PDS flow aborted can't opendir $tree_dirname: for reading.\n Please re run the script.\n";
     while (defined( $tree_filename = readdir(TREEDIR))) {
          if($tree_filename =~ /(\w+).tree(\d)/){  
               $scanned_fubname = $1;
               if($scanned_fubname eq $fubname ){
                    push(@fub_tree,  $tree_filename);
               }
          }
     }
     my @sorted_fubtree = sort(@fub_tree);
     my $post_fubtree=   pop(@sorted_fubtree);
     my $hier_file = "$tree_dirname/$post_fubtree";
     my $hier_filefh =IO::File->new;
     my @block_name;
     my %block_hier;
     my $block_level;
     my $blockname;
     my $temp_parent ;
     my @block_parent;
     $hier_filefh->open("$hier_file")or die "could not open file $hier_file \n";
     while(<$hier_filefh>){
          if (/(\w+)\s+Level=(\d)./){
               $blockname = $1;
               $block_level =$2;
               $block_hier{$blockname}{NAME} = $blockname;
               $block_hier{$blockname}{LEVEL}= $block_level;
               if( $block_hier{$blockname}{LEVEL} eq 0){
                    $block_hier{$blockname}{PARENT} = [($fubname)];
               }
               elsif( $block_hier{$blockname}{LEVEL} eq 1){
                    push @{$block_hier{$blockname}{PARENT}}, $fubname ;
                    $temp_parent = $block_hier{$blockname}{NAME};
               }
               else{
                    unless( {map { $_ => 1 } @{$block_hier{$blockname}{PARENT}}}->{$temp_parent}){
                         push @{$block_hier{$blockname}{PARENT}},  $temp_parent;
                    } 
               }
          }
     }
    # foreach my $blockname(keys %block_hier){
         # if($blockname !~ /^ai|gnac/){
            #   print "   $block_hier{$blockname}{NAME} , $block_hier{$blockname}{LEVEL} , @{$block_hier{$blockname}{PARENT}}  \n";
         # }
    # }
     my $cmslogfile; 
     my %cmslogfilehash;
     my $cmstime = 0 ;
     my $temp;
     my $cmsdirname = "$work_area/genesys";
     opendir(CMSDIR, $cmsdirname)or die "can't opendir $cmsdirname: for reading \n";
     #unless die " Could not find netlist eco logfile at $work_area/genesys\n";
     # ( defined( $cmslogfile = readdir(CMSDIR))) {die " Could not find netlist eco logfile at $work_area/genesys\n Please run netlist ECO and RE-run the script"; }
     #while( defined( $cmslogfile = readdir(CMSDIR)))or die " Could not find netlist eco logfile at $work_area/genesys\n";


     while( defined( $cmslogfile = readdir(CMSDIR))) {
          if($cmslogfile =~ /cms_(\w+).report.summary_cms_heat_gvtable.\d/){
              # print " logfile found\n";
               my $st = stat("$cmsdirname/$cmslogfile");
               $cmstime = $st->mtime;
               $temp = $1;
               if($fubname eq $temp){
                    $cmslogfilehash{$cmslogfile}{NAME}= $cmslogfile;
                    $cmslogfilehash{$cmslogfile}{TIME} =$cmstime;
               }  
          } 
     }
     
     my $latestcmsfile ;
     my @sortedcmsfiles = sort keys%cmslogfilehash;
     my $check_iflogfile_exists = @sortedcmsfiles;
     if ( $check_iflogfile_exists == 0)
     {
          die "net list ECO files not found at $work_area/genesys \n Please run netlist ECO and RE-run the script  \n";
     }
     $latestcmsfile = pop @sortedcmsfiles;
     my $sumfile = "$work_area/genesys/$latestcmsfile";
     my $sumfilefh =IO::File->new;
     $sumfilefh->open("$sumfile")or die "could not open the file for reading :$sumfile";
     mkdir "$user_home/iplan_summary" ;
     mkdir "$user_home/iplan_summary/$fubname";
     mkdir "$user_home/iplan_summary/$fubname/backup";
     my @oldsumfile =0;
     my $backupfile = "$user_home/iplan_summary/$fubname/backup/"."$fubname"."_backup.txt";
     my $sumdirname = "$user_home/iplan_summary/$fubname";
     opendir(DIR,$sumdirname) or die "can't opendir $sumdirname: $!";
     @oldsumfile = readdir(DIR) ;
     close (DIR);
     if( $oldsumfile[3]  ){
          my $sumoldfilename ="$sumdirname/$oldsumfile[3]";
          copy( $sumoldfilename, $backupfile ) or die " failed to move  $sumoldfilename";     
     }
     my $sum_CSVfile = "$user_home/iplan_summary/$fubname/"."$fubname"."_sum.txt";
     my $FILE = IO::File->new;
     open FILE, ">$sum_CSVfile" or die "Can not create $sum_CSVfile $!\n";
     my %ecodata_hash;
     #my $steps ;
     my $leafcellgenesys;
     #$leafcellgenesys = "Leaf Cell";
    # my @gallerysteps;
     my $time = scalar localtime();
     
     while (<$sumfilefh>){
          my @ecodata = split(/\t/,$_);
          my $wordcount = @ecodata;

          if(($wordcount >8) && ($ecodata[2] eq "notdone")){
               my $block = $ecodata[0];
               my $type = $ecodata[3];
               my $diff = $ecodata[4];
               my $insts = $ecodata[6];
               my $depth = $ecodata[7];
               my $instdiff = $ecodata[8];
               my $celldensity = $ecodata[9];
               $ecodata_hash{$block}{BLOCK}= $block;
               $ecodata_hash{$block}{TYPE}= $type;
               $ecodata_hash{$block}{DIFF}= $diff;
               $ecodata_hash{$block}{INSTS}=$insts;
               $ecodata_hash{$block}{DEPTH}=$depth ;
               $ecodata_hash{$block}{INSTDIFF}=$instdiff;
               $ecodata_hash{$block}{CELLDENSITY}=$celldensity;

          }
     }
     print FILE "PARENT,BLOCK,TYPE,DIFF,INSTS,DEPTH,INST*DIFF,CELLDENSITY,EFFORT,PRIORITY,RUNDATE/TIME \n";  
     print FILE ",Fub Level\n";               
     foreach my $block(sort keys%ecodata_hash){
          if($ecodata_hash{$block}{TYPE} =~ /RepInst|DelInst|AddTrn/){
               print FILE "@{$block_hier{$block}{PARENT}},$ecodata_hash{$block}{BLOCK},$ecodata_hash{$block}{TYPE},$ecodata_hash{$block}{DIFF},$ecodata_hash{$block}{INSTS},$ecodata_hash{$block}{DEPTH},$ecodata_hash{$block}{INSTDIFF},$ecodata_hash{$block}{CELLDENSITY},,,$time\n";
          }
     }        
     print FILE ",Gallery Steps\n";
    
   #  print FILE join("\n",@gallerysteps);
     my $num = @gallerysteps;
     my $var =0;
     for ($var=1; $var <$num;$var++){
          print FILE ",$gallerysteps[$var], Step $var \n";
     }
}



else 
{
     die " \n You are not in the UE setup. Please launch the UE and run the script again. \n\n";
}

print "\n\n";
close(FILE);
close(CMSDIR);
close(TREEDIR);
