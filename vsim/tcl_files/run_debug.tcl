#!/bin/bash
# \
exec vsim -64 -do "$0"

source ./tcl_files/run_common.tcl

set TB            tb
set VSIM_FLAGS    "-gTEST=\"DEBUG\""
set MEMLOAD       "PRELOAD"

source ./tcl_files/config/vsim.tcl
