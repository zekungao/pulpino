// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

generate
  if (DUT_IMPL == "NORMAL") begin: BANK_WR
    task write_data_word;
      input integer      byte_addr;
      input logic [31:0] word;
      tb_chip_top_i.top_i.C.i.top_wrapper_i.pulpino_top_i.core_region_i.data_mem.write_word(byte_addr, word);
    endtask

    task write_instr_word;
      input integer      byte_addr;
      input logic [31:0] word;
      tb_chip_top_i.top_i.C.i.top_wrapper_i.pulpino_top_i.core_region_i.instr_mem.sp_ram_wrap_i.write_word(byte_addr, word);
    endtask

  end else begin: BANK_WR

    task write_data_word;
      input integer      byte_addr;
      input logic [31:0] word;

      $error("mem_preload not supported with DUT_IMPL: %s", DUT_IMPL);
      exit_status_if.Done(pkg_exit_status::ERROR);
    endtask

    task write_instr_word;
      input integer      byte_addr;
      input logic [31:0] word;

      $error("mem_preload not supported with DUT_IMPL: %s", DUT_IMPL);
      exit_status_if.Done(pkg_exit_status::ERROR);
    endtask

  end
endgenerate


logic [31:0]     data_mem[];  // this variable holds the whole memory content
logic [31:0]     instr_mem[]; // this variable holds the whole memory content
event            event_mem_load;


task mem_preload;
  integer      addr;
  integer      instr_size;
  integer      instr_width;
  integer      data_size;
  integer      data_width;
  logic [31:0] data;
  string       l2_imem_file;
  string       l2_dmem_file;
  begin
    $display("Preloading memory");

    // Get parameter values from `tb.tb_chip_top_i`
    instr_size   = tb.tb_chip_top_i.top_i.C.i.top_wrapper_i.pulpino_top_i.core_region_i.instr_mem.sp_ram_wrap_i.RAM_SIZE;
    instr_width = tb.tb_chip_top_i.top_i.C.i.top_wrapper_i.pulpino_top_i.core_region_i.instr_mem.sp_ram_wrap_i.DATA_WIDTH;

    data_size   = tb.tb_chip_top_i.top_i.C.i.top_wrapper_i.pulpino_top_i.core_region_i.data_mem.RAM_SIZE;
    data_width = tb.tb_chip_top_i.top_i.C.i.top_wrapper_i.pulpino_top_i.core_region_i.data_mem.DATA_WIDTH;

    instr_mem = new [instr_size/4];
    data_mem  = new [data_size/4];

    if(!$value$plusargs("l2_imem=%s", l2_imem_file))
       l2_imem_file = "slm_files/l2_stim.slm";

    $display("Preloading instruction memory from %0s", l2_imem_file);
    $readmemh(l2_imem_file, instr_mem);

    if(!$value$plusargs("l2_dmem=%s", l2_dmem_file))
       l2_dmem_file = "slm_files/tcdm_bank0.slm";

    $display("Preloading data memory from %0s", l2_dmem_file);
    $readmemh(l2_dmem_file, data_mem);


    // preload data memory
    for(addr = 0; addr < data_size; addr += 4) begin
        data = data_mem[addr / 4];
        BANK_WR.write_data_word(addr, data);
    end

    // preload instruction memory
    for(addr = 0; addr < instr_size; addr += 4) begin
        data = instr_mem[addr / 4];
        BANK_WR.write_instr_word(addr, data);
    end
  end
endtask
