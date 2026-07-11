ifeq ($(IFLOW_CHEETAH_RTL_ROOT),) # use shell value, if set; otw use := so we only call cth_query once
   export IFLOW_CHEETAH_RTL_ROOT := $(shell cth_query -tool cheetah-rtl ENVS CHEETAH_RTL_ROOT -resolve)
endif

export iflow_args  ?=
export iflow_local ?= true

iflow_list_stages:
	${IFLOW_CHEETAH_RTL_ROOT}/iflow/scripts/iflow_run.py -ini ${WORKAREA}/iflow/iflow.ini -local true -list_stages
