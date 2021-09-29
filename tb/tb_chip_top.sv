// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "config.sv"
`include "tb_jtag_pkg.sv"
`include "exit_status.sv"



module tb_chip_top(input wire s_clk, ExitStatus exit_status_if);
  timeunit      1ns;
  timeprecision 1ps;

  // the following parameters can activate instantiation of the verification IPs
  // see the instructions in vip/spi_flash to download the verification IPs
  parameter  USE_W25Q16JV_MODEL = 0;

  // +MEMLOAD= valid values are "SPI", "STANDALONE" "PRELOAD", "" (no load of L2)
  // parameter  SPI            = "QUAD";    // valid values are "SINGLE", "QUAD"
  parameter  SPI            = "SINGLE";    // valid values are "SINGLE", "QUAD"
  parameter  BAUDRATE       = 781250;    // 1562500
  parameter  TEST           = ""; //valid values are "" (NONE), "DEBUG"

  parameter  DUT_IMPL       = "NORMAL";	// valid values are "NORMAL", "SV2V", "PL", "PL_W_TIMING"
  parameter  USE_ZERO_RISCY = 0;
  parameter  RISCY_RV32F    = 0;
  parameter  ZERO_RV32M     = 1;
  parameter  ZERO_RV32E     = 0;


  string        memload;
  logic         s_rst_n = 1'b0;
  wire          s_rst_n_wire = s_rst_n;
  logic         fetch_enable = 1'b0;
  wire          fetch_enable_wire = fetch_enable;

  logic [1:0]   padmode_spi_master;
  logic         spi_sck   = 1'b0;
  wire          spi_sck_wire = spi_sck;
  logic         spi_csn   = 1'b1;
  wire          spi_csn_wire = spi_csn;
  logic [1:0]   spi_mode;
  logic         spi_sdo0;
  wire          spi_sdo0_wire = spi_sdo0;
  logic         spi_sdo1;
  logic         spi_sdo2;
  logic         spi_sdo3;
  wire          spi_sdi0;
  logic         spi_sdi1;
  logic         spi_sdi2;
  logic         spi_sdi3;

  wire          uart_tx;
  wire          uart_rx;
  logic         s_uart_dtr;
  logic         s_uart_rts;

  logic         scl_pad_i;
  logic         scl_pad_o;
  logic         scl_padoen_o;

  logic         sda_pad_i;
  logic         sda_pad_o;
  logic         sda_padoen_o;

  wire          scl_io;
  wire          sda_io;
  pullup(scl_io);
  pullup(sda_io);

  localparam int GPIO_WIDTH = 21;
  logic [GPIO_WIDTH - 1: 0]  gpio_in = 'z;
  wire  [GPIO_WIDTH - 1: 0]  gpio = gpio_in;
  // NOTE:
  // For SMIC110 process, GPIO uses PBSD2 pad that has a pulldown resistor constantly connected to the pad.
  //                      and when gpio_in is Hi-Z, gpio is zero.
  // For SKY130 process, GPIO use gpiov2 pad, and no pulldown resistor connects to the pad when output is disabled.
  //                     and when gpio_in is Hi-Z, pad output is disabled, gpio is also Hi-Z.
  //                     And this introduces `X` into the SoC.
  // To avoid `X` in simulation, always attach pulldown resistor to GPIO pads .
  generate
    for (genvar k = 0; k < GPIO_WIDTH; ++k) begin: GPIO_PAD_PULLDOWN
      pulldown(gpio[k]);
    end
  endgenerate

  logic [7:0] upio_in = 'z;
  wire  [7:0] upio = upio_in;

  logic [31:0]  recv_data;

  jtag_i jtag_if();
  wire jtag_tck = jtag_if.tck;
  wire jtag_trstn =  jtag_if.trstn;
  wire jtag_tms = jtag_if.tms;
  wire jtag_tdi = jtag_if.tdi;
  wire jtag_tdo;
  assign jtag_if.tdo = jtag_tdo;

  adv_dbg_if_t adv_dbg_if = new(jtag_if);

  // use 8N1
  uart_bus
  #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0)
  )
  uart
  (
    .rx         ( uart_rx ),
    .tx         ( uart_tx ),
    .rx_en      ( 1'b1    )
  );

  ///////////////////////////
  // SPI Peripherals BEGIN //
  ///////////////////////////

  wire spi_master_clk;
  wire spi_master_csn0;
  wire spi_master_csn1;
  wire spi_master_csn2;
  wire spi_master_csn3;
  wire spi_master_mosi;
  wire spi_master_miso;

  spi_slave spi_dev();

  wire spi_flash_csn;
  wire spi_flash_clk;
  wire spi_flash_di;
  wire spi_flash_do;
  wire spi_flash_wpn;
  wire spi_flash_holdn;
  // pullup(spi_flash_csn);
  // pullup(spi_flash_di);
  // pullup(spi_flash_do);
  pullup(spi_flash_wpn);
  pullup(spi_flash_holdn);

  /* SPI flash model */
  generate
    if (USE_W25Q16JV_MODEL == 1) begin
      flash_wrapper
      #(
        .WITH_TIMING((DUT_IMPL === "PL_W_TIMING") ? 1 : 0)
      )
      spiflash
      (
        .CSn    ( spi_flash_csn   ),
        .CLK    ( spi_flash_clk   ),
        .DIO    ( spi_flash_di    ),
        .DO     ( spi_flash_do    ),
        .WPn    ( spi_flash_wpn   ),
        .HOLDn  ( spi_flash_holdn )
      );
    end
    else begin
      assign spi_flash_do = 'bz;
    end
  endgenerate

  if (TEST == "ARDUINO_SPI") begin
    // NOTE: ARDUINO_SPI and memload == 'STANDALONE' combination does not work.
    assign spi_dev.clk = spi_master_clk;
    assign spi_dev.csn = spi_master_csn0;
    assign spi_dev.sdo[0] = spi_master_mosi;
    assign spi_master_miso = spi_dev.sdi[0];
  end else begin
    assign spi_flash_clk = spi_master_clk;
    assign spi_flash_csn = spi_master_csn0;
    assign spi_flash_di  = spi_master_mosi;
    assign spi_master_miso = spi_flash_do;

    if (TEST == "ICBENCH_SPI_CSN1") begin
      assign spi_dev.clk = spi_master_clk;
      assign spi_dev.csn = spi_master_csn1;
      assign spi_dev.sdo[0] = spi_master_mosi;
      assign spi_master_miso = spi_dev.sdi[0];
    end else if (TEST == "ICBENCH_SPI_CSN2") begin
      assign spi_dev.clk = spi_master_clk;
      assign spi_dev.csn = spi_master_csn2;
      assign spi_dev.sdo[0] = spi_master_mosi;
      assign spi_master_miso = spi_dev.sdi[0];
    end else if (TEST == "ICBENCH_SPI_CSN3") begin
      assign spi_dev.clk = spi_master_clk;
      assign spi_dev.csn = spi_master_csn3;
      assign spi_dev.sdo[0] = spi_master_mosi;
      assign spi_master_miso = spi_dev.sdi[0];
    end
  end

  /////////////////////////
  // SPI Peripherals END //
  /////////////////////////


