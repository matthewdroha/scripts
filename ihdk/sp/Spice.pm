package Spice ;
require 5.001 ;
 
##################################################################
#    Copyright (c) 2000 Rohit Sharma. All rights reserved.
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
##################################################################
 
#############
#Author      : Rohit Sharma
#Date        : 21 August, 2000.
#Description : SPICE netlist interface
#
#
#
#############

BEGIN {
   require Exporter;
   use Carp ;
   use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION) ;
   @ISA = qw(Exporter);
   @EXPORT = qw(&spiceInit &getTopSubckts &getSubcktList &getSubckt &getVersion &getTerminals &getResistors &getCapacitors &getTransistors &getInstances_orig &getInstances &getBulkConnections &getHierarchy) ;
   $VERSION = 0.01 ;
 
   $SIG{INT} = sub { die "... wait wait. one sec, huh?\n" } ;
   #initilize global variables ;
   $spice::error = "" ;
   $spice::warn = "" ;
   $spice::verbose = 0 ;
   $spice::DEBUG_ = 0 ;
   $spice::tmpFile = "" ;
   $spice::topSubckt = "top" ;
   %spice::subckts = ( ) ;
   }
 
use strict ;
 
sub spiceInit {
   my ( $file ) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   %spice::subckts = ( ) ;  ;# MT

   do {
      carp "no spice file given." ;
      $spice::error = "no spice file given." ;
      return "-1";
      } unless ( defined $file ) ;
   do {
      carp "spice file $file is not a plain text file." ;
      $spice::error = "spice file $file is not a plain text file." ;
      return "-1";
      }unless ( -f $file && -T $file ) ;
 
   Log ( "Processing spice file $file: phase1\n" )
      if ( $spice::verbose ) ;
   my $retValue ;
   $retValue = processSpice ( $file ) ;
   return "-1" if ( $retValue == "-1" ) ;
 
   Log ( "Processing spice file $file: phase2\n" )
      if ( $spice::verbose ) ;
   $retValue = readSpice ( $spice::tmpFile ) ;
   return "-1" if ( $retValue == "-1" ) ;
   return 0; # Initialization sucessful.
}

sub processSpice {
   my ( $file ) = @_ ;
   do {
      $spice::tmpFile = "${file}.tmp" if ($file) ;
      } unless ( -f $spice::tmpFile ) ;
   do {
      carp "Could not open new spice File $spice::tmpFile for writing." ;
      $spice::error = "Could not open new spice File $spice::tmpFile for writing." ;
      return "-1" ;
      } unless open ( TMPSPICE, ">$spice::tmpFile" ) ;
   do {
      carp "Could not open spice File $file for reading." ;
      $spice::error = "Could not open spice File $file for reading." ;
      return "-1" ;
      } unless open ( SPICE, "<$file" ) ;
 
   Log ( "reading spice file ..." ) if ( $spice::verbose ) ;
   my $line ;
   my $prevLine ;
   my $lineNo  = 0;
 
   while ( $line = <SPICE> ) {
      $lineNo++ ;
      Log ( "." ) if ( $lineNo/1000==int($lineNo/1000) && $spice::verbose) ;
 
      $line =~ s/\n//g ;
      next unless ( length $line ) ;# ignore blank lines.
#      next if ( $line =~ m/^\s*\*/ );# weed out comments.
      next if ( $line =~ m/^\s*\*/ && ($line !~ m/Version|library name/)) ;# weed out comments.   MT
      if ( $line =~ m/^\s*\+/ ) {
         $line =~ s/^\s*\+/ /g ; # eat up continuation character +.
         $prevLine .= $line ;
         }
      else {
         print TMPSPICE "$prevLine\n" if ( $prevLine ) ;
         $prevLine = $line ;
         }
      }
   print TMPSPICE "$prevLine\n" if ( $prevLine ) ;
   Log ( "... done.\n" ) if ( $spice::verbose ) ;
   close SPICE ;
   close TMPSPICE ;
   return 0; #phase 1 successful.
   }


