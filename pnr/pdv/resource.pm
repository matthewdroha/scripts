#!/usr/bin/perl -w 

use strict ; 
package my_regex_hash ; 

sub ret_regex {
    my $regex_hashp = {"cvscmp_standard" =>    "^(clean|DIRTY)\\s+cvscmp\\s+standard\\s+(\\d+)\\s+(\\d+)",
                       "cvscmp_alternative" => "^(clean|DIRTY)\\s+cvscmp\\s+alternate\\s+(\\d+)\\s+(\\d+)",
                       "badnet" =>             "^(clean|DIRTY)\\s+badnet\\s+(\\d+)\\s+(\\d+)" ,
                       "badport" =>            "^(clean|DIRTY)\\s+badport\\s+(\\d+)\\s+(\\d+)",
                       "badsyn" =>             "^(clean|DIRTY)\\s+badsyn\\s+(\\d+)\\s+(\\d+)" ,
                       "cdenwfub" =>           "^(clean|DIRTY)\\s+cdenwfub\\s+(\\d+)\\s+(\\d+)",
                       "containerscheck" =>    "^(clean|DIRTY)\\s+containerscheck\\s+(\\d+)\\s+(\\d+)",
                       "drcd" =>               "^(clean|DIRTY)\\s+drcd\\s+(\\d+)\\s+(\\d+)",
                       "fltgnac" =>            "^(clean|DIRTY)\\s+fltgnac\\s+(\\d+)\\s+(\\d+)",
                       "fubhalfdrc" =>         "^(clean|DIRTY)\\s+fubhalfdrc\\s+(\\d+)\\s+(\\d+)",
                       "fubinsideoth" =>       "^(clean|DIRTY)\\s+fubinsideoth\\s+(\\d+)\\s+(\\d+)",
                       "fuboob" =>             "^(clean|DIRTY)\\s+fuboob\\s+(\\d+)\\s+(\\d+)",
                       "fubpower" =>           "^(clean|DIRTY)\\s+fubpower\\s+(\\d+)\\s+(\\d+)",
                       "gnacname" =>           "^(clean|DIRTY)\\s+gnacname\\s+(\\d+)\\s+(\\d+)",
                       "gnacpnrstrict" =>      "^(clean|DIRTY)\\s+gnacpnrstrict\\s+(\\d+)\\s+(\\d+)",
                       "hportnomet" =>         "^(clean|DIRTY)\\s+hportnomet\\s+(\\d+)\\s+(\\d+)",
                       "illpdiff" =>           "^(clean|DIRTY)\\s+illpdiff\\s+(\\d+)\\s+(\\d+)",
                       "ipfub" =>              "^(clean|DIRTY)\\s+ipfub\\s+(\\d+)\\s+(\\d+)",
                       "ippjdev" =>            "^(clean|DIRTY)\\s+ippjdev\\s+(\\d+)\\s+(\\d+)",
                       "numgnac" =>            "^(clean|DIRTY)\\s+numgnac\\s+(\\d+)\\s+(\\d+)",
                       "othinsidefub" =>       "^(clean|DIRTY)\\s+othinsidefub\\s+(\\d+)\\s+(\\d+)",
                       "powerdecap" =>         "^(clean|DIRTY)\\s+powerdecap\\s+(\\d+)\\s+(\\d+)",
                       "tpcmp" =>              "^(clean|DIRTY)\\s+tpcmp\\s+(\\d+)\\s+(\\d+)",
                       "trcalt" =>             "^(clean|DIRTY)\\s+trcalt\\s+(\\d+)\\s+(\\d+)",
                       "trcstd" =>             "^(clean|DIRTY)\\s+trcstd\\s+(\\d+)\\s+(\\d+)",
                       "unbleg" =>             "^(clean|DIRTY)\\s+unbleg\\s+(\\d+)\\s+(\\d+)",
                       "uncongnac" =>          "^(clean|DIRTY)\\s+uncongnac\\s+(\\d+)\\s+(\\d+)",
                       "vden" =>               "^(clean|DIRTY)\\s+vden\\s+(\\d+)\\s+(\\d+)",
                       "via0gcn" =>            "^(clean|DIRTY)\\s+via0gcn\\s+(\\d+)\\s+(\\d+)",
                       "vm0isocheck" =>        "^(clean|DIRTY)\\s+vm0isocheck\\s+(\\d+)\\s+(\\d+)",
                       "xydrv" =>              "^(clean|DIRTY)\\s+xydrv\\s+(\\d+)\\s+(\\d+)",
                       "topopens" =>           "^(clean|DIRTY)\\s+topopens\\s+(\\d+)\\s+(\\d+)",
                       "check_pins" =>         "^(clean|DIRTY)\\s+check_pins\\s+(\\d+)\\s+(\\d+)" ,
                       "bonuscon" =>           "^(clean|DIRTY)\\s+bonuscon\\s+(\\d+)\\s+(\\d+)" ,
                       "gclkcts" =>            "^(clean|DIRTY)\\s+gclkcts\\s+(\\d+)\\s+(\\d+)" ,
                       "gclkctsqual" =>        "^(clean|DIRTY)\\s+gclkctsqual\\s+(\\d+)\\s+(\\d+)" ,
                       "gnacpnroth" =>         "^(clean|DIRTY)\\s+gnacpnroth\\s+(\\d+)\\s+(\\d+)" ,
                       "rlsm1portopen" =>      "^(clean|DIRTY)\\s+rlsm1portopen\\s+(\\d+)\\s+(\\d+)" ,
                       "numgnacrls" =>         "^(clean|DIRTY)\\s+numgnacrls\\s+(\\d+)\\s+(\\d+)" ,
                       "trcll" =>              "^(clean|DIRTY)\\s+trcll\\s+(\\d+)\\s+(\\d+)" ,  } ;     



    bless $regex_hashp , "my_regex_hash" ;
    return $regex_hashp ;

}

