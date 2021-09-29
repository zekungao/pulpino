module chip_top_wrapper
  #(
    parameter DUT_IMPL             = "NORMAL",
    parameter USE_ZERO_RISCY       = 1,
    parameter RISCY_RV32F          = 0,
    parameter ZERO_RV32M           = 1,
    parameter ZERO_RV32E           = 0
  )
  (
    // Clock and Reset
    inout  wire              clk_pad,
    inout  wire              rst_n_pad,

    inout  wire              fetch_enable_pad,

    //SPI Slave
    inout  wire              spi_clk_pad,
    inout  wire              spi_cs_pad,
    inout  wire              spi_miso_pad,
    inout  wire              spi_mosi_pad,

    //SPI Master
    inout  wire              spi_master_clk_pad,
    inout  wire              spi_master_csn0_pad,
    inout  wire              spi_master_csn1_pad,
    inout  wire              spi_master_csn2_pad,
    inout  wire              spi_master_csn3_pad,
    inout  wire              spi_master_miso_pad,
    input  wire              spi_master_mosi_pad,

    inout  wire              scl_pad,
    inout  wire              sda_pad,

    inout  wire              uart_tx_pad,
    inout  wire              uart_rx_pad,

    inout  wire       [20:0] gpio_pad,
    inout  wire        [7:0] upio_pad,

    // JTAG signals
    inout  wire              tck_pad,
    inout  wire              trstn_pad,
    inout  wire              tms_pad,
    inout  wire              tdi_pad,
    inout  wire              tdo_pad
  );
  generate
    // To overcome same module issue, one have to:
    // 1. Init instance with `uselib (see below)
    // 2. Call vsim with `-L work` before other `-L ...`
    //    ModelSim User's Manual
    //
    //    When you specify -L work first in the search library arguments 
    //    you are directing vsim to search for the instantiated module or UDP in the library 
    //    that contains the module that does the instantiation.
    //
    //    -L work is required to let pulpino chip use cells with/without timing compile to its own library.

    if (DUT_IMPL == "NORMAL") begin: C
      `uselib lib=pulpino_lib
      pulpino_top_with_pads #(
        .USE_ZERO_RISCY(USE_ZERO_RISCY),
        .RISCY_RV32F(RISCY_RV32F),
        .ZERO_RV32M(ZERO_RV32M),
        .ZERO_RV32E(ZERO_RV32E)
      ) i(
        .*
        );
    end
    else if (DUT_IMPL == "SV2V") begin: C
      // All parameters have been expanded, and no parameter exists in sv2v version.
      `uselib lib=pulpino_sv2v_lib
      pulpino_top_with_pads
      i(
        .*
        );
    end 
    else if (DUT_IMPL == "PL") begin: C
      // All parameters have been expanded, and no parameter exists in postlayout version.
      `uselib lib=pulpino_pl_lib
      pulpino_top_with_pads
      i(
        .*
        );
    end
    else if (DUT_IMPL == "PL_W_TIMING") begin: C
      // All parameters have been expanded, and no parameter exists in postlayout version.
      `uselib lib=pulpino_pl_w_timing_lib
      pulpino_top_with_pads
      i(
        .*
        );
    end else begin
      initial begin
        $display("Unsupported DUT_IMPL value: %s", DUT_IMPL);
        $fflush();
        $stop();
      end
    end
  endgenerate
endmodule