sub readSpice ( ) {
   my ( $file ) = @_ ;
   my $subcktName = "" ;
    
   do {
      carp "Could not open new spice File $file for reading." ;
      $spice::error = "Could not open new spice File $file for reading." ;
      return "-1" ;
      } unless open ( TMPSPICE, "<$file" ) ;
 
   my $line ; 
   while ( $line = <TMPSPICE> ) {
      if( $line =~ m/^\s*\+/ ) { # self validation. 
         Log ( "processSpice subroutine didnt work correctly. Bug in the spice.pm\n" ) ;
         return "-1" ;
         }
 
      next unless ( $line =~ m/^\s*x/i ||
                    $line =~ m/^\s*r/i ||
                    $line =~ m/^\s*c/i ||
                    $line =~ m/^\s*m/i ||
                    $line =~ m/Version/i ||
                    $line =~ m/^\s*\.subckt/i ||
                    $line =~ m/^\s*\.end/i
                    ) ;
 
      if ( $line =~ m/^\s*\.subckt/i ) {
         $subcktName = getSubcktName ( $line ) ; 
         do {
            carp "WARN: incorrect .subckt definition: $line.\n" ;
            $spice::warn = "WARN: incorrect .subckt definition: $line.\n" ;
            next ;
            } if ( $subcktName eq "-1" ) ;
         $spice::subckts{$subcktName} = $line ;
         next ;
         }
      elsif ( $line =~ m/^\s*\.ends/i ) {
         do {
            carp "WARN:.ends statment without subckt definition. $line.\n" ;
            $spice::warn = "WARN:.ends statment without subckt definition. $line.\n";
            next ;
            }unless ( $subcktName ) ;
         $spice::subckts{$subcktName} .= $line ;
         $subcktName = "" ;
         next ;
         }
      elsif ( $line =~ m/^\s*x/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*r/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*c/i ) {
        $subcktName =  $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*m/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/Version/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*\.end[\s+|\n]/i ) { last; }
      }
 
   close TMPSPICE ;
   unlink ( $spice::tmpFile ) if ( -f $spice::tmpFile ) ;          # MT commented this out to test
   return 0 ; # mission successful :=)
   }
 
sub getBulkConnections {
   my ($txName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   $spice::warn = "This subroutine has not been implemented yet.\n" ;
   return "-1";
   }


sub getSubcktName {
   my ( $stmt ) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my @parts ;
   $stmt =~ s/^\s*\.subckt\s+//i ;
   @parts = split /\s+/, $stmt ;
if ($spice::DEBUG_ ) { print "\t\tsubckt Name : $parts[0].\n" ; }
   if ( $parts[0] ) { return $parts[0]; }
   else { return "-1" ; }
   }
 
sub getSubckt {
   my ($subckt) = @_ ;
   $spice::error = "" ;
   if ( $subckt && $spice::subckts{$subckt} ) {
      return $spice::subckts{$subckt} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      } 
   }


#sub getHierarchy {
#  my ($subckt, $filter) = @_;
#  my $depth = 0;
#  my @hierList;
#  @hierList = traverseHier($subckt, $depth, $filter, @hierList);
#  return @hierList;
#}
#sub traverseHier ( ) {
#   my ($node, $depth, $filter, @hierList) = @_ ;
#   print "Current: @hierList\n";
##   my @hierList;
#   push(@hierList, "$node,$depth");
#   print "Checking $depth - $node\n" if ($spice::DEBUG_ );
#   $depth = $depth + 1;
#   my %subckts = getInstances($node);
#   my @children = values %subckts ;
#   @children = removeDup(@children);
#   undef %subckts;
#   if ($#children < 0) { return }
#   my $child;
#   foreach $child (@children) {
#        if ($child !~ m/$filter/) {
##          push(@hierList, "$child,$depth");
#          traverseHier($child, $depth, $filter, @hierList);
#        }
#      }
#   return @hierList;
# }
# sub removeDup {
#   my ( @list ) = @_ ;
#   my $part ;
#   my %hash = ( ) ;
#   foreach $part ( @list ) {
#      $part =~ s/\s+//g ;
#      $hash{$part} = 1 if ( length ( $part ) ) ;
#      }
#   @list = keys %hash ;
#   return @list ;
# }
 
## MT
sub getVersion {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;
   my $retValue = "Verilog";

   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/Version:\s*([0-9]+\.[0-9]+)/i ) ;
      return $1;
  }
  return $retValue;  
}

sub getTerminals {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;

   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*\.subckt/i ) ;
      my ( @retValue, $retValue ) ;
      @retValue = getTermName ( $line ) ;
		if( @retValue ) {
         push( @list, @retValue );
      }
   return @list ;
   }
   }

