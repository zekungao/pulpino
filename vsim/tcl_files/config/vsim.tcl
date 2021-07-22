source tcl_files/config/vsim_ips.tcl

# ModelSim User's Manual
#
# When you specify -L work first in the search library arguments 
# you are directing vsim to search for the instantiated module or UDP in the library 
# that contains the module that does the instantiation.
#
# -L work is required to let pulpino chip use cells with/without timing compile to its own library.
#
set cmd "vsim -quiet $TB \
  -L work \
  $VSIM_SOC_LIB \
  $VSIM_IP_LIBS \
  $VSIM_VIP_LIBS \
  $VSIM_EXTRA_LIBS \
  +nowarnTRAN \
  +nowarnTSCALE \
  +nowarnTFMPC \
  +MEMLOAD=$MEMLOAD \
  -gUSE_ZERO_RISCY=$env(USE_ZERO_RISCY) \
  -gRISCY_RV32F=$env(RISCY_RV32F) \
  -gZERO_RV32M=$env(ZERO_RV32M) \
  -gZERO_RV32E=$env(ZERO_RV32E) \
  -t ps \
  -voptargs=\"+acc -suppress 2103\" \
  $VSIM_FLAGS"

# set cmd "$cmd -sv_lib ./work/libri5cyv2sim"
eval $cmd
eval $COVER_SAVE_CMD

# check exit status in tb and quit the simulation accordingly
proc run_and_exit {} {
  run -all
  quit -code [examine -radix decimal sim:/tb/exit_status]
}
