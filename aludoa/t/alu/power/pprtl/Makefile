export CONFIG     = flow.cfg

## Dont edit the below lines
export FLOW              = pprtl
ifeq ($(CHEETAH_RTL_ROOT),) # use shell value, if set; otw use := so we only call cth_query once
  export CHEETAH_RTL_ROOT := $(shell cth_query -tool pprtl ENVS CHEETAH_RTL_ROOT -resolve)
endif

export FLOW_ROOT = ${CHEETAH_RTL_ROOT}/lowpower/${FLOW}

include ${FLOW_ROOT}/Makefile.${FLOW}
