#!/bin/tcsh

/usr/users/home2/environment/epgenv/bin/pnr -d -b none -pr 1266 -ov /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha -t opus_lay -n laystat_temp -cmd "cd $HOME/laystat;$HOME/pnr/status/laystat.pl"
cd $HOME
chgrp -R mpgall laystat
chmod -R 755 laystat
rsync -avz --delete --links -e ssh2 laystat icsl6009.iil:/nfs/iil/disks/home10/mroha
rsync -avz --delete --links -e ssh2 laystat vws801.sc:/nfs/user/home/mroha
rsync -avz --delete --links -e ssh2 laystat /www/htdocs/fdc_da/pd
rm -rf /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha/laystat_temp
