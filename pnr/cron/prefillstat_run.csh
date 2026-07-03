#!/bin/tcsh

/usr/users/home2/environment/epgenv/bin/pnr -d -b none -pr 1266 -ov /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha -t opus_lay -n prefillstat_temp -cmd "cd $HOME/prefillstat;$HOME/pnr/status/prefillstat.pl"
cd $HOME
chgrp -R mpgall prefillstat
chmod -R 755 prefillstat
rsync -avz --delete --links -e ssh2 prefillstat icsl6009.iil:/nfs/iil/disks/home10/mroha
rsync -avz --delete --links -e ssh2 prefillstat vws801.sc:/nfs/user/home/mroha
rsync -avz --delete --links -e ssh2 prefillstat /www/htdocs/fdc_da/pd
rm -rf /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha/prefillstat_temp
