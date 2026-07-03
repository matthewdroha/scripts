#!/bin/tcsh

cd $HOME
mkdir snap
mkdir snap/cad_root
mkdir snap/bin
mkdir snap/setup
cd ${HOME}/snap/cad_root
rsync -avz --links --delete -e ssh2 icsl6004.iil:/nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/process/p1266 .
cd ${HOME}/snap/bin
ln -s ${HOME}/snap/cad_root/p1266/bin/RCS .
co -f RCS/*
cd ${HOME}/snap/setup
ln -s ${HOME}/snap/cad_root/p1266/setup/RCS .
co -f RCS/*
cd $HOME
chgrp -R mpgall snap
chmod -R 775 snap

if (-e /nfs/fm) then
  rsync -avz --links --delete -e ssh2 ${HOME}/snap/cad_root/p1266 /nfs/site/disks/fm_fdc_s10079/penryn_area/latest_rcs
endif
