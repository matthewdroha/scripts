package stm ;
use Dabasics ;
require "gdsii.ph" ;

sub new {
    my ($TYPE,$filename) = @_ ;

    my $self ;
    $self->{'filename'} = $filename ;  
    @{$self->{'records'}} = () ;

    return bless($self,$TYPE) ;
}



sub readchunk {
    my $fh = shift;
    my $size = shift ;

    my ($data) ;
    $data = "" ;
    for (my $i = 0 ; $i < $size ; $i ++) {
        my ($d) ;
        unless (read($fh,$d,1)) { return 0 ;}
        $data = $data . $d ;
    }
    return $data ;
}

sub readdatachunk {
    my $fh  = shift ;
    my $datatype = shift ;
    my $dataptr = shift ;
    
    my ($d,$size) ;

    if ($datatype == 1) {       #one word bit array
        $size = 2 ;
        $d = &readchunk($fh,$size);
        $d = unpack('B16',$d) ;
    } elsif ($datatype == 2) {  #one word signed integer (2's complement)
        $size = 2 ;
        $d = &readchunk($fh,$size);
        $d = unpack('n',$d) ;
        if ($d > 2**($size*8 - 1)) {
            $d = $d - 2**($size*8) ;
        }
    } elsif ($datatype == 3) {  #two word signed integer (2's complement)
        $size = 4 ;
        $d = &readchunk($fh,$size);
        $d = unpack('N',$d) ;
        if ($d > 2**($size*8 - 1)) {
            $d = $d - 2**($size*8) ;
        }
    } elsif ($datatype == 4) {  #two word float
        $size = 4 ;
        $d = &readchunk($fh,$size);
        &mydie("-f- fatal:  datatype \"$datatype\" not supported, supposedly never used anymore...\n We'll see.\n");
    } elsif ($datatype == 5) {  #four word float / handled as two word :(
        $size = 8 ;
        $d = &readchunk($fh,$size);
        $d = unpack('B64',$d) ;
        if ($d =~/^(\d)(\d{7})(\d{32})\d*$/) {
            #print "FLOAT $d ";
            my ($s,$e,$m) = ($1,$2,$3);
            $e = "0$e";
            $e = unpack('C',pack('B*',$e));
            $e = $e - 64 ;
            $m = unpack('N',pack('B*',$m));
            #print "$s $e $m " ;
            $m = $m / (2**32) ;
            $d = $m * (16 ** $e) ;
            #print "$d\n";
        } else {
            &mydie("-f- fatal:  float conversion problem.\n");
        }
        
    } elsif ($datatype == 6) {  #string
        $size = 1 ;
        $d = &readchunk($fh,$size);
        $d = unpack('c',$d);
        $d = (33 <= $d && $d <= 126) ? chr($d) : chr($d) ;
        #$d = unpack('a',$d);
    } else {  
        &mydie("-e- error:  datatype: \"$datatype\" is unsupported.  program terminated.\n");
    }

    push @$dataptr, $d ;

    return $size ;
}

sub readrecord {
    my $self = shift ;
    my $fh = shift;
    
    if (-eof $fh) { return 0; } 
    
    my $recordlength = unpack('n',&readchunk($fh,2));
    my $recordtype = unpack('c',&readchunk($fh,1) );
    my $datatype = unpack('c',&readchunk($fh,1)) ;


    my %record ;
    $record{'length'} = $recordlength ;
    $record{'type'} = $gds_record2string{$recordtype} ;
    $record{'datatype'} = $datatype ;

    my $count = 4 ;
    my @data ;
    while ($count < $recordlength) {
        $count = $count + &readdatachunk($fh,$datatype,\@{$record{'data'}});
    }
    
    push @{$self->{'records'}}, \%record ;
    return 1 ;
}

sub readgds {
    my $self = shift ;

    open(IN,"$self->{filename}") || &mydie("-e- error: couldn't open \"$self->{filename}\" for read.\n");
    while ($self->readrecord(IN)) {
    }
    close(IN);

}

