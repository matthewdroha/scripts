#!/bin/bash
# Fail if $WORKAREA directory is not set or doesn't exist
if [ -z "$WORKAREA" ] || [ ! -d "$WORKAREA" ]; then
    echo "Error: WORKAREA is not set or does not exist."
    exit 1
fi
# Clean the following areas in $WORKAREA/power/pprtl2:  partition grdlbuild
rm -rf $WORKAREA/power/pprtl2/partition
rm -rf $WORKAREA/power/pprtl2/grdlbuild

echo "Cleaned $WORKAREA/power/pprtl2/partition and $WORKAREA/power/pprtl2/grdlbuild"

# Clean the following regular files in $WORKAREA/power/pprtl2: Makefile stdcell.ldb.list activity_dir.map prep_pprtl2_* tool.cth output
rm -f $WORKAREA/power/pprtl2/Makefile
rm -f $WORKAREA/power/pprtl2/stdcell.ldb.list
rm -f $WORKAREA/power/pprtl2/activity_dir.map
rm -f $WORKAREA/power/pprtl2/prep_pprtl2_*
rm -f $WORKAREA/power/pprtl2/tool.cth
rm -f $WORKAREA/power/pprtl2/output
echo "Cleaned regular files in $WORKAREA/power/pprtl2"
