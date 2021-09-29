#!/bin/bash
# \
exec vsim -64 -do "$0"

source ./tcl_files/run_common.tcl

if { [file exists ./tcl_files.icb/run_pl.tcl] } {
  source ./tcl_files.icb/run_pl.tcl
}

source ./tcl_files/config/vsim.tcl
