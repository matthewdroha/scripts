 # #    # ###### #####    ##            ####   ####  #    # ###### #  ####   ####  
 # ##   # #      #    #  #  #          #    # #    # ##   # #      # #    # #      
 # # #  # #####  #    # #    #         #      #    # # #  # #####  # #       ####  
 # #  # # #      #####  ######         #      #    # #  # # #      # #  ###      # 
 # #   ## #      #   #  #    #         #    # #    # #   ## #      # #    # #    # 
 # #    # #      #    # #    #          ####   ####  #    # #      #  ####   ####  
                               #######                                            


# gt1280 infra config

## Details
Location: /p/hdk/etc/Projects/s78tc
FE environment is set to 1.18.SP1 liteinfra 


## FE DOA Test
* Run test while in mmg800_infra_configs sandbox. 
* You should see but not be inside the "t" directory.
 
> Example:  /usr/intel/pkgs/perl/5.34.0/bin/prove --verbose :: --proj s78tc --proj_version ${USER}_sbox --cfg gt1280_fe.cth --grp soc,gt1280

> Example:  /usr/intel/pkgs/perl/5.34.0/bin/prove t/clean.t --verbose :: --proj s78tc --proj_version ${USER}_sbox --cfg gt1280_fe.cth --grp soc,gt1280
 

## FE environment setup
`/p/hdk/bin/cth_psetup -p s78tc -cfg gt1280_fe.cth -read_only`
