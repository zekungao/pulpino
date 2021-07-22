module pulpino_pads
  (
    //////////
    // PADS //
    //////////

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
    inout  wire              spi_master_mosi_pad,

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
    inout  wire              tdo_pad,

    ///////////////////
    // TO TOP MODULE //
    ///////////////////
    // Clock and Reset
    output logic              clk /*verilator clocker*/,
    input  logic              clk_pad_IE_1,
    input  logic              clk_pad_I_0,
    output logic              rst_n,
    input  logic              rst_n_pad_OEN_1,
    input  logic              rst_n_pad_I_0,

    output logic              fetch_enable_i,
    input  logic              fetch_enable_pad_OEN_1,
    input  logic              fetch_enable_pad_I_0,

    //SPI Slave
    output logic              spi_clk_i /*verilator clocker*/,
    input  logic              spi_clk_pad_OEN_1,
    input  logic              spi_clk_pad_I_0,
    output logic              spi_cs_i /*verilator clocker*/,
    input  logic              spi_cs_pad_OEN_1,
    input  logic              spi_cs_pad_I_0,
    input  logic              spi_sdo0_o,
    input  logic              spi_miso_pad_OEN_0,
    output logic              spi_sdi0_i,
    input  logic              spi_mosi_pad_OEN_1,
    input  logic              spi_mosi_pad_I_0,

    //SPI Master
    input  logic              spi_master_clk_o,
    input  logic              spi_master_clk_pad_OEN_0,
    input  logic              spi_master_csn0_o,
    input  logic              spi_master_csn0_pad_OEN_0,
    input  logic              spi_master_csn1_o,
    input  logic              spi_master_csn1_pad_OEN_0,
    input  logic              spi_master_csn2_o,
    input  logic              spi_master_csn2_pad_OEN_0,
    input  logic              spi_master_csn3_o,
    input  logic              spi_master_csn3_pad_OEN_0,
    input  logic              spi_master_sdo0_o,
    input  logic              spi_master_mosi_pad_OEN_0,
    output logic              spi_master_sdi0_i,
    input  logic              spi_master_miso_pad_OEN_1,
    input  logic              spi_master_miso_pad_I_0,

    output logic              scl_pad_i,
    input  logic              scl_pad_o,
    input  logic              scl_pad_IE_1,
    input  logic              scl_padoen_o,
    output logic              sda_pad_i,
    input  logic              sda_pad_o,
    input  logic              sda_pad_IE_1,
    input  logic              sda_padoen_o,

    input  logic              uart_tx,
    input  logic              uart_tx_pad_OEN_0,
    output logic              uart_rx,
    input  logic              uart_rx_pad_OEN_1,
    input  logic              uart_rx_pad_I_0,

    output logic       [20:0] gpio_in,
    input  logic       [20:0] gpio_out,
    input  logic       [20:0] gpio_pad_IE_1,
    input  logic       [20:0] gpio_pad_OEN,

    output logic        [7:0] upio_in,
    input  logic        [7:0] upio_out,
    input  logic        [7:0] upio_pad_IE_1,
    input  logic        [7:0] upio_pad_OEN,

    // JTAG signals
    output logic              tck_i,
    input  logic              tck_pad_OEN_1,
    input  logic              tck_pad_I_0,
    output logic              trstn_i,
    input  logic              trstn_pad_OEN_1,
    input  logic              trstn_pad_I_0,
    output logic              tms_i,
    input  logic              tms_pad_OEN_1,
    input  logic              tms_pad_I_0,
    output logic              tdi_i,
    input  logic              tdi_pad_OEN_1,
    input  logic              tdi_pad_I_0,
    input  logic              tdo_o,
    input  logic              tdo_pad_OEN_0
  );

  pad_clk    clk_pad_i              (.PAD(clk_pad),              .IE(clk_pad_IE_1),               .OEN(clk_pad_IE_1),               .I(clk_pad_I_0),              .O(clk)  );
  pad_io_pd  rst_n_pad_i            (.PAD(rst_n_pad),            .IE(rst_n_pad_OEN_1),            .OEN(rst_n_pad_OEN_1),            .I(rst_n_pad_I_0),            .O(rst_n));

  pad_io_pd  fetch_enable_pad_i     (.PAD(fetch_enable_pad),     .IE(fetch_enable_pad_OEN_1),     .OEN(fetch_enable_pad_OEN_1),     .I(fetch_enable_pad_I_0),     .O(fetch_enable_i));

  // PULPino as slave
  pad_io_pd  spi_clk_pad_i          (.PAD(spi_clk_pad),          .IE(spi_clk_pad_OEN_1),          .OEN(spi_clk_pad_OEN_1),          .I(spi_clk_pad_I_0),          .O(spi_clk_i));
  pad_io_pd  spi_cs_pad_i           (.PAD(spi_cs_pad),           .IE(spi_cs_pad_OEN_1),           .OEN(spi_cs_pad_OEN_1),           .I(spi_cs_pad_I_0),           .O(spi_cs_i));
  // spi_mode_o is not used since only SPI is supported
  pad_io_pd  spi_miso_pad_i         (.PAD(spi_miso_pad),         .IE(spi_miso_pad_OEN_0),         .OEN(spi_miso_pad_OEN_0),         .I(spi_sdo0_o),               .O());
  pad_io_pd  spi_mosi_pad_i         (.PAD(spi_mosi_pad),         .IE(spi_mosi_pad_OEN_1),         .OEN(spi_mosi_pad_OEN_1),         .I(spi_mosi_pad_I_0),         .O(spi_sdi0_i));

  // PULPino as master
  pad_io_pd  spi_master_clk_pad_i   (.PAD(spi_master_clk_pad ),  .IE(spi_master_clk_pad_OEN_0 ),  .OEN(spi_master_clk_pad_OEN_0 ),  .I(spi_master_clk_o ),        .O());
  pad_io_pd  spi_master_csn0_pad_i  (.PAD(spi_master_csn0_pad),  .IE(spi_master_csn0_pad_OEN_0),  .OEN(spi_master_csn0_pad_OEN_0),  .I(spi_master_csn0_o),        .O());
  pad_io_pd  spi_master_csn1_pad_i  (.PAD(spi_master_csn1_pad),  .IE(spi_master_csn1_pad_OEN_0),  .OEN(spi_master_csn1_pad_OEN_0),  .I(spi_master_csn1_o),        .O());
  pad_io_pd  spi_master_csn2_pad_i  (.PAD(spi_master_csn2_pad),  .IE(spi_master_csn2_pad_OEN_0),  .OEN(spi_master_csn2_pad_OEN_0),  .I(spi_master_csn2_o),        .O());
  pad_io_pd  spi_master_csn3_pad_i  (.PAD(spi_master_csn3_pad),  .IE(spi_master_csn3_pad_OEN_0),  .OEN(spi_master_csn3_pad_OEN_0),  .I(spi_master_csn3_o),        .O());
  // spi_master_mode_o is not used since only SPI is supported
  pad_io_pd  spi_master_miso_pad_i  (.PAD(spi_master_miso_pad),  .IE(spi_master_miso_pad_OEN_1),  .OEN(spi_master_miso_pad_OEN_1),  .I(spi_master_miso_pad_I_0),  .O(spi_master_sdi0_i));
  pad_io_pd  spi_master_mosi_pad_i  (.PAD(spi_master_mosi_pad),  .IE(spi_master_mosi_pad_OEN_0),  .OEN(spi_master_mosi_pad_OEN_0),  .I(spi_master_sdo0_o),        .O());

  pad_io     scl_pad_pad_i          (.PAD(scl_pad),              .IE(scl_pad_IE_1),               .OEN(scl_padoen_o),               .I(scl_pad_o),                .O(scl_pad_i));
  pad_io     sda_pad_pad_i          (.PAD(sda_pad),              .IE(sda_pad_IE_1),               .OEN(sda_padoen_o),               .I(sda_pad_o),                .O(sda_pad_i));

  pad_io_pd  uart_tx_pad_i          (.PAD(uart_tx_pad),          .IE(uart_tx_pad_OEN_0),          .OEN(uart_tx_pad_OEN_0),          .I(uart_tx),                  .O());
  pad_io_pd  uart_rx_pad_i          (.PAD(uart_rx_pad),          .IE(uart_rx_pad_OEN_1),          .OEN(uart_rx_pad_OEN_1),          .I(uart_rx_pad_I_0),          .O(uart_rx));

  generate
    for (genvar i = 0; i < 21; i++) begin : GPIO_PAD_GEN
      pad_io_pd gpio_pad_i          (.PAD(gpio_pad[i]),          .IE(gpio_pad_IE_1[i]),     .OEN(gpio_pad_OEN[i]),   .I(gpio_out[i]),          .O(gpio_in[i]));
    end
  endgenerate

  generate
    for (genvar i = 0; i < $size(upio_pad); i++) begin : UPIO_PAD_GEN
      pad_io_pd upio_pad_i          (.PAD(upio_pad[i]),          .IE(upio_pad_IE_1[i]),     .OEN(upio_pad_OEN[i]),   .I(upio_out[i]),          .O(upio_in[i]));
    end
  endgenerate

  pad_io_pd tck_pad_i               (.PAD(tck_pad),              .IE(tck_pad_OEN_1),       .OEN(tck_pad_OEN_1),           .I(tck_pad_I_0),                 .O(tck_i));
  pad_io_pd trstn_pad_i             (.PAD(trstn_pad),            .IE(trstn_pad_OEN_1),     .OEN(trstn_pad_OEN_1),         .I(trstn_pad_I_0),               .O(trstn_i));
  pad_io_pd tms_pad_i               (.PAD(tms_pad),              .IE(tms_pad_OEN_1),       .OEN(tms_pad_OEN_1),           .I(tms_pad_I_0),                 .O(tms_i));
  pad_io_pd tdi_pad_i               (.PAD(tdi_pad),              .IE(tdi_pad_OEN_1),       .OEN(tdi_pad_OEN_1),           .I(tdi_pad_I_0),                 .O(tdi_i));
  pad_io_pd tdo_pad_i               (.PAD(tdo_pad),              .IE(tdo_pad_OEN_0),       .OEN(tdo_pad_OEN_0),           .I(tdo_o),                       .O());

endmodule
