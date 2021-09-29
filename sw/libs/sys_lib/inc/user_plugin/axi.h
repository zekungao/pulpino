#ifndef _USER_PLUGIN_AXI_H_
#define _USER_PLUGIN_AXI_H_

#include <pulpino.h>

#define UP_AXI_REG_SRC_ADDR      ( USER_PLUGIN_AXI_BASE_ADDR + 0x00 )
#define UP_AXI_REG_DST_ADDR      ( USER_PLUGIN_AXI_BASE_ADDR + 0x04 )
#define UP_AXI_REG_SIZE          ( USER_PLUGIN_AXI_BASE_ADDR + 0x08 )
#define UP_AXI_REG_CTRL          ( USER_PLUGIN_AXI_BASE_ADDR + 0x0C )
#define UP_AXI_REG_CMD           ( USER_PLUGIN_AXI_BASE_ADDR + 0x10 )
#define UP_AXI_REG_STATUS        ( USER_PLUGIN_AXI_BASE_ADDR + 0x14 )

#define UP_AXI_SRC_ADDR          REG(UP_AXI_REG_SRC_ADDR)
#define UP_AXI_DST_ADDR          REG(UP_AXI_REG_DST_ADDR)
#define UP_AXI_SIZE              REG(UP_AXI_REG_SIZE)
#define UP_AXI_CTRL              REG(UP_AXI_REG_CTRL)
#define UP_AXI_CMD               REG(UP_AXI_REG_CMD)
#define UP_AXI_STATUS            REG(UP_AXI_REG_STATUS)

// Word size = (REG_SIZE / 4) + 1
// s: the actual byte size in an array
#define REG_SIZE_GET_BYTE_SIZE(s)     (((s) & ~0x3) - 4)

#define UP_AXI_CTRL_INT_EN_BIT   (1 << 0)

#define UP_AXI_CMD_CLR_INT_BIT   (1 << 0)
#define UP_AXI_CMD_TRIGGER_BIT   (1 << 1)

#define UP_AXI_STATUS_BUSY_BIT   (1 << 0)
#define UP_AXI_STATUS_INT_BIT    (1 << 1)

#endif
