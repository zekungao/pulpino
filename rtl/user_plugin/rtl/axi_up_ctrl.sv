
module axi_up_ctrl
#(
    parameter REG_SIZE_WIDTH = 16
)
(
    input logic     ACLK,
    input logic     ARESETn,

    AXI_BUS.Master  mstr,

    // User signals
    input  logic [mstr.AXI_ADDR_WIDTH-1:0]  src_addr_i,
    input  logic [mstr.AXI_ADDR_WIDTH-1:0]  dst_addr_i,
    input  logic [REG_SIZE_WIDTH-1:0]       size_i,
    input  logic                            ctrl_int_en_i,
    input  logic                            cmd_clr_int_pulse_i,
    input  logic                            cmd_trigger_pulse_i,

    output logic                            status_busy_o,
    output logic                            status_int_pending_o,
    output logic                            int_o
);

    /////////////////////////////////////////
    // Data Reading / Processing / Writing //
    /////////////////////////////////////////

    logic [mstr.AXI_ADDR_WIDTH - 2 - 1: 0] r_r_word_addr;  // Read address by word
    logic [mstr.AXI_ADDR_WIDTH - 2 - 1: 0] r_w_word_addr;  // Write address by word
    logic [REG_SIZE_WIDTH - 2 - 1: 0]      r_word_size;    // Remaining number of words

    logic                              s_r_req;  // Read memory request
    logic [mstr.AXI_DATA_WIDTH - 1: 0] s_r_data;
    logic                              s_r_gnt;  // Read memory grant

    logic                              s_w_req;  // Write memory request
    logic [mstr.AXI_DATA_WIDTH - 1: 0] s_w_data;
    logic                              s_w_data_store;
    logic [mstr.AXI_DATA_WIDTH - 1: 0] r_w_data;
    logic                              s_w_gnt;  // Write memory grant

    logic                              s_load;
    logic                              s_nxt_word;

    // A very simple process
    assign s_w_data = {s_r_data[$size(s_r_data) - 2: 0], 1'b0};

    always_ff @(posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_w_data <= 'b0;
        else if (s_w_data_store)
            r_w_data <= s_w_data;
    end

    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
        begin
            r_r_word_addr <= 'b0;
            r_w_word_addr <= 'b0;
            r_word_size   <= 'b0;
        end
        else
        begin
            unique case (1'b1)
                s_load:
                begin
                    r_r_word_addr <= src_addr_i[mstr.AXI_ADDR_WIDTH-1:2];
                    r_w_word_addr <= dst_addr_i[mstr.AXI_ADDR_WIDTH-1:2];
                    r_word_size   <= size_i[REG_SIZE_WIDTH-1:2];
                end
                s_nxt_word:
                begin
                    r_r_word_addr <= r_r_word_addr + 1'b1;
                    r_w_word_addr <= r_w_word_addr + 1'b1;
                    r_word_size   <= r_word_size   - 1'b1;
                end
                default:
                begin
                  // use default to avoid unique warning
                end
            endcase
        end
    end

    enum logic [2:0] {  IDLE,
                        INIT_READ,
                        WAIT_READ,
                        INIT_WRITE,
                        WAIT_WRITE
                     } r_CS, s_CS_n;

    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_CS <= IDLE;
        else
            r_CS <= s_CS_n;
    end

    always_comb
    begin
        s_r_req    = 1'b0;
        s_w_req    = 1'b0;

        s_load     = 1'b0;
        s_nxt_word = 1'b0;

        s_w_data_store = 1'b0;

        status_busy_o  = 1'b1;

        case (r_CS)
            IDLE:
            begin
                status_busy_o = 1'b0;

                if (~cmd_trigger_pulse_i)
                    s_CS_n = IDLE;
                else
                begin
                    s_load = 1'b1;
                    s_CS_n = INIT_READ;
                end
            end

            INIT_READ:
            begin
                s_r_req = 1'b1;
                s_CS_n  = WAIT_READ;
            end

            WAIT_READ:
            begin
                s_r_req = 1'b1;

                if (~s_r_gnt)
                    s_CS_n = WAIT_READ;
                else
                begin
                    s_w_data_store = 1'b1;

                    s_CS_n = INIT_WRITE;
                end
            end

            INIT_WRITE:
            begin
                s_w_req = 1'b1;
                s_CS_n  = WAIT_WRITE;
            end

            WAIT_WRITE:
            begin
                s_w_req = 1'b1;
                if (~s_w_gnt)
                    s_CS_n = WAIT_WRITE;
                else
                begin
                    if (r_word_size == 'b0)
                        s_CS_n = IDLE;
                    else
                    begin
                        s_nxt_word = 1'b1;
                        s_CS_n     = INIT_READ;
                    end
                end
            end

            default:
            begin
                s_CS_n = IDLE;
            end
        endcase
    end

    axi_mem_word_rd
    #(
        .AXI4_ADDR_WIDTH ( mstr.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( mstr.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( mstr.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( mstr.AXI_USER_WIDTH )
    )
    mem_rd_i
    (
        .ACLK       ( ACLK           ),
        .ARESETn    ( ARESETn        ),

        .ARID_o     ( mstr.ar_id     ),
        .ARADDR_o   ( mstr.ar_addr   ),
        .ARLEN_o    ( mstr.ar_len    ),
        .ARSIZE_o   ( mstr.ar_size   ),
        .ARBURST_o  ( mstr.ar_burst  ),
        .ARLOCK_o   ( mstr.ar_lock   ),
        .ARCACHE_o  ( mstr.ar_cache  ),
        .ARPROT_o   ( mstr.ar_prot   ),
        .ARREGION_o ( mstr.ar_region ),
        .ARUSER_o   ( mstr.ar_user   ),
        .ARQOS_o    ( mstr.ar_qos    ),
        .ARVALID_o  ( mstr.ar_valid  ),
        .ARREADY_i  ( mstr.ar_ready  ),

        .RID_i      ( mstr.r_id      ),
        .RDATA_i    ( mstr.r_data    ),
        .RRESP_i    ( mstr.r_resp    ),
        .RLAST_i    ( mstr.r_last    ),
        .RUSER_i    ( mstr.r_user    ),
        .RVALID_i   ( mstr.r_valid   ),
        .RREADY_o   ( mstr.r_ready   ),

        .rd_req_i       ( s_r_req       ),
        .rd_word_addr_i ( r_r_word_addr ),
        .rd_data_o      ( s_r_data      ),
        .rd_gnt_o       ( s_r_gnt       )
    );

    axi_mem_word_wt
    #(
        .AXI4_ADDR_WIDTH ( mstr.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( mstr.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( mstr.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( mstr.AXI_USER_WIDTH )
    )
    mem_wt_i
    (
        .ACLK       ( ACLK           ),
        .ARESETn    ( ARESETn        ),

        .AWID_o     ( mstr.aw_id     ),
        .AWADDR_o   ( mstr.aw_addr   ),
        .AWLEN_o    ( mstr.aw_len    ),
        .AWSIZE_o   ( mstr.aw_size   ),
        .AWBURST_o  ( mstr.aw_burst  ),
        .AWLOCK_o   ( mstr.aw_lock   ),
        .AWCACHE_o  ( mstr.aw_cache  ),
        .AWPROT_o   ( mstr.aw_prot   ),
        .AWREGION_o ( mstr.aw_region ),
        .AWUSER_o   ( mstr.aw_user   ),
        .AWQOS_o    ( mstr.aw_qos    ),
        .AWVALID_o  ( mstr.aw_valid  ),
        .AWREADY_i  ( mstr.aw_ready  ),

        .WDATA_o    ( mstr.w_data    ),
        .WSTRB_o    ( mstr.w_strb    ),
        .WLAST_o    ( mstr.w_last    ),
        .WUSER_o    ( mstr.w_user    ),
        .WVALID_o   ( mstr.w_valid   ),
        .WREADY_i   ( mstr.w_ready   ),

        .BID_i      ( mstr.b_id      ),
        .BRESP_i    ( mstr.b_resp    ),
        .BVALID_i   ( mstr.b_valid   ),
        .BUSER_i    ( mstr.b_user    ),
        .BREADY_o   ( mstr.b_ready   ),

        .wt_req_i       ( s_w_req       ),
        .wt_word_addr_i ( r_w_word_addr ),
        .wt_data_i      ( r_w_data      ),
        .wt_gnt_o       ( s_w_gnt       )
    );

    ///////////////
    // Interrupt //
    ///////////////
    logic r_last_status_busy;

    always_ff @(posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_last_status_busy <= 1'b0;
        else
            r_last_status_busy <= status_busy_o;
    end


    always_ff @(posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            status_int_pending_o <= 1'b0;
        else if (cmd_clr_int_pulse_i)
            status_int_pending_o <= 1'b0;
        else if (~status_int_pending_o)
            status_int_pending_o <= r_last_status_busy & ~status_busy_o;
    end

    assign int_o = ctrl_int_en_i & status_int_pending_o;

endmodule