#########   Check to see all collateral exists and that the setp is correct ###########
sub check_everything {
    my $local_sn = shift ;
    my $pds_sn = shift ;
    my $ward = shift ;
    my $fub = shift ;
    my $cur_tool = shift ;
    my $proj = shift ;


    #####Check  if the mkisp sn and cvssch sn exist ###
    if ( -e "$local_sn" && -e "$pds_sn" ) {
        print "-I- Found the mkisp/$fub.sn and the cvssch/$fub.sn\n" ;
    }else {
        print "-E- Can not find either: \n" ;
        print "-E-\t$local_sn\n" ;
        print "-E-\t$pds_sn\n" ;
        die;
    }

    #### Check the correct setup tool was used ####
    if ($cur_tool eq "opus_lay" || $cur_tool eq "arls") {
        print "-I- The current tool is: $cur_tool.\n" ;
    }else{
        print "-E- Your current tool is set to: $cur_tool\n" ;
        print "-E- You need to re-setup with either:  \"opus_lay\" or \"arls\" \n" ;
        die;
    }




}



######################## Get Grab Sort Check Save #####################


sub store_error {
    my $regex_hp = shift ;
    my $proj     = shift ;
    my $fub      = shift ;
    my $flow     = shift ;
    my $date     = shift ;
    my $time     = shift ;
    my $sum_file = shift ;
    my $sqldb    = shift ;
    my $sqlcmd   = shift ;
    my $old_file = "$sqldb$fub.$flow.old" ;
    my $new_file = "$sqldb$fub.$flow.new" ;

#### Change new to old, Delete old, write in the new to the old position. ##### 
    system ("$sqlcmd -list -p $proj -f $fub -a $flow -note new | perl -p -i -e 's/,new,/,old,/' | grep -v ^project | grep -v ^= > $old_file") ;
    system ("$sqlcmd -delete -f $fub -a $flow -note new -p $proj -force") ;
    system ("$sqlcmd -delete -f $fub -a $flow -note old -p $proj -force") ;
    system ("$sqlcmd -add -file $old_file -force") ;

#######tah dah
    open (SUM_FILE, "<$sum_file") || die "-E- Cannot find iss log file: $sum_file\n" ;
    open (NEW_LOG, ">$new_file")  || die "-E- Cannot open new log file: $new_file for write!\n" ;
    while ( <SUM_FILE> ) {
        chomp ;
        foreach my $kee ( sort keys %{$regex_hp} ) {
            if ( $_ =~ /$regex_hp->{$kee}/ ) {   
                print NEW_LOG "$proj,$fub,$flow,$kee,$2,new\n" ;
            }
        }
    }
    close(SUM_FILE)  || die "-E- Could not close the $sum_file file!!\n" ;
    close(NEW_LOG) || die "-E- Could not close the $new_file!\n" ;
    system ("$sqlcmd -add -file $new_file -force ") ;
    print "-I- Successfully completed BB query and DB exchange\n" ;
}
1;
