export CONFIG     = flow.cfg

## Dont edit the below lines
export FLOW              = h2b
export CHEETAH_RTL_ROOT ?= $(shell cth_query -tool cheetah-rtl ENVS CHEETAH_RTL_ROOT -resolve)
export FLOW_ROOT         = ${CHEETAH_RTL_ROOT}/handoff/${FLOW}
export RTL_UTIL_ROOT     = ${CHEETAH_RTL_ROOT}/rtlutils
include ${FLOW_ROOT}/Makefile.${FLOW}
