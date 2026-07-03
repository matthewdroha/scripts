#!/bin/csh -f

setenv fub $1
if ($fub == "") goto Usage

if !($?LIB_FLOW) setenv LIB_FLOW NO

if (! -e "$fub") mkdir $fub
cd $fub
if ((-e "setup") | (-e "bin")) \rm -rf setup bin
mkdir setup bin
if (! -e "auxiliaries") mkdir auxiliaries

# cp -p /nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/PS3_do_not_touch_cells_rgexp.list auxiliaries/
cp -p /nfs/fm/proj/pnr/fm_cad01/cad/i386_linux24/siclone/PS3_do_not_touch_cells_rgexp.list  auxiliaries/

#if (-e "/nfs/iil/proj/mrm/mrm24/penryn/CentralData/FubsSkipLists/${fub}_PS3_skipCells.list") then
#  set cellsArray = (`cat /nfs/iil/proj/mrm/mrm24/penryn/CentralData/FubsSkipLists/${fub}_PS3_skipCells.list`)

if (-e "/nfs/site/disks/fm_fdc_s10079/penryn_area/CentralData/FubsSkipLists/${fub}_PS3_skipCells.list") then
  set cellsArray = (`cat /nfs/site/disks/fm_fdc_s10079/penryn_area/CentralData/FubsSkipLists/${fub}_PS3_skipCells.list`)
  echo "{\n  cell_swapping [" > auxiliaries/${fub}_PS3_skipCells.list
  foreach cell ( $cellsArray )
    echo "    ^${cell}"'$' >> auxiliaries/${fub}_PS3_skipCells.list
  end
  echo "  ]\n}" >> auxiliaries/${fub}_PS3_skipCells.list
endif



if (-e /nfs/fm) then
  echo "Using Folsom CAD root"
  set rcsroot = /nfs/fm/proj/pnr/fm_cad01/cad/i386_linux24/siclone/process/p1266
else
  set rcsroot = /nfs/site/proj/mpg/proc/cad/i386_linux22/siclone/process/p1266
endif


cd setup
ln -s ${rcsroot}/setup/RCS . 
co RCS/*



cd ../bin
ln -s ${rcsroot}/bin/RCS .
co RCS/*


cd ..
if (! -e "src") mkdir src


if (-e "run$fub") \rm -f run$fub
cat >> run$fub <<END
#!/bin/csh -f

########################### Run Environment Setting ######################################

# Needed when sending jobs to netBatch.
if (\$?NetBatchJob) then
  source ~mroha/pnr/mig/1266_env.src
endif

if (\$#argv>0) then
  setenv work_dir_extension \$1
  echo "\nwork_dir_extension = \$work_dir_extension\n"
else
  setenv work_dir_extension ""
endif

setenv fub $fub

setenv LIB_FLOW $LIB_FLOW

if !(\$?FIX_BITS_PITCH) setenv FIX_BITS_PITCH NO

# When "FIX_BITS_PITCH==YES" the flow will use the cells arrays which will be
# defined in "cellsSize_ucs_priorities.pdb" file under the "auxiliaries" directory. 

if ( (\$LIB_FLOW != YES) & (\$FIX_BITS_PITCH != YES) ) then
  setenv ARRAY_MODE 1
else
  setenv ARRAY_MODE 0
endif

 
rm -rf work-$fub\$work_dir_extension
mkdir work-$fub\$work_dir_extension
if (\$LIB_FLOW != YES) then
  if !(\$?NetBatchJob) then
    bin/runall.csh >& work-$fub\$work_dir_extension/$fub.log &
  else # netBatch run.
    bin/runall.csh >& work-$fub\$work_dir_extension/$fub.log
  endif
else
  bin/runallLib.csh >& work-$fub\$work_dir_extension/$fub.log
endif

END

chmod +x run$fub

exit(0)

Usage:
  echo "\n\nMissing fub name.\n  1266_env.csh <fub-name>\n\n"
  exit(1)

