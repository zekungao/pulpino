#!/bin/tcsh

# This file is sourced by scripts
# pulpino/vsim/vcompile/vip/vcompile_vip*.sh
# And all vars in vcompile_vip*.sh can be used.

set THIS_DIR="`dirname "$SOURCED"`"

# 3rd party behavior modules
# Disable `specify block`
set FLASH_FILE="${THIS_DIR}/spi_flash/w25q16jv/w25q16jv.v"
if ( -f "${FLASH_FILE}" ) then
    vlog +nospecify -quiet -sv -work ${LIB_NAME} "$FLASH_FILE" || goto error
else
    echo "Warning: ${FLASH_FILE} does not exist, and is ignored"
endif
