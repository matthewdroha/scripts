export CONFIG     = flow.cfg

## Dont edit the below lines
export FLOW              = genfilelist
export CHEETAH_RTL_ROOT ?= $(shell cth_query -tool cheetah-rtl ENVS CHEETAH_RTL_ROOT -resolve)
export FLOW_ROOT         = ${CHEETAH_RTL_ROOT}/rtlutils
export RTL_UTIL_ROOT     = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}

help :
	@echo ""
	@echo "************************************************** Help ***************************************************"
	@echo ""
	@echo   " 1. make gen_filelist   -- To generate filelist for all flows. "
	@echo   " 2. make block_filelist -- To generate partition level filelist. 'BLOCK' keyword must be specified"
	@echo ""
	@echo "***********************************************************************************************************"
	@echo ""