/*
  i2c_buf i2c_buf_i
  (
    .scl_io       ( scl_io       ),
    .sda_io       ( sda_io       ),
    .scl_pad_i    ( scl_pad_i    ),
    .scl_pad_o    ( scl_pad_o    ),
    .scl_padoen_o ( scl_padoen_o ),
    .sda_pad_i    ( sda_pad_i    ),
    .sda_pad_o    ( sda_pad_o    ),
    .sda_padoen_o ( sda_padoen_o )
  );
*/

  i2c_eeprom_model
  #(
    .ADDRESS ( 7'b1010_000 )
  )
  i2c_eeprom_model_i
  (
    .scl_io ( scl_io  ),
    .sda_io ( sda_io  ),
    .rst_ni ( s_rst_n )
  );

  chip_top_wrapper
  #(
    .DUT_IMPL          ( DUT_IMPL       ),
    .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
    .RISCY_RV32F       ( RISCY_RV32F    ),
    .ZERO_RV32M        ( ZERO_RV32M     ),
    .ZERO_RV32E        ( ZERO_RV32E     )
   )
  top_i
  (
    .clk_pad           ( s_clk        ),
    .rst_n_pad         ( s_rst_n_wire ),
    .fetch_enable_pad  ( fetch_enable_wire ),

    // PULPino as SPI Slave
    .spi_clk_pad       ( spi_sck_wire ),
    .spi_cs_pad        ( spi_csn_wire ),
    .spi_miso_pad      ( spi_sdi0   ),
    .spi_mosi_pad      ( spi_sdo0_wire ),

    // PULPino as SPI Master
    .spi_master_clk_pad  ( spi_master_clk  ),
    .spi_master_csn0_pad ( spi_master_csn0 ),
    .spi_master_csn1_pad ( spi_master_csn1 ),
    .spi_master_csn2_pad ( spi_master_csn2 ),
    .spi_master_csn3_pad ( spi_master_csn3 ),
    .spi_master_mosi_pad ( spi_master_mosi ),
    .spi_master_miso_pad ( spi_master_miso ),

    .scl_pad(scl_io),
    .sda_pad(sda_io),
    
    .uart_tx_pad          ( uart_rx ),
    .uart_rx_pad          ( uart_tx ),

    .gpio_pad             (gpio),

    .upio_pad             (upio),

    .tck_pad              ( jtag_tck     ),
    .trstn_pad            ( jtag_trstn   ),
    .tms_pad              ( jtag_tms     ),
    .tdi_pad              ( jtag_tdi     ),
    .tdo_pad              ( jtag_tdo     )
  );

  logic use_qspi;
  pkg_exit_status::Status spi_check_status;
  wire  [GPIO_WIDTH - 1: 0]  gpio_o = top_i.C.i.gpio_out;
  wire  [7:0]                upio_o = top_i.C.i.upio_out;

  initial
  begin
    int i;

    if(!$value$plusargs("MEMLOAD=%s", memload))
      memload = "PRELOAD";

    $display("Using MEMLOAD method: %s", memload);

    $display("Using %s core", USE_ZERO_RISCY ? "zero-riscy" : "ri5cy");

    use_qspi = SPI == "QUAD" ? 1'b1 : 1'b0;

    s_rst_n      = 1'b0;
    fetch_enable = 1'b0;

    #500ns;

    s_rst_n = 1'b1;

    #500ns;
    if (use_qspi)
      spi_enable_qpi();


    if (memload != "STANDALONE")
    begin
      /* Configure JTAG and set boot address */
      adv_dbg_if.jtag_reset();
      adv_dbg_if.jtag_softreset();
      adv_dbg_if.init();
      adv_dbg_if.axi4_write32(32'h1A10_7008, 1, 32'h0000_0000);
    end

    if (memload == "PRELOAD")
    begin
      // preload memories
      mem_preload();
    end
    else if (memload == "SPI")
    begin
      spi_load(use_qspi);
      spi_check(use_qspi);
    end

    #200ns;
    fetch_enable = 1'b1;

    if(TEST == "DEBUG") begin
      debug_tests();
    end else if (TEST == "DEBUG_IRQ") begin
      debug_irq_tests();
    end else if (TEST == "MEM_DPI") begin
      mem_dpi(4567);
    end else if (TEST == "ARDUINO_UART") begin
      if (~top_i.C.i.gpio_out[0])
        wait(top_i.C.i.gpio_out[0]);
      uart.send_char(8'h65);
    end else if (TEST == "ARDUINO_GPIO") begin
      // Here  test for GPIO Starts
      if (~top_i.C.i.gpio_out[0])
        wait(top_i.C.i.gpio_out[0]);

      gpio_in[4]=1'b1;

      if (~top_i.C.i.gpio_out[1])
        wait(top_i.C.i.gpio_out[1]);
      if (~top_i.C.i.gpio_out[2])
        wait(top_i.C.i.gpio_out[2]);
      if (~top_i.C.i.gpio_out[3])
        wait(top_i.C.i.gpio_out[3]);

      gpio_in[7]=1'b1;

    end else if (TEST == "ARDUINO_SHIFT") begin

      if (~top_i.C.i.gpio_out[0])
        wait(top_i.C.i.gpio_out[0]);
      //start TEST

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b1;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b1;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b0;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b0;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b1;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b0;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b0;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

      if (~top_i.C.i.gpio_out[4])
        wait(top_i.C.i.gpio_out[4]);
      gpio_in[3]=1'b1;
      if (top_i.C.i.gpio_out[4])
        wait(~top_i.C.i.gpio_out[4]);

    end else if (TEST == "ARDUINO_PULSEIN") begin
      if (~top_i.C.i.gpio_out[0])
        wait(top_i.C.i.gpio_out[0]);

      // Add 1ns delay to avoid gpio change on clock edge.
      // When gpio input changes on clock edge,
      // it is hard to say which value (before / after change) will be sampled immediately.
      // And this uncertainty lead to original / sv2v design assertion check failure.
      #50us;  #1ns;
      gpio_in[4]=1'b1;
      #500us; #1ns;
      gpio_in[4]=1'b0;
      #1ms;   #1ns;
      gpio_in[4]=1'b1;
      #500us; #1ns;
      gpio_in[4]=1'b0;
    end else if (TEST == "ARDUINO_INT") begin
      if (~top_i.C.i.gpio_out[0])
        wait(top_i.C.i.gpio_out[0]);

      // Add 1ns delay to avoid gpio change on clock edge.
      // When gpio input changes on clock edge,
      // it is hard to say which value (before / after change) will be sampled immediately.
      // And this uncertainty lead to original / sv2v design assertion check failure.
      #50us; #1ns;
      gpio_in[1]=1'b1;
      #20us; #1ns;
      gpio_in[1]=1'b0;
      #20us; #1ns;
      gpio_in[1]=1'b1;
      #20us; #1ns;
      gpio_in[2]=1'b1;
      #20us; #1ns;
    end else if (TEST == "ARDUINO_SPI") begin
      for(i = 0; i < 2; i++) begin
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {>>{8'h38}});
      end
    end else if (TEST == "ICBENCH_SPI_CSN1") begin
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {<<{8'h37}});
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {<<{8'h36}});
    end else if (TEST == "ICBENCH_SPI_CSN2") begin
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {<<{8'h47}});
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {<<{8'h46}});
    end else if (TEST == "ICBENCH_SPI_CSN3") begin
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {<<{8'h57}});
        spi_dev.wait_csn(1'b0);
        spi_dev.send(0, {<<{8'h56}});
    end else if (TEST == "ICBENCH_GPIO") begin
      test_input(8, GPIO_WIDTH);
      gpio_in = 'bz;
      test_output(8, GPIO_WIDTH);
      gpio_in = 'bz;
      test_interrupt_rise(8, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;
      test_interrupt_fall(8, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;
      test_interrupt_lev0(8, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;
      test_interrupt_lev1(8, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;

      test_input(9, GPIO_WIDTH);
      gpio_in = 'bz;
      test_output(9, GPIO_WIDTH);
      gpio_in = 'bz;
      test_interrupt_rise(9, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;
      test_interrupt_fall(9, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;
      test_interrupt_lev0(9, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;
      test_interrupt_lev1(9, GPIO_WIDTH);
      #1000ns;
      gpio_in = 'bz;

      wait(gpio_o[8] === 0); wait(gpio_o[8] === 1); // Wait for software req
  
    end else if (TEST == "ICBENCH_GPIO_FAST") begin
      test_gpio_fast(9);
      test_gpio_fast(10);
      gpio_in = 'bz;
    end else if (TEST == "UPIO") begin
      test_upio(0);
      test_upio(1);
    end



    // end of computation
    if (~top_i.C.i.gpio_out[8])
      wait(top_i.C.i.gpio_out[8]);

    spi_check_return_codes(spi_check_status);
    exit_status_if.Done(spi_check_status);
  end

  //////////////////////////////
  // Assertions on GPIO BEGIN //
  //////////////////////////////

  // assert property( top_i.C.i.gpio_dir[0] |-> top_i.C.i.gpio[0] === top_i.C.i.gpio_out[0]);
  // assert #0 ( top_i.C.i.gpio_dir[0] || gpio[0] === top_i.C.i.gpio_out[0]) $display("PASS"); else $error("NOT PASS");
  task gpio_out_check_error;
    input integer i;
    $error("GPIO[%d] output assertion error", i);
    exit_status_if.Done(pkg_exit_status::ERROR);
  endtask

  generate
    for (genvar k = 0; k < GPIO_WIDTH; ++k) begin: GPIO_ASSERT_GEN
      // Deferred assertion cannot be written like `assert #0 (...) else begin ... end;
      // A task is required to encapsulate error actions.
      // top_i.C.i.gpio_dir[k] |-> gpio[k] === top_i.C.i.gpio_out[k]
      // assert #0 ( ~(~top_i.C.i.gpio_pad_OEN[k]) || gpio[k] === top_i.C.i.gpio_out[k]) else gpio_out_check_error(k);
      assert property (@(posedge s_clk) ~top_i.C.i.gpio_pad_OEN[k] |-> gpio[k] === top_i.C.i.gpio_out[k]) else gpio_out_check_error(k);
    end
  endgenerate

  ////////////////////////////
  // Assertions on GPIO END //
  ////////////////////////////


  // TODO: this is a hack, do it properly!
  `include "tb_spi_pkg.sv"
  `include "tb_mem_pkg.sv"
  `include "spi_debug_test.svh"
  `include "mem_dpi.svh"
  `include "gpio_test.sv"
  `include "gpio_fast_test.sv"
  `include "upio_test.sv"
endmodule
