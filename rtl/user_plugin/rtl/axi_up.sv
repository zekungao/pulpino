`define REG_SIZE_WIDTH 15  // At most 32KB

module axi_up
(
    input logic     ACLK,
    input logic     ARESETn,

    AXI_BUS.Slave   slv,
    AXI_BUS.Master  mstr,

    output  logic   int_o
);

    logic [mstr.AXI_ADDR_WIDTH - 1: 0] s_src_addr;
    logic [mstr.AXI_ADDR_WIDTH - 1: 0] s_dst_addr;
    logic [`REG_SIZE_WIDTH - 1: 0]     s_size;
    logic                              s_ctrl_int_en;
    logic                              s_cmd_clr_int_pulse;
    logic                              s_cmd_trigger_pulse;
    logic                              s_status_busy;
    logic                              s_status_int_pending;

    axi_up_if
    #(
        .REG_SIZE_WIDTH( `REG_SIZE_WIDTH )
    )
    if_i
    (
        .ACLK                 ( ACLK                 ),
        .ARESETn              ( ARESETn              ),

        .slv                  ( slv                  ),

        .src_addr_o           ( s_src_addr           ),
        .dst_addr_o           ( s_dst_addr           ),
        .size_o               ( s_size               ),
        .ctrl_int_en_o        ( s_ctrl_int_en        ),
        .cmd_clr_int_pulse_o  ( s_cmd_clr_int_pulse  ),
        .cmd_trigger_pulse_o  ( s_cmd_trigger_pulse  ),

        .status_busy_i        ( s_status_busy        ),
        .status_int_pending_i ( s_status_int_pending )
    );

    axi_up_ctrl
    #(
        .REG_SIZE_WIDTH ( `REG_SIZE_WIDTH )
    )
    ctrl_i
    (
        .ACLK                 ( ACLK                 ),
        .ARESETn              ( ARESETn              ),
        .mstr                 ( mstr                 ),

        .src_addr_i           ( s_src_addr           ),
        .dst_addr_i           ( s_dst_addr           ),
        .size_i               ( s_size               ),
        .ctrl_int_en_i        ( s_ctrl_int_en        ),
        .cmd_clr_int_pulse_i  ( s_cmd_clr_int_pulse  ),
        .cmd_trigger_pulse_i  ( s_cmd_trigger_pulse  ),

        .status_busy_o        ( s_status_busy        ),
        .status_int_pending_o ( s_status_int_pending ),
        .int_o                ( int_o                )
    );

endmodule
