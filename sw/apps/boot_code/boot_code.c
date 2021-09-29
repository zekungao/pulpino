// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


#include <spi.h>
#include <gpio.h>
#include <uart.h>
#include <utils.h>
#include <pulpino.h>

const char g_numbers[] = {
                           '0', '1', '2', '3', '4', '5', '6', '7',
                           '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
                         };

int check_spi_flash();
void read_words(uint32_t addr, uint32_t* wordBuf, unsigned int wordSize);
void uart_send_block_done(unsigned int i);
void jump_and_start(volatile int *ptr);

#define UART_SEND_STR(s) do { \
  uart_send(s, sizeof(s) - 1); \
} while(0)

#define UART_SEND_STR_AND_WAIT_TX_DONE(s) do { \
  UART_SEND_STR(s); \
  uart_wait_tx_done(); \
} while(0)

int main()
{
  /* sets direction for SPI master pins with only one CS */
  // NOTE: spi_set_master write PADMUX register, which is not used by ICBENCH pulpino.
  //       And spi_setup_master can be removed.
  spi_setup_master(1);
  uart_set_cfg(0, 1);

  for (int i = 0; i < 3000; i++) {
    //wait some time to have proper power up of external flash
    #ifdef __riscv__
        asm volatile ("nop");
    #else
        asm volatile ("l.nop");
    #endif
  }

  /* divide sys clock by 4 + 1 */
  // SPI clock = Fsoc / (2 * (CLKDIV + 1))
  *(volatile int*) (SPI_REG_CLKDIV) = 0x4;

  if (check_spi_flash()) {
    UART_SEND_STR("ERROR: Winbond SPI flash not found\n");
    while (1);
  }

  UART_SEND_STR_AND_WAIT_TX_DONE("Loading from SPI\n");

  //-----------------------------------------------------------
  // Read header
  //-----------------------------------------------------------

  int header_ptr[8];
  int addr = 0;

  read_words(addr, (uint32_t*)header_ptr, sizeof(header_ptr) / sizeof(header_ptr[0]));

  int instr_start = header_ptr[0];
  int *instr = (int *) header_ptr[1];
  int instr_size =  header_ptr[2];
  int instr_blocks = header_ptr[3];

  int data_start = header_ptr[4];
  int *data = (int *) header_ptr[5];
  int data_size = header_ptr[6];
  int data_blocks = header_ptr[7];

  #define BLOCK_BYTES 4096
  #define BLOCK_WORDS (BLOCK_BYTES / 4)

  //-----------------------------------------------------------
  // Read Instruction RAM
  //-----------------------------------------------------------

  UART_SEND_STR_AND_WAIT_TX_DONE("Copying Instructions\n");

  addr = instr_start;
  for (int i = 0; i < instr_blocks; i++) {
    read_words(addr, (uint32_t*)instr, BLOCK_WORDS);

    instr += BLOCK_WORDS; // new address = old address + 1024 words
    addr  += BLOCK_BYTES; // new address = old address + 4KB

    uart_send_block_done(i);
  }

  //-----------------------------------------------------------
  // Read Data RAM
  //-----------------------------------------------------------

  UART_SEND_STR_AND_WAIT_TX_DONE("Copying Data\n");

  addr = data_start;
  for (int i = 0; i < data_blocks; i++) {
    read_words(addr, (uint32_t*)data, BLOCK_WORDS);

    data += BLOCK_WORDS; // new address = old address + 1024 words
    addr += BLOCK_BYTES; // new address = old address + 4KB

    uart_send_block_done(i);
  }

  UART_SEND_STR_AND_WAIT_TX_DONE("Done, jumping to Instruction RAM.\n");

  //-----------------------------------------------------------
  // Set new boot address -> exceptions/interrupts/events rely
  // on that information
  //-----------------------------------------------------------

  BOOTREG = 0x00;

  //-----------------------------------------------------------
  // Done jump to main program
  //-----------------------------------------------------------

  //jump to program start address (instruction base address)
  jump_and_start((volatile int *)(INSTR_RAM_START_ADDR));
}



/////////////////////
// Flash: W25Q16JV //
/////////////////////

#define CMD_READ_JEDEC_ID               0x9F
#define CMD_READ_DATA                   0x03

// Wait for read/write transition to finish.
static inline void wait_spi_idle() {
  while ((spi_get_status() & 0xFFFF) != 1);
}

static inline void wait_flash_idle() {
  // Because there is neither erasing nor writing, only reading.
  // Just wait for SPI idle.
  wait_spi_idle();
}

uint32_t read_JEDEC_ID() {
  uint32_t ret;

  wait_flash_idle();
  spi_setup_cmd_addr(CMD_READ_JEDEC_ID, 8, 0, 0);
  spi_set_datalen(24);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_RD, SPI_CSN0);
  spi_read_fifo((int*)&ret, 24);
  return ret;
}

// Read words.
// One word is 4-byte.
// Note spi_set_datalen set bit-length, and max bit-length is 65535,
// about 65535 / 32 = 2047.96875 words.
// In other words, max wordSize is 2047.
void read_words(uint32_t addr, uint32_t* wordBuf, unsigned int wordSize) {
  wait_flash_idle();
  spi_setup_cmd_addr(CMD_READ_DATA, 8, addr << 8, 24);
  spi_set_datalen(wordSize * 32);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_RD, SPI_CSN0);
  spi_read_fifo((int*)wordBuf, wordSize * 32);
}

int check_spi_flash() {
  int err = 0;
  uint32_t rd_id = read_JEDEC_ID();

  // id should be 0x00EF4015;
  // Only check manufacture id
  if (((rd_id >> 16) & 0xFF) != 0xEF)
    err++;

  return err;
}

void jump_and_start(volatile int *ptr)
{
#ifdef __riscv__
  asm("jalr x0, %0\n"
      "nop\n"
      "nop\n"
      "nop\n"
      : : "r" (ptr) );
#else
  asm("l.jr\t%0\n"
      "l.nop\n"
      "l.nop\n"
      "l.nop\n"
      : : "r" (ptr) );
#endif
}

void uart_send_block_done(unsigned int i) {
  unsigned int low  = i & 0xF;
  unsigned int high = i >>  4; // /16

  UART_SEND_STR("Block ");

  uart_send(&g_numbers[high], 1);
  uart_send(&g_numbers[low], 1);

  UART_SEND_STR(" done\n");

  uart_wait_tx_done();
}
