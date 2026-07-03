#!/usr/intel/bin/perl

$| = 1;

##PUT NAME OF REQUIRED RV LAYERR FILES BELOW##

push(@flows, "DCC_ALL_BIN_rv.scaled.layerr.gz");
push(@flows, "DCC_ALL_rv.scaled.layerr.gz");
push(@flows, "NETRV_ALL_rv.scaled.layerr.gz");
push(@flows, "PWR_SFACTOR_ALL_rv.scaled.layerr.gz");
push(@flows, "SIGNAL_SFACTOR_ALL_rv.scaled.layerr.gz");
push(@flows, "TAVORPWR_ALL_rv.scaled.layerr.gz");

################################################

$date = `date +"%m-%d-%EY-%H:%M:%S"`;
chomp($date);
$path = "$ENV{DRIVE_DB}/fubs";
$outfile = "$ENV{WORK_AREA_ROOT_DIR}/rv/rvinfo_${date}.csv";

unless(-e $path){
  print("\nNeed to be in a UE setup to run $0\n");
  exit;
}

open(FILE, ">$outfile") || die "Can't open $outfile\n";


foreach $fub(`ls $ENV{DRIVE_DB}/fubs/`){
  chomp($fub);
  print("\nRunning on $fub\n");
  $fubline = $fub;
  foreach $flow (@flows){
    unless($out){
      @head = split(/\./, $flow);
      $head[0] =~ s/_rv//g;
      $head[0] =~ s/_ALL//g;
      $header .= ",$head[0]";
    }
    if(-e "$path/$fub/greatest/genesys/layerr/$fub.$flow"){
      $total = `gzgrep "TotalErrors" $path/$fub/greatest/genesys/layerr/$fub.$flow`;
      chomp($total);
      ($j, $total1) = split(' ', $total);    
      $total1 =~ s/\)//g;
      if($total1 == ""){
        $total1 = "0";
      }
    } else {
        $total1 = "MIA";  
      }
    $fubline .= ",$total1";
  }
  $out .= "$fubline\n";
}
  
print(FILE "FUB$header\n");
print(FILE "$out");
close(FILE);

print("\n\nFinished running $0\n\nScaled output is located at $outfile\n\nHave a Nice Day:\)\n\n");
exit;
