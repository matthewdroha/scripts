## Dont edit the below lines
export FLOW              = vc_lint
ifeq ($(CHEETAH_RTL_ROOT),) # use shell value, if set; otw use := so we only call cth_query once
   export CHEETAH_RTL_ROOT := $(shell cth_query -tool cheetah-rtl ENVS CHEETAH_RTL_ROOT -resolve)
endif

export FLOW_ROOT         = ${CHEETAH_RTL_ROOT}/static_checks/vc_static
export RTL_UTIL_ROOT     = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}
