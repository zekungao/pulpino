`define APB_REG_A      4'b0000 // BASEADDR + 0x00
`define APB_REG_B      4'b0001 // BASEADDR + 0x04
`define APB_REG_S      4'b0010 // BASEADDR + 0x08
`define APB_REG_CTRL   4'b0011 // BASEADDR + 0x0C
`define APB_REG_CMD    4'b0100 // BASEADDR + 0x10

`define APB_REG_STATUS 4'b0101 // BASEADDR + 0x14

`define APB_REG_PADDIR 4'b1000 // BASEADDR + 0x20
`define APB_REG_PADIN  4'b1001 // BASEADDR + 0x24
`define APB_REG_PADOUT 4'b1010 // BASEADDR + 0x28

`define CTRL_INT_EN_BIT  'd0

`define CMD_CLR_INT_BIT  'd0
`define CMD_SET_INT_BIT  'd1


module apb_up
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    input  logic                [7:0] upio_in_i,
    output logic                [7:0] upio_out_o,
    output logic                [7:0] upio_dir_o,

    output logic                      int_o
);  
    ///////////////
    // APB Logic //
    ///////////////

    // One cycle read/write, no wait states
    assign PREADY      = 1'b1;
    // No slave error
    assign PSLVERR     = 1'b0;

    logic [3:0] s_apb_addr;
    logic       s_apb_write;

    assign s_apb_addr  = PADDR[5:2];
    assign s_apb_write = PSEL & PENABLE & PWRITE;


    ////////////////
    // User Logic //
    ////////////////

    // registers
    logic [7:0] r_a;       // A register
    logic [7:0] r_b;       // B register
    logic [7:0] s_s;       // S register

    logic [7:0] r_ctrl;    // ctrl register
    logic [7:0] s_status;  // status register

    logic s_int_en;   // Interrupt enable
    logic r_int_flag; // Interrupt pending flag

    assign s_s = r_a | r_b;

    assign s_status = {6'b0, r_int_flag}; 
    assign s_int_en = r_ctrl[`CTRL_INT_EN_BIT];

    assign int_o    = s_int_en & r_int_flag;

    //
    // UPIO registers
    //
    // A value of 1 means it is configured as an output,
    // while 0 configures it as an input.
    logic [7:0] r_upio_paddir;
    logic [7:0] r_upio_padout;

    assign upio_dir_o = r_upio_paddir;
    assign upio_out_o = r_upio_padout;

    //
    // Registers write
    //
    always_ff @ (posedge HCLK, negedge HRESETn)
    begin
        if (~HRESETn)
        begin
            r_a        <= 'h0;
            r_b        <= 'h0;
            r_ctrl     <= 'h0;
            r_int_flag <= 'h0;

            r_upio_paddir <= 'h0;
            r_upio_padout <= 'h0;
        end
        else if (s_apb_write)
             begin
                 case (s_apb_addr)
                     `APB_REG_A:
                         r_a <= PWDATA[7:0];
                     `APB_REG_B:
                         r_b <= PWDATA[7:0];
                     `APB_REG_CTRL:
                         r_ctrl <= PWDATA[7:0];
                     `APB_REG_CMD:
                         if (PWDATA[`CMD_CLR_INT_BIT])
                             r_int_flag <= 1'b0;
                         else if (PWDATA[`CMD_SET_INT_BIT])
                             r_int_flag <= 1'b1;
                     `APB_REG_PADDIR:
                         r_upio_paddir <= PWDATA[7:0];
                     `APB_REG_PADOUT:
                         r_upio_padout <= PWDATA[7:0];
                 endcase
             end
    end // always

    //
    // Registers read
    //
    always_comb
    begin
        case (s_apb_addr)
            `APB_REG_A:
                PRDATA = {'h0, r_a};
            `APB_REG_B:
                PRDATA = {'h0, r_b};
            `APB_REG_S:
                PRDATA = {'h0, s_s};
            `APB_REG_CTRL:
                PRDATA = {'h0, r_ctrl};
            `APB_REG_STATUS:
                PRDATA = {'h0, s_status};
            `APB_REG_PADDIR:
                PRDATA = {'h0, r_upio_paddir};
            `APB_REG_PADIN:
                PRDATA = {'h0, upio_in_i};
            `APB_REG_PADOUT:
                PRDATA = {'h0, r_upio_padout};
            default:
                PRDATA = 'h0;
        endcase
    end
 
endmodule
