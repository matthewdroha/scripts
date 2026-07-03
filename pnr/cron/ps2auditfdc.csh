#!/bin/tcsh

ssh2 icsl4021.iil "cd /mpg/proc/cad/i386_linux24; rsync -avz -e ssh2 siclone filc6006.fm:

# Run the rsync to grab the ps2audit files
cd /usr/users/home2/mroha/migstat/ctl/ps2audit
rsync -avz -e ssh2 /nfs/site/disks/fm_fdc_s10079/penryn_area/ps2audit_files_here/* .
ssh2 vws801.sc "cd /nfs/sc/proj/pnr/pnr034/ps2audit_files_here; rsync -avz -e ssh2 * filc9020.fm:/usr/users/home2/mroha/migstat/ctl/ps2audit/."

# Run the rsync for the audit data
cd /nfs/site/disks/fm_fdc_s10079/penryn_area/mroha
rsync -avz --delete --links -e ssh2 ps2_audit vws801.sc:/nfs/sc/proj/pnr/pnr034
