module flash_wrapper
  #(
    parameter WITH_TIMING
   )
   (
     input CSn,
     input CLK,
     inout DIO,
     inout WPn,
     inout HOLDn,
     inout DO
   );
   generate
     if (WITH_TIMING === 0) begin: C
       `uselib lib=vip_lib
       W25Q16JV i(.*);
     end else begin: C
       `uselib lib=vip_timing_lib
       W25Q16JV i(.*);
     end
   endgenerate
endmodule
