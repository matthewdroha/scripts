# If blackboxing is required
# set_scm_options -blackbox {qat_top}

# If SRAM/REG file models sneak through (instead of being HIPs)
# Warning: Unable to resolve reference to '__ZEBU_mem_a8_d512_ra_ws' in '\UCIEDDA_D2D_LIB.fblp_fifo_flit_logger :fifo_mem'. (WDDB-164)
# Info: Creating black box for \BlackBox##fifo_mem##UCIEDDA_D2D_LIB.fblp_fifo_flit_logger##__ZEBU_mem_a8_d512_ra_ws ...
set_scm_options -mem_size_threshold 8192