sub writegds {
    my $self = shift ;
    my $filename = shift ;
    open (OUT, ">$filename") || &mydie("-e- error:  couldn't open \"$filename\" for write.\n");

    my ($r,$d) ;
    print "writing $#{$self->{records}} to $filename\n";
    foreach $r (@{$self->{'records'}}) {
        print OUT pack('n', $r->{'length'});
        print OUT pack('c', $gds_string2record{$r->{'type'}});
        print OUT pack('c', $r->{'datatype'});

        foreach $d (@{$r->{'data'}}) {        
            if ($r->{'datatype'} == 1) {
                print OUT pack('B16', $d) ;
            } elsif ( $r->{'datatype'} == 2) {
                if ($d < 0) {
                    $d = $d + 2**16 ;
                }
                print OUT pack('n', $d);
                
            } elsif ( $r->{'datatype'} == 3) {
                if ($d < 0) {
                    $d = $d + 2**32 ;
                }
                print OUT pack('N', $d);
            } elsif ( $r->{'datatype'} == 4) {
                &mydie("-f- fatal:  datatype \"$r->{datatype}\" not supported, supposedly never used anymore...\n We'll see.\n");
            } elsif ( $r->{'datatype'} == 5) {
                my ($s,$e,$m) ;
                $s = 0 ;
                #print "UNFLOAT $d " ;
                if ($d < 0) {
                    $d = 0 - $d ; 
                    $s = 1 ;
                } 

                $e = int(log($d)/log(16)) + 1 ;
                $d = $d / (16 ** $e) ;
                $m = int($d * (2**32)) ;
                #print "$s $e $m " ;
                $e = $e + 64 ;
                
                my ($binary) ;
                $binary = "0"x64 ;
                substr($binary,0,1) = $s;
                $e = unpack('B8', pack('c', $e));
                $e = substr($e,1,7) ;
                #print " $e " ;
                substr($binary,1,7) = $e ;
                $m = unpack('B32', pack('N',$m)) ;
                substr($binary,8,32) = $m ;
                print OUT pack('B64',$binary);
                #print "$binary\n";
            } elsif ( $r->{'datatype'} == 6) {
                print OUT pack('c', ord($d));
            } else {
                &mydie("-e- error:  datatype \"$r->{datatype}\" is unsupported... terminated\n");
            }
        }


    }
    close (OUT);

}

sub readascii {
    my $self = shift ;
    my $filename = shift ;

    open (IN, "<$filename") || &mydie("-e- error:  couldn't open \"$filename\" for read.\n");
    while(<IN>) {
        if (/^\s*(\S+)\s*(\d+)\s+(\d+)\s*\:\s*\'*(.*?)\'*\s*\;/) {
            my (%record, $d, @data) ;
            
            $record{'type'} = $1 ;
            $record{'datatype'} = $2 ;
            $record{'length'} = $3 ;
            $d = $4 ;

            if ($record{'datatype'} == 6) {
                @data = split(/\s*/,$d);
            } else {
                @data = split(/\s+/,$d);
            }

            @{$record{'data'}} = @data;
            push @{$self->{'records'}}, \%record ;
        }
    }
    close IN ;

}

sub writeascii {
    my $self = shift ;
    my $filename = shift ;

    open (OUT, ">$filename") || &mydie("-e- error:  couldn't open \"$filename\" for write.\n");

    my ($r,$d) ;
    print "writing $#{$self->{records}} to $filename\n";
    foreach $r (@{$self->{'records'}}) {
        print OUT "$r->{type} $r->{datatype} $r->{length} : ";
        
        if ($r->{'datatype'} == 6) {
            print OUT "'" ;
            foreach $d (@{$r->{'data'}}) {
                print OUT "$d" ;
            }
            print OUT "'" ;
        } else {
            foreach $d (@{$r->{'data'}}) {
                print OUT "$d " ;
            }
        }
        print OUT ";\n";
    }
    close (OUT);
}


