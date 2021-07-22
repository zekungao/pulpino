#!/bin/tcsh

if (! $?VSIM_PATH ) then
  setenv VSIM_PATH      `pwd`
endif

if (! $?PULP_PATH ) then
  setenv PULP_PATH      `pwd`/../
endif

setenv MSIM_LIBS_PATH ${VSIM_PATH}/modelsim_libs

setenv IPS_PATH       ${PULP_PATH}/ips
setenv VIP_PATH       ${PULP_PATH}/vip
setenv RTL_PATH       ${PULP_PATH}/rtl
setenv TB_PATH        ${PULP_PATH}/tb

clear
source ${PULP_PATH}/vsim/vcompile/colors.csh

# Prepare modelsim.ini in the current directory
vmap -c
if ( $?RTL_COVERAGE && $RTL_COVERAGE != "" && $RTL_COVERAGE != "0") then
  echo ""
  echo "${Green}--> Enable RTL Coverage... ${NC}"
  echo ""
  ${VSIM_PATH}/patch_modelsim_ini.py ${VSIM_PATH}/modelsim.ini
endif


rm -rf modelsim_libs
vlib modelsim_libs

rm -rf work
vlib work

echo ""
echo "${Green}--> Compiling PULPino Platform... ${NC}"
echo ""

# Behavior models
source ${PULP_PATH}/vsim/vcompile/vip/vcompile_vip.csh         || exit 1
source ${PULP_PATH}/vsim/vcompile/vip/vcompile_vip_timing.csh  || exit 1

# IP blocks
source ${PULP_PATH}/vsim/vcompile/vcompile_ips.csh  || exit 1

# Compile functional version
source ${PULP_PATH}/vsim/vcompile/rtl/vcompile_pulpino.sh  || exit 1
source ${PULP_PATH}/vsim/vcompile/rtl/vcompile_tb.sh       || exit 1

# Compile process specific version
# This may overwrite previous compilations
if ( $?ICB_PATH && "$ICB_PATH" != "" ) then
  # To allow space in the path,
  # replace space to \1, \0 to space for list construction.
  foreach each ( `find "${ICB_PATH}/vsim/vcompile/rtl/" -name '*.sh' -print0 | sort -z | tr ' ' '\1' | tr '\0' ' '` )
    # Convert '\1' back to space
    echo Find "$each" and sourcing ...
    source "$each" || exit 1
  end
endif


echo ""
echo "${Green}--> PULPino platform compilation complete! ${NC}"
echo ""
