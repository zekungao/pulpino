#!/bin/bash
# \
exec vsim -64 -do "$0"

source ./tcl_files/run_common.tcl

if { [file exists ./tcl_files.icb/run.tcl] } {
  source ./tcl_files.icb/run.tcl
}

set VSIM_VIP_LIBS   "$VSIM_VIP_LIBS -L vip_lib"

source ./tcl_files/config/vsim.tcl
