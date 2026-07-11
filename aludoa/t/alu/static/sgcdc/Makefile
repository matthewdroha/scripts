export CONFIG     = flow.cfg

export FLOW              = sgcdc
ifeq ($(CHEETAH_RTL_ROOT),) # use shell value, if set; otw use := so we only call cth_query once
   export CHEETAH_RTL_ROOT := $(shell cth_query -tool sgcdc ENVS CHEETAH_RTL_ROOT -resolve)
endif

export FLOW_ROOT        = ${CHEETAH_RTL_ROOT}/cdc/${FLOW}
export RTL_UTIL_ROOT    = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}
