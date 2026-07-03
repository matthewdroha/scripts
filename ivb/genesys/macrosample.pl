# Create TCL command file (Latency issue with running loop with open pipe, still looking at it)
my $commandfile = "${WARD}/${BASEFILE}.tcl";
my $commandfilefh = new IO::File;
my $command = "run${EXE_PREFIX}";
$commandfilefh->open(">$commandfile") or die $MAINLOG->fatalq("Could not open file for writing: $commandfile");
$commandfilefh->printf("namespace eval $EXE_PREFIX {\n\n");
$commandfilefh->printf("proc $command \{\} \{\n");
foreach my $tclfile (@tcl_modules_list) {
  if ($tclfile =~ /mig/) {
    $commandfilefh->printf("source $tclfile\n");
  }
}
$commandfilefh->printf("Shorts setOption -depthToCheck 99\n");
$commandfilefh->printf("Shorts setOption -extendedCategories 0\n");
$commandfilefh->printf("Shorts setOption -mergeSynthNet 1\n");
$commandfilefh->printf("Shorts setOption -checkMultipins 0\n");
$commandfilefh->printf("::Shorts setOption -writeLogFile 1\n");
foreach my $aicell (@aicell_list) {
  $commandfilefh->printf("Read -cellname $aicell -viewname lnf\n");
  $commandfilefh->printf("::mig::getCellMetrics\n");
  #$commandfilefh->printf("::Shorts setCell -cell $aicell\n");
  #$commandfilefh->printf("set shortscount [Shorts find]\n");
  #$commandfilefh->printf("::boo::IOUT 1 1 \"cellstudystat: Shorts count for cell $aicell = \$shortscount\"\n");
  #$commandfilefh->printf("Shorts remove\n");
  $commandfilefh->printf("DiscardAll -noask\n");
}
$commandfilefh->printf("\}\n\}\n");