sub getTermName {
   my ( $stmt ) = @_ ;
   my @retVal;
   if ( $stmt !~ m/^\s*\.subckt/i ) {
      $spice::error = "Not a valid terminal declaration.  :$stmt" ;
      return "-1" ;
      }
   my @tmp ;
   @tmp = split /\s+/, $stmt ;
	shift(@tmp);
	shift(@tmp);
   if ( scalar(@tmp) < 1 ) {
      $spice::error = "Not a valid terminal declaration.  :$stmt" ;
      return "-1" ;
      }
   foreach my $ele (@tmp) {
    if ($ele !~ /=/) {      ;# MT skip pal=0  e.g. a b c o vccl vssl nal=0 naw=0 ncl=0 ncw=0 nbl=0 nbw=0
      push(@retVal, $ele);
    }
   }
   return ( @retVal ) ;
   }

sub getCapacitors {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;
 
   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*c/i ) ;
      my @retValue ;
      @retValue = getResCapName ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }
 

sub getResistors {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;
 
   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*r/i ) ;
      my @retValue ;
      @retValue = getResCapName ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }
 
sub getResCapName {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*[rc]/i ) {
      $spice::error = "Not a valid resistor or capacitor declaration.  :$stmt" ;
      return "-1" ;
      }
   my @tmp ;
   @tmp = split /\s+/, $stmt ;
   if ( $#tmp < 3 ) {
      $spice::error = "Not a valid resistor or capacitor declaration.  :$stmt" ;
      return "-1" ;
      }
   return ( $tmp[0], $tmp[3] ) ;
   }
 