# deprecated 07/30/2004
sub glance {
    my $self = shift ;
    open (IN, "<$self->{filename}") || &mydie("-e- error:  couldn't open \"$self->{filename}\" for read.\n");
    open (OUT,">$self->{filename}.out") || &mydie("-e- error:  couldn't open \"$self->{filename}.out\" for write.\n");
    my ($type,$line) ;

    my $flag = 1 ;
    while ($self->slurprecord(IN,\$type,\$line)) {
        if ($type eq "TEXT") { $flag = 0 ; } 
        
        if ($flag) {
            print OUT $line ;
        }

        if ($type eq "ENDEL") {$flag = 1 ;} 

    }

    close(IN);
    close(OUT);
}

# deprecated 07/30/2004
sub slurprecord {
    my $self = shift ;
    my $fh = shift ;
    my $typeptr = shift ;
    my $dataptr = shift ;

    $$dataptr = "";
    $$typeptr = 0;

    my $data ;
    my ($recordlength, $datatype, $recordtype) ;
    unless (read $fh, $data, 2) { return 0 ; }
    $$dataptr = $$dataptr . $data ;
    $recordlength = unpack('n', $data) ;
    unless (read $fh, $data, 1) { return 0 ; }
    $$dataptr = $$dataptr . $data ;
    $recordtype = unpack('C', $data) ;
    unless (read $fh, $data, 1) { return 0 ; }
    $$dataptr = $$dataptr . $data ;
    $datatype = unpack('C', $data) ;

    $decode = (defined $gds_record2string{$recordtype}) ? $gds_record2string{$recordtype} : 0 ;
    $$typeptr = $decode ;

    print "$recordtype$datatype - $recordlength - $decode : ";

    my ($chunklength) ;
    if ($datatype == 1) {
        $chunklength = 2;
    } elsif ($datatype == 2) {
        $chunklength = 2 ;
    } elsif ($datatype == 3) {
        $chunklength = 4 ;
    } elsif ($datatype == 4) {
        $chunklength = 4 ;
    } elsif ($datatype == 5) {
        $chunklength = 8 ;
    } elsif ($datatype == 6) {
        $chunklength = 1 ;
    } else {
        $chunklength = 1 ;
    }

    my ($chunk,$dchunk) ;
    my $i = 0 ;
    print "    " ;
    while($i < $recordlength - 4) {
        unless (read $fh, $chunk, $chunklength) { return 0 ; }
        $$dataptr = $$dataptr . $chunk ;
        if ($datatype == 1) {
            $dchunk = unpack('H',$chunk) ;
        } elsif ($datatype == 2) {
            $dchunk = unpack('n',$chunk) ;
            if ($dchunk > 2**($chunklength * 8 - 1)) {
                #print "negative \n" ;
                $dchunk = $dchunk - 2**($chunklength *8 ) ;
            }
        } elsif ($datatype == 3) {
            $dchunk = unpack('N',$chunk) ;
            if ($dchunk > 2**($chunklength * 8 - 1)) {
                #print "negative \n" ;
                $dchunk = $dchunk - 2**($chunklength *8 );
            }
        } elsif ($datatype == 4) {
            $dchunk = unpack('H8',$chunk) ;
        } elsif ($datatype == 5) {
            #$dchunk = unpack('H16',$chunk) ;
            $dchunk = unpack('B64',$chunk) ;
            
            if ($dchunk =~/^(\d)(\d{7})(\d{16})\d*$/) {
                my ($s,$e,$m) = ($1,$2,$3);
                $e = "0$e";
                $e = unpack('C',pack('B*',$e));
                $e = $e - 64 ;
                $m = unpack('n',pack('B*',$m));
                $m = $m / (2**16) ;
                $dchunk = $m * (16 ** $e) ;
            }
            

        } elsif ($datatype == 6) {
            $dchunk = chr(unpack('c',$chunk)) ;
        } else {
            $dchunk = unpack('H',$chunk) ;
        }
        if ($dchunk=~/\w/) {
            print "$dchunk " ;
        }
        $i = $i + $chunklength  ;
    }
    print "\n";

    return 1 ;
}



1;
