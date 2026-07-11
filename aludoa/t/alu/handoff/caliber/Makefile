export CONFIG     = caliber.cfg

include ${WORKAREA}/Makefile.env

## Dont edit the below lines
export FLOW              = caliber
export FLOW_ROOT         = ${CHEETAH_RTL_ROOT}/handoff/${FLOW}
export RTL_UTIL_ROOT     = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}
include ${RTL_UTIL_ROOT}/Makefile.genfilelist
