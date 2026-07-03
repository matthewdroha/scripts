#!/bin/tcsh

/nfs/site/proj/mpg/proc/cad/em64t_linux26/uesetup/uesetup -d -p ivbstd -hp ivbstd -pr 1270 -b pshift -m latest -ov /nfs/site/disks/fm_fdc_n25005/penryn_area/mroha/ivbstd -t parade_fub -n cellstudy_temp -ot /nfs/site/proj/gsr/common/proj_tools/genesys/overrides/ivb/developer:~mmaestre/ivb.ot -cmd "cd $HOME/cellstudystat;$HOME/ivb/status/cellstudystat.pl --verbose"

cd $HOME
chgrp -R mpgall cellstudystat
chmod -R 755 cellstudystat
rsync -avz --delete --links -e ssh2 cellstudystat /www/htdocs/fdc_da/pd
