#!/usr/intel/pkgs/perl/5.14.1-threads/bin/perl

my $makesubipfile = "make_subip.source";
my $makesubipfile_h = IO::File->new;
$makesubipfile_h->open(">$makesubipfile") or die "-E- Could not open $makesubipfile for write\n";
my $ipconfig = "ipconfig.pm";
my $ipconfig_h =  IO::File->new;
$ipconfig_h->open(">$ipconfig") or die "-E- Could not open $ipconfig for write\n";
my $finalized = "finalized.pm";
my $finalized_h =  IO::File->new;
$finalized_h->open(">$finalized") or die "-E- Could not open $finalized for write\n";
my $blocksetup = "blocksetup.source";
my $blocksetup_h =  IO::File->new;
$blocksetup_h->open(">$blocksetup") or die "-E- Could not open $blocksetup for write\n";
my %block_hash;
while (<>) {
 chomp;
 my @record = split(/\/|\s+/, $_);
 my $ldb = $record[8];
 @record = split(/_\d\./, $ldb);
 $block = $record[0];
 $block_uc = uc($block);
 $path = $_;
 $path =~ s/\s+\\s*$//;
 #my $target = "HIP_${block_uc}/collateral/ebb";
 my $block_trunc = $block;
 $block_trunc =~ s/_lib$//;
 my $target = "${block_trunc}/collateral/ebb";
 $block_uc = "HIP_${block_uc}";
 unless ($path =~ /\/nfs/) {next};
 if ($path =~ /^\s*\#/) {next};
 if ($path =~ /idv_collaterals/) {next};
 unless (-e $path) {
    #print "ISSUE: $path\n";
 } 
 #$block_hash{$block} = $block_uc;
 $block_hash{$block_trunc} = $block_trunc;
 print "${block_trunc} $block_uc $path\n";

 if ($path =~ /\/ldb\//) {
   $makesubipfile_h->print("mkdir -p ${target}/lib\n");
   $target = "${target}/lib";
   $makesubipfile_h->print("cp -rp ${path} $target\n");
   my $libpath = $path;
   $libpath =~ s/\.ldb/\.lib/;
   $makesubipfile_h->print("cp -rp ${libpath} $target\n");
 } else {
   $makesubipfile_h->print("mkdir -p ${target}/mw\n");
   $target = "${target}/mw";
   $makesubipfile_h->print("cp -rp ${path}/\* $target\n");
 }
}

#$ipconfig_h->print(q($ToolConfig_ips{ipconfig} = {));
#$ipconfig_h->print("\n");
#$ipconfig_h->print(q(VERSION     => 'n/a',));
#  $ipconfig_h->print("\n");
#$ipconfig_h->print(q(SUB_TOOLS => {));
#  $ipconfig_h->print("\n");

$finalized_h->print(q(-children => [));

foreach my $blk (sort keys %block_hash) {
  $ipconfig_h->print(qq(\$ToolConfig_ips\{$blk\} = \{));
  $ipconfig_h->print("\n");
  #$ipconfig_h->print("$blk \=\> \{\n"); 
  $ipconfig_h->print("  VERSION\=\> \"NA\"\,\n");
  $ipconfig_h->print("  PATH\=\> \"\$ENV\{MODEL_ROOT\}\/subIP\/HIP\/$block_hash{$blk}\"\,\n");
  $ipconfig_h->print(q(  OTHER => {));
  $ipconfig_h->print("\n");
  $ipconfig_h->print(q(    unit_parent => "c73p1adpisclklpfamily",));
  $ipconfig_h->print("\n");
  $ipconfig_h->print(q(    -block_type => "hip",));
  $ipconfig_h->print("\n");
  $ipconfig_h->print(q(  },));
  $ipconfig_h->print("\n");
  $ipconfig_h->print(q(};));
  $ipconfig_h->print("\n");
  $finalized_h->print(qq('${blk}',));
}
#$ipconfig_h->print(q(  },));
#$ipconfig_h->print("\n");
#$ipconfig_h->print(q(},));
#$ipconfig_h->print("\n");
$finalized_h->print(q(],));
$finalized_h->print("\n");
$finalized_h->print("\n");



foreach my $blk (sort keys %block_hash) {
  $blocksetup_h->print("ln -s c73p1adpisclklpfamily $blk\n");
  $finalized_h->print("       $blk \=\> \{\n");
  $finalized_h->print(q(        -dut              => [ 'mphyph2' ],));
  $finalized_h->print("\n");
  $finalized_h->print(q(        -block_type  => "hip",));
  $finalized_h->print("\n");
  #$finalized_h->print(qq(        -opus_lib    =\> '',));
  #$finalized_h->print("\n");
  $finalized_h->print(qq(        -enable_ldb  => 1,));
  $finalized_h->print("\n");
  $finalized_h->print(qq(        -enable_mw  => 0,));
  $finalized_h->print("\n");
  $finalized_h->print(qq(        -enable_ndm => 0,));
  $finalized_h->print("\n");
  $finalized_h->print(qq(        -enable_stm => 0,));
  $finalized_h->print("\n");
  $finalized_h->print(q(        -stdlib_type => "d04",));
  $finalized_h->print("\n");
  $finalized_h->print(q(        -lib_variant => "ln,nn,wn",));
  $finalized_h->print("\n");
  $finalized_h->print(q(       },));
  $finalized_h->print("\n");
}

  

=pod


# Which opus library to be used for this block
   16     # if not specified - use block name with '_' removed
   17     -opus_lib => "myopuslib",
   18 
   19     # enable/disable LDB for this HIP
   20     -enable_ldb = 1,
   21 
   22     # enable/disable MW for this HIP
   23     -enable_mw = 1,
   24 
   25     # enable/disable NDM for this HIP (for icc2)
   26     -enable_ndm = 1,
   27 
   28     # enable/disable STM for this HIP (for icc2)
   29     -enable_stm = 1,

$ToolConfig_tools{ipconfig} = {
    4     VERSION     => 'n/a',
    5     SUB_TOOLS => {

c73p4rfshdxrom2048x32img9 => {
    7             # The hip SHIP tag
    8             VERSION => "BXTA0P08RTL2IFC3V1",
    9             # The path to the hip release on FE - for BE we have dc_config configurations
   10             PATH => "$ENV{IP_RELEASE}/hip/c73p4rfshdxrom2048x32img9/&get_tool_version()",
   11             # Envinroment vars to set when using this tool
   12             ENV => {
   13                 C73P4RFSHDXROM2048X32IMG9_ROOT => "&get_tool_path()",
   14             },
   15             # Additional configuration of this hip
   16             OTHER => {
   17                 # Units using this hip
   18                 unit_parent => "pcie_top",
   19                 # block_type of the block
   20                 -block_type => "hip",
   21             },
   22         },
  $ipconfig_h->print("$blk\n");
}


-children => ['c73p1plllccorehptop','c73p1isclkebgclklanetop','c73p1isclkebgcrotop','c73p1isclkebgdebuffgrptop','c73p1isclkebgfbdivgrptop','c73p1isclkebgxtaltop','c73p1isclkebgrcomptop','c73p1isclkebgrefclkbuffertop','d8xsidvmifm4','d8xsidvamifm4'],
       },




=cut
