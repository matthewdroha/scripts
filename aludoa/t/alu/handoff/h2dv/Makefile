export CONFIG     = flow.cfg

include ${WORKAREA}/Makefile.env

## Dont edit the below lines
export FLOW              = h2dv
export CHEETAH_RTL_ROOT ?= /p/hdk/cad/Cheetah-RTL/1.32.8/bento
export FLOW_ROOT         = ${CHEETAH_RTL_ROOT}/handoff/${FLOW}
export RTL_UTIL_ROOT     = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}

