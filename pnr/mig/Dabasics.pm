package Dabasics ;

use Exporter ;
@ISA = qw(Exporter) ;
use Cwd ;
use File::Basename ;
#use DBI ;

@EXPORT = qw(assert mydie syscmd slurpfile2hash slurpfile2hashofarrays cksum cksumdir slurpfile2array dumpstring2file dumparray2file dumphash2file printhash printarray mergehash fwd subprint uniqueid getsqlconnection listen talk);

my ($good,$bad) ;

$good = 0 ;
$bad = 1 ;

sub assert {
    my ($code,$msg) = @_ ;

    unless ($code) {

        print "--- assertion stack trace ---\n" ;
        
        my ($pack,$filename,$line,$subname,$i) ;
        
        $i = 0 ;
        while(($pack,$filename,$line,$subname) = caller($i)) {
            print "$filename $subname - $line\n";
            $i ++ ;
        }
        
        print "--- your final error ---\n";
    
        &mydie($msg) ;
    }
}

sub numberofstackframes {
    my ($pack,$filename,$line,$subname,$i) ;
    
    $i = 0 ;
    while(($pack,$filename,$line,$subname) = caller($i)) {
        $i ++ ;
    }
    
    return $i
}

sub subprint {
    my (@list) = @_ ;
    my ($pack,$filename,$line,$subname,$i)  = caller(0) ;
    $filename =~ s/\.\w+$// ;
    $filename =~ tr/A-Z/a-z/ ;
    $filename =~ s/^\S+\/+//;
    $filename = "($filename)" ;

    my ($localtime) = scalar localtime ;


    printf("%14s  (%24s)  ||", $filename, $localtime);
    print "  " x &numberofstackframes() ;
    print @list ;
}

sub mydie {
    my $message = shift;
    print "$message";
    exit ($bad);
}

sub syscmd {
    my $cmd = shift ;
    my $retptr = shift ;
    #print "system: $cmd\n";
    my $junk ;
    $junk = qx/$cmd/;
    # Get  status from system
    my $ret = $? >> 8; 
    
    if (defined $retptr) {
        $$retptr = $junk ;
    }


    if ($ret) {  
        print "-e- error: command completed with error code $ret.\n"; 
    }

    return ($ret);
}

sub fwd {
    my ($path) = shift;
    
    my ($dir,$curwd,$base) ;
    
    $dir = dirname ($path) ;
    $base = basename ($path) ;

    $curwd = cwd() ;
    chdir $dir || die ("-e- error:  can't change dir to \"$dir\"\n");
    $dir = cwd() ;
    chdir $curwd || die ("-e- error:  can't change dir to \"$curwd\"\n");

    return "$dir/$base";
}

sub slurpfile2hash {
    my ($file,$hashptr) ;
    $file = shift;
    $hashptr = shift;

    open (IN,"<$file") || &mydie("-f- fatal:  couldn't open \"$file\" for read.\n");
    while(<IN>) {
        chomp ;
        if (/^\s*(\S+)\s+(.+)\s*$/) {
            $hashptr->{$1} = $2 ;
        } else {
            print "-i- info: ($file) ignored line \"$_\"\n";
        }
    }
    close(IN);
}

sub slurpfile2hashofarrays {
    my ($file,$hashptr) ;
    $file = shift;
    $hashptr = shift;

    open (IN,"<$file") || &mydie("-f- fatal:  couldn't open \"$file\" for read.\n");
    while(<IN>) {
        chomp ;
        if (/^\s*(\S+)\s+(.+?)\s*$/) {
            push @{$hashptr->{$1}}, $2 ;
        } else {
            print "-i- info: ($file) ignored line \"$_\"\n";
        }
    }
    close(IN);
}

sub slurpfile2array {
    my ($file,$aryptr) ;
    $file = shift ;
    $aryptr = shift;

    open (IN,"<$file") || &mydie("-f- fatal:  couldn't open \"$file\" for read.\n");
    while(<IN>) {
        chomp ;
        if (/\S/) {
            push @$aryptr, $_ ;
        }
    }
    close(IN);
    
}

sub dumpstring2file {
    my ($file,$string) ;
    $file = shift ;
    $string = shift;

    open (OUT,">>$file") || &subprint("-f- fatal:  couldn't open \"$file\" for append.\n");
    
    print OUT "$string";
    close(OUT);

}


sub dumparray2file {
    my ($file,$aryptr) ;
    $file = shift ;
    $aryptr = shift;

    open (OUT,">$file") || &mydie("-f- fatal:  couldn't open \"$file\" for write.\n");
    my $line ;
    foreach $line (@$aryptr) {
        print OUT "$line\n";
    }
    close(OUT);

}

sub dumphash2file {
    my ($file,$hashptr) ;
    $file = shift ;
    $hashptr = shift;

    open (OUT,">$file") || &mydie("-f- fatal:  couldn't open \"$file\" for write.\n");
    my $key ;
    foreach $key (keys %$hashptr) {
        print OUT "$key $hashptr->{$key}\n";
    }
    close(OUT);
}