sub getTransistors {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;
 
   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*m/i ) ;
      my @retValue ;
      @retValue = getTxName ( $line ) ;
      if ( $#retValue > 0  ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }
 
sub getTxName {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*m/i ) {
      $spice::error = "Not a valid device statement.  :$stmt" ;
      return "-1" ;
      }
   my $tx ;
   my $type ;
   my ($terms, $L,$W, $M) = ("", "", "", 1);
   ( $tx ) = split /\s+/, $stmt ;
   $tx = substr($tx, 1);

   my @tmp ;
   if ( $stmt =~ m/\=/ ) {
      ( @tmp ) = split /\s*\=\s*/, $stmt ;
      ( @tmp ) = split /\s+/, $tmp[0] ;
      if ( $tmp[$#tmp-1] ) {
         $type = $tmp[$#tmp-1] ;

         shift @tmp;
         pop @tmp;
         pop @tmp;
         $terms = join(" ", @tmp);
         $L = $1 if ($stmt =~ m/l\s*\=\s*(\S+)/i);
         $W = $1 if ($stmt =~ m/w\s*\=\s*(\S+)/i);
         $M = $1 if ($stmt =~ m/m\s*\=\s*(\S+)/i);
         }
      else {
         $spice::error = "could not find transistor type." ;
         return "-1" ;
         } 
      }
   else {
      ( @tmp ) = split /\s+/, $stmt ;
      if ( $tmp[$#tmp] ) {
         $type = $tmp[$#tmp] ;
         shift @tmp;
         pop @tmp;
         $terms = join(" ", @tmp);
         }
      elsif ( $tmp[$#tmp-1] ) {
         $type = $tmp[$#tmp-1] ;
         shift @tmp;
         pop @tmp;
         pop @tmp;
         $terms = join(" ", @tmp);
         }
      else {
         $spice::error = "could not find transistor type." ;
         return "-1" ;
         }
      }
   return ( $tx, {TYPE=>$type,TERMS=>$terms,L=>$L,W=>$W,M=>$M} ) ;
   }

sub getTxName_orig {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*m/i ) {
      $spice::error = "Not a valid instance statement.  :$stmt" ;
      return "-1" ;
      }
   my $tx ;
   my $type ;
   ( $tx ) = split /\s+/, $stmt ;
   my @tmp ;
   if ( $stmt =~ m/\=/ ) {
      ( @tmp ) = split /\s*\=\s*/, $stmt ;
      ( @tmp ) = split /\s+/, $tmp[0] ;
      if ( $tmp[$#tmp-1] ) {
         $type = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find transistor type." ;
         return "-1" ;
         } 
      }
   else {
      ( @tmp ) = split /\s+/, $stmt ;
      if ( $tmp[$#tmp] ) {
         $type = $tmp[$#tmp] ;
         }
      elsif ( $tmp[$#tmp-1] ) {
         $type = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find transistor type." ;
         return "-1" ;
         }
      }
   return ( $tx, $type ) ;
   }

sub getInstances_orig {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;
 
   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*x/i ) ;
      my @retValue ;
      @retValue = getInstName_orig ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }
 
sub getInstName_orig {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*x/i ) {
      $spice::error = "Not a valid instance statement." ;
      return "-1" ;
      }
   my $inst;
   my $subckt ;
   ( $inst ) = split /\s+/, $stmt ;
   my @tmp ;
   if ( $stmt =~ m/\=/ ) {
      ( @tmp ) = split /\s*\=\s*/, $stmt ;
      ( @tmp ) = split /\s+/, $tmp[0] ;
      if ( $tmp[$#tmp-1] ) {
         $subckt = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find subckt name." ;
         return "-1" ;
         } 
      }
   else {
      ( @tmp ) = split /\s+/, $stmt ;
      if ( $tmp[$#tmp] ) {
         $subckt = $tmp[$#tmp] ;
         }
      elsif ( $tmp[$#tmp-1] ) {
         $subckt = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find subckt name." ;
         return "-1" ;
         }
      }
   return ( $inst, $subckt ) ;
   }



sub getInstances {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;
 
   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*x/i ) ;
      my @retValue ;
      @retValue = getInstName ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }
 
sub getInstName {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*x/i ) {
      $spice::error = "Not a valid instance statement." ;
      return "-1" ;
      }
   my ($inst, $nets);
   my $subckt ;
   ( $inst ) = split /\s+/, $stmt ;
   $inst = substr($inst, 1);
   my @tmp ;
   if ( $stmt =~ m/\=/ ) {
      ( @tmp ) = split /\s*\=\s*/, $stmt ;
      ( @tmp ) = split /\s+/, $tmp[0] ;
      if ( $tmp[$#tmp-1] ) {
         $subckt = $tmp[$#tmp-1] ;
         shift @tmp;
         pop @tmp;
         $nets = join(" ", @tmp);
         }
      else {
         $spice::error = "could not find subckt name." ;
         return "-1" ;
         } 
      }
   else {
      ( @tmp ) = split /\s+/, $stmt ;
      if ( $tmp[$#tmp] ) {
         $subckt = $tmp[$#tmp] ;
         shift @tmp;
         pop @tmp;
         $nets = join(" ", @tmp);
         }
      elsif ( $tmp[$#tmp-1] ) {
         $subckt = $tmp[$#tmp-1] ;
         shift @tmp;
         pop @tmp;
         pop @tmp;
         $nets = join(" ", @tmp);
         }
      else {
         $spice::error = "could not find subckt name." ;
         return "-1" ;
         }
      }
#   return ( $inst, $subckt ) ;
   return ( $inst, {MASTER=>$subckt,NETS=>$nets} ) ;
   }
 
sub getTopSubckts {
   my @nodes ;
   $spice::error = "" ;
   $spice::warn = "" ;
#   @nodes = keys %spice::subckts ;               ;# ORIG LINE
   @nodes = keys %spice::subckts
        unless (@nodes);            ;# MT
   my @list ;
   my $node1 ;
   my $node2 ;
   foreach $node1 ( @nodes ) {
      my $top = 1 ;
      foreach $node2 ( @nodes ) {
         next if ( $node2 eq $node1 ) ;
         my $inst ;
         my @instances ;
         my %tmp ;
         %tmp = getInstances($node2) ;
         @instances = values %tmp ;
         undef %tmp ;
         foreach $inst ( @instances ) {
#            if ( $inst eq $node1 ) {$top = 0;  last ;}         ;# ORIG
            if ( $inst->{MASTER} eq $node1 ) {$top = 0;  last ;}
            }
         last if ( not $top ) ;
         }
         push @list, $node1 if ( $top ) ;
      }
   return @list ;
   }
 
sub getSubcktList {
   $spice::error = "" ;
   $spice::warn = "" ;
   my @list ;
   @list =  keys %spice::subckts ;
   if ( $#list == -1 ) {
      $spice::error = "could not find subckt name." ;
      return "-1" ;
      }
   return @list ;
   }
 
sub Log {
   my ( $msg ) = @_ ;
   print $msg ;
   }
 
END {
   Log ( "exiting spice... \n" ) if ( $spice::verbose ) ;
   undef $spice::error ;
   undef $spice::warn  ;
   undef $spice::verbose  ;
   undef $spice::DEBUG_ ;
   undef $spice::tmpFile ;
   undef $spice::topSubckt ;
   undef %spice::subckts ;
   }
1; #just for fun.


