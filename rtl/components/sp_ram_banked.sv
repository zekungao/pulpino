// Copyright 2021 IC Bench,Inc.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Behavior of this module is the same as the behavior of functional/sp_ram.sv.
//
// This module is used as a general single-port RAM implementation with banks,
// and intended to be used by ${process}/sp_ram.sv.
//
// Thus for a specific process, only sp_ram_YYYYxWW need to be implemented.
module sp_ram_banked
  #(
    parameter RAM_BYTE_SIZE  = 32768,
    parameter ADDR_WIDTH     = $clog2(RAM_BYTE_SIZE),
    parameter DATA_WIDTH     = 32,
    parameter BANK_WORD_SIZE = 4096
  )(
    // Clock and Reset
    input  logic                    clk,
    input  logic                    en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata_o,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i
  );

   localparam BANK_BYTE_SIZE = BANK_WORD_SIZE * (DATA_WIDTH / 8);
   localparam BANK_NUM       = RAM_BYTE_SIZE / BANK_BYTE_SIZE;
   localparam BANK_SEL_WIDTH = $clog2(BANK_NUM);

   logic [DATA_WIDTH - 1:0] ram_out_int;
   logic [DATA_WIDTH - 1:0] bank_out [BANK_NUM - 1:0];
   logic [BANK_SEL_WIDTH - 1:0] bank_sel;
   logic [BANK_SEL_WIDTH - 1:0] bank_sel_d;

   logic [DATA_WIDTH - 1:0] bit_mask;

   assign bank_sel = addr_i[ADDR_WIDTH-1 -: BANK_SEL_WIDTH];
   always_ff @(posedge clk) begin
     if (en_i) begin
       bank_sel_d <= bank_sel;
     end
   end

   assign rdata_o = bank_out[bank_sel_d];

   generate
     for (genvar i = 0; i < DATA_WIDTH; i++) begin : BIT_MASK_GEN
       assign bit_mask[i] = be_i[i / 8];
     end
   endgenerate

   generate
     for (genvar i = 0; i < BANK_NUM; i++) begin : BANK
       if (BANK_WORD_SIZE == 4096 && DATA_WIDTH == 32) begin : SPRAM
         // Single-PORT SRAM
         // word depth: 4096
         // word bits:  32
         // bit-write:  on
         //
         // CLK:        clock input
         // CEN:        chip enable input (active low)
         // A[11:0]:    address inputs
         // D[31:0]:    data inputs
         // Q[31:0]:    data outputs
         // WEN:        write enable input (active low)
         // BWEN[31:0]: bit-write enable input (active low)
         sp_ram_4096x32 bank_i(
           .CLK  ( clk                       ),
           .CEN  ( ~(en_i & (bank_sel == i)) ),
           .A    ( addr_i[ADDR_WIDTH - 1 - BANK_SEL_WIDTH : $clog2(DATA_WIDTH/8)] ),
           .D    ( wdata_i                   ),
           .Q    ( bank_out[i]               ),
           .WEN  ( ~we_i                     ),
           .BWEN ( ~bit_mask                 )
         );
       end
       else begin
         initial begin
           $error("Unsupported SRAM configuration");
           $fflush;
           $stop;
         end
       end
     end
   endgenerate

   // synthesis translate_off

   task write_word(
     input integer byte_addr,
     input logic [DATA_WIDTH-1:0] word);

     $error("Word writing not supported");
     $fflush;
     $stop;

   endtask

   // synthesis translate_on

endmodule