sub mergehash {
    my (%arg) = @_ ;

    assert (defined($arg{"srchash"}), "-e- error:  srchash needs an argument\n");
    assert (defined($arg{"dsthash"}), "-e- error:  dsthash needs an argument\n");
    my ($flagdontcreate, $flagassignall);
    
    my ($srcptr,$dstptr) ;
    $srcptr = $arg{"srchash"} ;
    $dstptr = $arg{"dsthash"} ;

    $flagdontcreate = (defined $arg{"dontcreate"}) ? 1 : 0 ;
    $flagassignall = (defined $arg{"assignall"}) ? 1 : 0 ;
    
    my ($key);
    foreach $key (keys %$srcptr) {
        my ($def,$sef) ;
        assert ((not $flagdontcreate or exists($dstptr->{"$key"})), "-e- error:  creating a key \"$key\" in dsthash\n") ;
    }
    foreach $key (keys %$dstptr) {
        assert ((not $flagassignall or exists($srcptr->{"$key"})), "-e- error:  wanted key \"$key\" in srchash\n") ;
    }

    foreach $key (keys  %$srcptr) {
        $dstptr->{$key} = $srcptr->{$key};
    }
    return 0
}

sub printhash {
    my $hashptr = shift;
    my ($key) ;
    foreach $key (sort keys %$hashptr) {
        &subprint("$key => $$hashptr{$key}\n");
    }
}

sub printarray {
    my $arrptr = shift;
    my ($val) ;
    
    foreach $val (@$arrptr) {
        &subprint("$val\n");
    }
}

sub getsqlconnection {
    my ($host,$user,$db) ;

    $host = "fildb6002.fm.intel.com";
    $user = "userwrite" ;
    $db = "pdda_internal" ;
    
    my $dbh = 'DBI'->connect("DBI:mysql:$db:$host", $user, '') || &mydie("-e- error: couldn't connect to database \"$db\"\n");
    
    return $dbh ;
}

sub cksum {
    my $path = shift ;

    &assert((-e $path), "-e- error: $path doesn't exist.\n");
    
    my ($cksum) ;

    &syscmd("cksum $path",\$cksum) && &mydie("-e- error: couldn't run cksum\n");
    $cksum =~ s/\s+.*\s*$//;
    return $cksum ;
}

sub uniqueid {
    my ($host,$pid,$time) ;
    
    &assert((defined $ENV{'HOST'}), "-e- error:  HOST environment variable wasn't set.\n") ;
    $host = $ENV{'HOST'} ;
    $pid = $$ ;
    $time = time ;

    return "host$host.pid$pid.time$time" ;
}

sub cksumdir {
    my $path = shift ;

    &assert((-e $path), "-e- error: \"$path\" doesn't exist.\n");

    my $cktemp = "$path.cksum.$$.temp";

    my $cksum ;
    if (-f $path) {
        $cksum = &cksum($path);
    } elsif (-d $path) {
        open (OUT,">$cktemp") || &mydie("-e- error: couldn't open \"$cktemp\" for write.\n");
        opendir(INDIR,$path) || &mydie("-e- error: couldn't open \"$path\" for file listing.\n");
        my ($d,@dir) ;
        @dir = readdir(INDIR) ;
        closedir INDIR ;
        foreach $d (sort @dir) {
            if ($d eq "." || $d eq ".." || $d =~/cksum/) { next ; }
            print OUT &cksum("$path/$d");
            print OUT " $path/$d\n";
        }
        close(OUT);
        $cksum = &cksum($cktemp);
        &syscmd("rm $cktemp") && &mydie("-e- error: couldn't run cksum on \"$cktemp\".\n");
    } else {
        &assert(0, "-e- error:  break in dacksum logic.\n");
    }
    
    $cksum =~ s/\s+.*$//;
    
    return $cksum ;
}

sub listen {
    my ($fh,$msgptr) = @_ ;
    my ($sline,$notokay,$err) ;

    alarm 5 ;
    $notokay = 1 ;
    $$msgptr = "" ;
    $err = "no error";
    while(defined($sline = <$fh>)) {
        #alarm 0 ;    #these inner loop alarms can be turned on to allow work inside the loop
        $notokay = 1 ;
        if ($sline !~ /\w/) {
            $err = "blank line received...\n";
            print $err ; 
            last ;
        }
        $notokay = 0 ;
        chomp $sline ;
        $$msgptr = $sline ;
        last ;
        #alarm 5 ;
    }
    alarm 0 ;
    #handshake
    if ($notokay) {
        print $fh "$err" ;
    } else {
        print $fh "okay\n" ;
    }
    return $notokay ;
}

sub talk {
    my ($fh,$msg) = @_ ;
    my ($sline,$notokay) ;

    print $fh $msg ;

    #handshake 

    alarm 5 ;
    $notokay = 1 ;
    while(defined($sline = <$fh>)) {
        $notokay = 1 ;
        if ($sline !~ /okay/) {
            print "-e- error:  improper handshaking...\n";
            print "            $sline";
            last ;
        }
        $notokay = 0 ;
        last ;
    }
    alarm 0 ;

    return $notokay
}

1;
