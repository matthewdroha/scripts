export CONFIG     = flow.cfg
export POST_SCRIPT = echo 'DONE'

include ${WORKAREA}/Makefile.env


## Dont edit the below lines
export FLOW              = puni
export CHEETAH_RTL_ROOT ?= /p/hdk/cad/Cheetah-RTL/1.32.8/bento
export FLOW_ROOT         = ${CHEETAH_RTL_ROOT}/ippackaging/${FLOW}
export RTL_UTIL_ROOT     = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}


