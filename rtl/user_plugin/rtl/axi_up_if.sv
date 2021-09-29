`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

`define WORD_ADDR_WIDTH 4

`define REG_SRC_ADDR   4'h0  // BASEADDR + 0x00
`define REG_DST_ADDR   4'h1  // BASEADDR + 0x04
`define REG_SIZE       4'h2  // BASEADDR + 0x08
`define REG_CTRL       4'h3  // BASEADDR + 0x0C
`define REG_CMD        4'h4  // BASEADDR + 0x10
`define REG_STATUS     4'h5  // BASEADDR + 0x14

`define CTRL_INT_EN_BIT 'd0

`define REG_CMD_WIDTH   2
`define CMD_CLR_INT_BIT 'd0
`define CMD_TRIGGER_BIT 'd1

`define STATUS_BUSY_BIT        'd0
`define STATUS_INT_PENDING_BIT 'd1


module axi_up_if
#(
    parameter REG_SIZE_WIDTH = 16
)
(
    input logic                           ACLK,
    input logic                           ARESETn,

    AXI_BUS.Slave                         slv,

    //user defined signals -------------------------------
    output logic [slv.AXI_DATA_WIDTH - 1:0]  src_addr_o   ,        // source address register
    output logic [slv.AXI_DATA_WIDTH - 1:0]  dst_addr_o   ,        // destination address register
    output logic [REG_SIZE_WIDTH - 1:0]      size_o       ,        // process byte number
    output logic                             ctrl_int_en_o,        // interrupt enable output
    output logic                             cmd_clr_int_pulse_o,  // clear int signal (pulse)
    output logic                             cmd_trigger_pulse_o,  // trigger signal (pulse)

    input  logic                             status_busy_i,        // status busy
    input  logic                             status_int_pending_i  // status int pending
);

    logic                           s_write;
    logic [`WORD_ADDR_WIDTH - 1:0]  s_w_word_addr;
    logic [slv.AXI_DATA_WIDTH-1:0]  s_wdata;
    logic [slv.AXI_STRB_WIDTH-1:0]  s_wstrb;

    logic [`WORD_ADDR_WIDTH - 1:0]  s_r_word_addr;
    logic [slv.AXI_DATA_WIDTH-1:0]  s_rdata;

    axi_reg_word_rd
    #(
        .AXI4_ADDR_WIDTH ( slv.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( slv.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( slv.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( slv.AXI_USER_WIDTH ),

        .WORD_ADDR_WIDTH ( `WORD_ADDR_WIDTH   )
    )
    reg_word_rd_i
    (
        .ACLK       ( ACLK          ),
        .ARESETn    ( ARESETn       ),

        .ARID_i     ( slv.ar_id     ),
        .ARADDR_i   ( slv.ar_addr   ),
        .ARLEN_i    ( slv.ar_len    ),
        .ARSIZE_i   ( slv.ar_size   ),
        .ARBURST_i  ( slv.ar_burst  ),
        .ARLOCK_i   ( slv.ar_lock   ),
        .ARCACHE_i  ( slv.ar_cache  ),
        .ARPROT_i   ( slv.ar_prot   ),
        .ARREGION_i ( slv.ar_region ),
        .ARUSER_i   ( slv.ar_user   ),
        .ARQOS_i    ( slv.ar_qos    ),
        .ARVALID_i  ( slv.ar_valid  ),
        .ARREADY_o  ( slv.ar_ready  ),
                                   
        .RID_o      ( slv.r_id      ),
        .RDATA_o    ( slv.r_data    ),
        .RRESP_o    ( slv.r_resp    ),
        .RLAST_o    ( slv.r_last    ),
        .RUSER_o    ( slv.r_user    ),
        .RVALID_o   ( slv.r_valid   ),
        .RREADY_i   ( slv.r_ready   ),

        .avalid_o    (),
        .word_addr_o ( s_r_word_addr ),
        .data_i      ( s_rdata       )
    );

    axi_reg_word_wt
    #(
        .AXI4_ADDR_WIDTH ( slv.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( slv.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( slv.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( slv.AXI_USER_WIDTH ),

        .WORD_ADDR_WIDTH ( `WORD_ADDR_WIDTH   )
    )
    reg_word_wt_i
    (
        .ACLK       ( ACLK          ),
        .ARESETn    ( ARESETn       ),

        .AWID_i     ( slv.aw_id     ),
        .AWADDR_i   ( slv.aw_addr   ),
        .AWLEN_i    ( slv.aw_len    ),
        .AWSIZE_i   ( slv.aw_size   ),
        .AWBURST_i  ( slv.aw_burst  ),
        .AWLOCK_i   ( slv.aw_lock   ),
        .AWCACHE_i  ( slv.aw_cache  ),
        .AWPROT_i   ( slv.aw_prot   ),
        .AWREGION_i ( slv.aw_region ),
        .AWUSER_i   ( slv.aw_user   ),
        .AWQOS_i    ( slv.aw_qos    ),
        .AWVALID_i  ( slv.aw_valid  ),
        .AWREADY_o  ( slv.aw_ready  ),
                                   
        .WDATA_i    ( slv.w_data    ),
        .WSTRB_i    ( slv.w_strb    ),
        .WLAST_i    ( slv.w_last    ),
        .WUSER_i    ( slv.w_user    ),
        .WVALID_i   ( slv.w_valid   ),
        .WREADY_o   ( slv.w_ready   ),
                                   
        .BID_o      ( slv.b_id      ),
        .BRESP_o    ( slv.b_resp    ),
        .BVALID_o   ( slv.b_valid   ),
        .BUSER_o    ( slv.b_user    ),
        .BREADY_i   ( slv.b_ready   ),

        .valid_o     ( s_write       ),
        .word_addr_o ( s_w_word_addr ),
        .data_o      ( s_wdata       ),
        .strb_o      ( s_wstrb       )
    );


    ////////////////
    // User Logic //
    ////////////////

    //
    // User reg write
    //
    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            src_addr_o    <= 'b0;
            dst_addr_o    <= 'b0;
            size_o        <= 'b0;
            ctrl_int_en_o <= 'b0;
        end
        else if (s_write)
             begin
                 case (s_w_word_addr)
                     `REG_SRC_ADDR:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 src_addr_o[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_DST_ADDR:
                         for (int i = 0; i < slv.AXI_STRB_WIDTH; i++)
                             if (s_wstrb[i])
                                 dst_addr_o[(i * 8) +: 8] <= s_wdata[(i * 8) +: 8];
                     `REG_SIZE:
                         for (int i = 0; i < $size(size_o); i++)
                             if (s_wstrb[i / 8])
                                 size_o[i] <= s_wdata[i];
                     `REG_CTRL:
                         if (s_wstrb[`CTRL_INT_EN_BIT / 8])
                             ctrl_int_en_o <= s_wdata[`CTRL_INT_EN_BIT];
                 endcase
             end
    end

    // cmd logic
    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            cmd_clr_int_pulse_o <= 'b0;
            cmd_trigger_pulse_o <= 'b0;
        end
        else if (s_write)
             begin
                 case (s_w_word_addr)
                     `REG_CMD:
                     begin
                         if (s_wstrb[`CMD_CLR_INT_BIT / 8] && s_wdata[`CMD_CLR_INT_BIT] && ~cmd_clr_int_pulse_o)
                            cmd_clr_int_pulse_o <= 1'b1;
                         else
                            cmd_clr_int_pulse_o <= 1'b0;

                         if (s_wstrb[`CMD_TRIGGER_BIT / 8] && s_wdata[`CMD_TRIGGER_BIT] && ~cmd_trigger_pulse_o)
                            cmd_trigger_pulse_o <= 1'b1;
                         else
                            cmd_trigger_pulse_o <= 1'b0;
                     end
                 endcase
             end
             else
             begin
                 cmd_clr_int_pulse_o <= 'b0;
                 cmd_trigger_pulse_o <= 'b0;
             end
    end

    //
    // User reg read
    //
    // Reg Ctrl
    logic [slv.AXI_DATA_WIDTH - 1: 0] s_ctrl;

    always_comb
    begin
        s_ctrl = 'h0;
        s_ctrl[`CTRL_INT_EN_BIT] = ctrl_int_en_o;
    end

    // Reg Status
    logic [slv.AXI_DATA_WIDTH - 1: 0] s_status;

    always_comb
    begin
        s_status = 'h0;
        s_status[`STATUS_BUSY_BIT] = status_busy_i;
        s_status[`STATUS_INT_PENDING_BIT] = status_int_pending_i;
    end

    always_comb
    begin
        case (s_r_word_addr)
            `REG_SRC_ADDR:
                s_rdata = src_addr_o;
            `REG_DST_ADDR:
                s_rdata = dst_addr_o;
            `REG_SIZE:
                // SystemVerilog will resize to the correct size
                s_rdata = {'h0, size_o};
            `REG_CTRL:
                s_rdata = s_ctrl;
            `REG_STATUS:
                s_rdata = s_status;
            default:
                s_rdata = 'h0;
        endcase
    end

endmodule
