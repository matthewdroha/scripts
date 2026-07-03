#!/bin/tcsh

/usr/users/home2/environment/epgenv/bin/pnr -d -b none -pr 1266 -ov /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha -t opus_lay -n cktstat_temp -cmd "cd $HOME/cktstat;$HOME/pnr/status/cktstat.pl"
cd $HOME
chgrp -R mpgall cktstat
chmod -R 755 cktstat
rsync -avz --delete --links -e ssh2 cktstat icsl6009.iil:/nfs/iil/disks/home10/mroha
rsync -avz --delete --links -e ssh2 cktstat vws801.sc:/nfs/user/home/mroha
rsync -avz --delete --links -e ssh2 cktstat /www/htdocs/fdc_da/pd
rm -rf /nfs/site/disks/fm_fdc_n25005/penryn_area/sagantec_group/mroha/cktstat_temp
