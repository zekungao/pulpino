`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

// This axi master has no function.
// Use this in case an axi master should be connected,
// but no actual function required to save logic.
module axi_dummy_mstr
#(
    parameter AXI4_ADDRESS_WIDTH = 32,
    parameter AXI4_DATA_WIDTH    = 32,
    parameter AXI4_ID_WIDTH      = 16,
    parameter AXI4_USER_WIDTH    = 10,
    parameter AXI_STRB_WIDTH     = AXI4_DATA_WIDTH/8
)
(
    input logic     ACLK,
    input logic     ARESETn,

    //AXI write address bus ------------------------------------
    output logic [AXI4_ID_WIDTH-1:0]                AWID_o     ,
    output logic [AXI4_ADDRESS_WIDTH-1:0]           AWADDR_o   ,
    output logic [ 7:0]                             AWLEN_o    ,
    output logic [ 2:0]                             AWSIZE_o   ,
    output logic [ 1:0]                             AWBURST_o  ,
    output logic                                    AWLOCK_o   ,
    output logic [ 3:0]                             AWCACHE_o  ,
    output logic [ 2:0]                             AWPROT_o   ,
    output logic [ 3:0]                             AWREGION_o ,
    output logic [ AXI4_USER_WIDTH-1:0]             AWUSER_o   ,
    output logic [ 3:0]                             AWQOS_o    ,
    output logic                                    AWVALID_o  ,
    input  logic                                    AWREADY_i  ,
    // ---------------------------------------------------------

    //AXI write data bus ---------------------------------------
    output logic [AXI4_DATA_WIDTH-1:0]              WDATA_o    ,
    output logic [AXI_STRB_WIDTH-1:0]               WSTRB_o    ,
    output logic                                    WLAST_o    ,
    output logic [AXI4_USER_WIDTH-1:0]              WUSER_o    ,
    output logic                                    WVALID_o   ,
    input  logic                                    WREADY_i   ,
    // ---------------------------------------------------------

    //AXI write response bus -----------------------------------
    input  logic   [AXI4_ID_WIDTH-1:0]              BID_i      ,
    input  logic   [ 1:0]                           BRESP_i    ,
    input  logic                                    BVALID_i   ,
    input  logic   [AXI4_USER_WIDTH-1:0]            BUSER_i    ,
    output logic                                    BREADY_o   ,
    // ---------------------------------------------------------

    //AXI read address bus -------------------------------------
    output logic [AXI4_ID_WIDTH-1:0]                ARID_o     ,
    output logic [AXI4_ADDRESS_WIDTH-1:0]           ARADDR_o   ,
    output logic [ 7:0]                             ARLEN_o    ,
    output logic [ 2:0]                             ARSIZE_o   ,
    output logic [ 1:0]                             ARBURST_o  ,
    output logic                                    ARLOCK_o   ,
    output logic [ 3:0]                             ARCACHE_o  ,
    output logic [ 2:0]                             ARPROT_o   ,
    output logic [ 3:0]                             ARREGION_o ,
    output logic [ AXI4_USER_WIDTH-1:0]             ARUSER_o   ,
    output logic [ 3:0]                             ARQOS_o    ,
    output logic                                    ARVALID_o  ,
    input  logic                                    ARREADY_i  ,
    // ---------------------------------------------------------

    //AXI read data bus ----------------------------------------
    input  logic [AXI4_ID_WIDTH-1:0]                RID_i      ,
    input  logic [AXI4_DATA_WIDTH-1:0]              RDATA_i    ,
    input  logic [ 1:0]                             RRESP_i    ,
    input  logic                                    RLAST_i    ,
    input  logic [AXI4_USER_WIDTH-1:0]              RUSER_i    ,
    input  logic                                    RVALID_i   ,
    output logic                                    RREADY_o
    // ---------------------------------------------------------
);

    assign AWID_o     = 'b0;
    assign AWADDR_o   = 'b0;
    assign AWLEN_o    = 'b0;
    assign AWSIZE_o   = 'b0;
    assign AWBURST_o  = 'b0;
    assign AWLOCK_o   = 'b0;
    assign AWCACHE_o  = 'b0;
    assign AWPROT_o   = 'b0;
    assign AWREGION_o = 'b0;
    assign AWUSER_o   = 'b0;
    assign AWQOS_o    = 'b0;
    assign AWVALID_o  = 'b0;

    assign WDATA_o    = 'b0;
    assign WSTRB_o    = 'b0;
    assign WLAST_o    = 'b0;
    assign WUSER_o    = 'b0;
    assign WVALID_o   = 'b0;

    assign BREADY_o   = 'b0;

    assign ARID_o     = 'b0;
    assign ARADDR_o   = 'b0;
    assign ARLEN_o    = 'b0;
    assign ARSIZE_o   = 'b0;
    assign ARBURST_o  = 'b0;
    assign ARLOCK_o   = 'b0;
    assign ARCACHE_o  = 'b0;
    assign ARPROT_o   = 'b0;
    assign ARREGION_o = 'b0;
    assign ARUSER_o   = 'b0;
    assign ARQOS_o    = 'b0;
    assign ARVALID_o  = 'b0;

    assign RREADY_o   = 'b0;

endmodule
