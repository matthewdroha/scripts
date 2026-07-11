#!/usr/intel/bin/tcsh -f

if (!($?WORKAREA)) then
  echo "WORKAREA is not set"
  exit 1
endif

echo "CTH_SETUP_CMD=$CTH_SETUP_CMD"
setenv VCS_HOME NOT_SET
echo "VCS_HOME=$VCS_HOME"
source `which cth_tsetup` -tool vcs
echo "VCS_HOME=$VCS_HOME"
