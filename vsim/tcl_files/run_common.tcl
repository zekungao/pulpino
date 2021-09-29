set TB            tb
set TB_TEST       $::env(TB_TEST)
set VSIM_FLAGS    "-GTEST=\"$TB_TEST\""
set MEMLOAD       $::env(MEMLOAD)
set COVER_SAVE_CMD ""

if { [info exists ::env(RTL_COVERAGE)] && $::env(RTL_COVERAGE) != "" && $::env(RTL_COVERAGE) != "0" } {
  set VSIM_FLAGS "$VSIM_FLAGS -coverage"
  # https://stackoverflow.com/a/49850758/2419510
  set COVER_SAVE_CMD "coverage save -onexit cover.ucdb"
}

set VSIM_SOC_LIB    "-L pulpino_lib"
set VSIM_VIP_LIBS   ""
set VSIM_EXTRA_LIBS ""
