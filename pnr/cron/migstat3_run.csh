#!/bin/tcsh

/usr/users/home2/environment/epgenv/bin/pnr -d -b none -pr 1266 -ov /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha -t opus_lay -n migstat3_temp -cmd "cd $HOME/migstat3;$HOME/pnr/mig/migstat3.pl"
cd $HOME
chgrp -R mpgall migstat3
chmod -R 755 migstat3
rsync -avz --delete --links -e ssh2 migstat3 icsl6009.iil:/nfs/iil/disks/home10/mroha
rsync -avz --delete --links -e ssh2 migstat3 vws801.sc:/nfs/user/home/mroha
rsync -avz --delete --links -e ssh2 migstat3 /www/htdocs/fdc_da/pd
rm -rf /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha/migstat3_temp
