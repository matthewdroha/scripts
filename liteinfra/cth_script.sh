#!/bin/bash --norc

if [ -z "$WORKAREA" ] || [ ! -d "$WORKAREA" ]; then
    echo "Error: WORKAREA is not set or does not exist."
    exit 1
fi

echo "CTH_SETUP_CMD=$CTH_SETUP_CMD"
export VCS_HOME=NOT_SET
echo "VCS_HOME=$VCS_HOME"
source /p/cth/pu_tu/prd/liteinfra/2.4.p04/commonFlow/bin/cth_tsetup_sh -tool vcs
echo "VCS_HOME=$VCS_HOME"
