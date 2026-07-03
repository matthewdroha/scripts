#!/bin/tcsh

/usr/users/home2/environment/epgenv/bin/pnr -d -b none -pr 1266 -ov /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha -t opus_lay -n migstat_temp -cmd "cd $HOME/migstat;$HOME/pnr/mig/migstat.pl"
cd $HOME
chgrp -R mpgall migstat
chmod -R 755 migstat
rsync -avz --delete --links -e ssh2 migstat icsl6009.iil:/nfs/iil/disks/home10/mroha
rsync -avz --delete --links -e ssh2 migstat vws801.sc:/nfs/user/home/mroha
rsync -avz --delete --links -e ssh2 migstat /www/htdocs/fdc_da/pd
rm -rf /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha/migstat_temp
