#!/bin/tcsh
source ${PULP_PATH}/vsim/vcompile/colors.csh

##############################################################################
# Settings
##############################################################################

set IP=vip_timing
set IP_NAME="vip_timing"


##############################################################################
# Check settings
##############################################################################

# check if environment variables are defined
if (! $?MSIM_LIBS_PATH ) then
  echo "${Red} MSIM_LIBS_PATH is not defined ${NC}"
  exit 1
endif

if (! $?VIP_PATH ) then
  echo "${Red} VIP_PATH is not defined ${NC}"
  exit 1
endif


set LIB_NAME="${IP}_lib"
set LIB_PATH="${MSIM_LIBS_PATH}/${LIB_NAME}"

##############################################################################
# Preparing library
##############################################################################

echo "${Green}--> Compiling ${IP_NAME}... ${NC}"

rm -rf $LIB_PATH

vlib $LIB_PATH
vmap $LIB_NAME $LIB_PATH

echo "${Green}Compiling component: ${Brown} ${IP_NAME} ${NC}"
echo "${Red}"

##############################################################################
# Compiling RTL
##############################################################################

# For tcsh, it looks there is no way to get source path of a script 
# that is sourced by a source script.
# Reference:
#   https://serverfault.com/a/139302/444463
#   https://serverfault.com/a/139313/444463
#   https://unix.stackexchange.com/a/4658
#
# E.g. a.csh is executed (not sourced)
#      a.csh source b.csh
#      b.csh sources c.sh
#
#      b.csh can use $_ to get sourced script name
#      But $_ evaled from c.csh is b.csh
# A workaround is required.
set SOURCED="${VIP_PATH}/vcompile_timing.csh"
source "$SOURCED"

echo "${Cyan}--> ${IP_NAME} compilation complete! ${NC}"
exit 0

##############################################################################
# Error handler
##############################################################################

error:
echo "${NC}"
exit 1
