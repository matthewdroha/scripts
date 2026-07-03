#!/bin/tcsh




if ($2 != "") then
  $SAGROOT/bin/polar -i $2 -o ${fub}_post1265.cif -p $migrate_file -l post1265
else
  $SAGROOT/bin/polar -i in/$fub.cif -o ${fub}_post1265.cif -p $migrate_file -l post1265
endif


echo "%USER-I, Dropping multi-value net name properties.\n"
$SAGROOT/bin/sagperl -I${SAGROOT}/lib -I/usr/intel/pkgs/perl/5.8.2/lib/5.8.2 ../bin/hierarTraverse.pl --i ${fub}_post1265.cif --o ${fub}.cif.propDrop --propertyDrop


echo "%USER-I, Adding texts to layers from their polygons property.\n"
$SAGROOT/bin/sagperl -I${SAGROOT}/lib -I/usr/intel/pkgs/perl/5.8.2/lib/5.8.2 ../bin/hierarTraverse.pl --i ${fub}.cif.propDrop --o $fub.cif.prop2text.$flow_stage --prop2text


echo '\n%USER-I, Add prorts to "portObject" layers  .\n'
$SAGROOT/bin/polar -i $fub.cif.prop2text.$flow_stage -o $fub.cif.generatePorts.$flow_stage -p $migrate_file -l generatePorts

echo "\n\n%USER-I, Writing $fub.stm.prop2text.$flow_stage stm file from cif .\n"
$SAGROOT/bin/layconv -ic $fub.cif.generatePorts.$flow_stage -og $fub.stm.$flow_stage -p $migrate_file 

\rm -f ${fub}_post1265.cif $fub.cif.prop2text.$flow_stage

exit(0)
