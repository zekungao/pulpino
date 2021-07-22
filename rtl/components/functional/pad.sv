// Copyright 2021 IC Bench,Inc.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module pad_io_pd
(
  inout  logic PAD,
  input  logic IE,
  input  logic OEN,
  input  logic I,
  output logic O
);

/*  
  x: any value

     Input           | Output
  IE  OEN  I      PAD    | PAD  O
   1   1   x       0        -   0
   1   1   x       1        -   1
   1   1   x   pull down    -   0
   1   0   0       -        0   0
   1   0   1       -        1   1
 */ 
  
  supply0 zero;
  bufif0 (PAD, I, OEN);
  bufif1 (O, PAD, IE);
  rpmos  (PAD, zero, zero);

endmodule


module pad_io
(
  inout  logic PAD,
  input  logic IE,
  input  logic OEN,
  input  logic I,
  output logic O
);

/*  
  x: any value

     Input           | Output
  IE  OEN  I      PAD    | PAD  O
   1   1   x       0        -   0
   1   1   x       1        -   1
   1   1   x       z        -   x
   1   0   0       -        0   0
   1   0   1       -        1   1
 */ 
  
  bufif0 (PAD, I, OEN);
  bufif1 (O, PAD, IE);

endmodule


// Due to pad ring creation limitation,
// add more signals to be compatible with more processes.
module pad_clk
(
  input  logic PAD,
  input  logic IE,
  input  logic OEN,
  input  logic I,
  output logic O
);
/*  
  x: any value

     Input           | Output
  IE  OEN  I      PAD    | PAD  O
   1   1   x       0        -   0
   1   1   x       1        -   1
   1   1   x       z        -   x
   1   0   0       -        0   0
   1   0   1       -        1   1
 */ 
  bufif0 (PAD, I, OEN);
  bufif1 (O, PAD, IE);

endmodule
