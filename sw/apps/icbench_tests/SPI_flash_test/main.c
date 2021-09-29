// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


#include <utils.h>
#include <stdio.h>
#include <spi.h>
#include <bench.h>

// Flash: W25Q16JV
//
// From datasheet:
//
// The W25Q16JV array is organized into 8,192 programmable pages of 256-bytes each.
// The total size = 8192 * 256 = 2MB
//
// Clock frequency for Read Data instruction (03h)  Min: D.C. Max: 50MHz

#define FLASH_LAST_ADDR                 0x1FFFFF

#define CMD_READ_JEDEC_ID               0x9F
#define CMD_READ_STATUS_REG1            0x05
#define CMD_WRITE_ENABLE                0x06
#define CMD_ERASE_SECTOR_4K             0x20
#define CMD_READ_DATA                   0x03
#define CMD_PAGE_PROG                   0x02

#define STATUS_REG1_BUSY                (0x01)
#define STATUS_REG1_WEL                 (0x01 << 1)


// https://en.wikipedia.org/wiki/Linear_congruential_generator
// Use a random-number-generation-like method to generate number for each address.
#define V(addr) ((1103515245 * (unsigned int)(addr) + 12345) % 0x80000000)


// Wait for read/write transition to finish.
inline void wait_spi_idle() {
  while ((spi_get_status() & 0xFFFF) != 1);
}

uint8_t read_status_reg1() {
  uint32_t word;

  wait_spi_idle();
  spi_setup_cmd_addr(CMD_READ_STATUS_REG1, 8, 0, 0);
  spi_set_datalen(8);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_RD, SPI_CSN0);
  spi_read_fifo((int*)&word, 8);

  // Only keep the last byte of word.
  uint8_t ret = word;
  return ret;
}

// Wait for write in progress done.
inline void wait_erase_write_busy_done() {
  while((read_status_reg1() & STATUS_REG1_BUSY) != 0);
} 

inline void wait_flash_idle() {
  wait_erase_write_busy_done();
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

void _write_enable() {
  spi_setup_cmd_addr(CMD_WRITE_ENABLE, 8, 0, 0);
  spi_set_datalen(0);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_WR, SPI_CSN0);
}

void erase_sector_4k(uint32_t addr) {
  wait_flash_idle();
  _write_enable();

  wait_spi_idle();
  spi_setup_cmd_addr(CMD_ERASE_SECTOR_4K, 8, (addr << 8), 24);
  spi_set_datalen(0);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_WR, SPI_CSN0);

  wait_erase_write_busy_done();
}

// Write one page.
// One word is 4-byte.
// Bytes of a page is 256-bytes, 256 / 4 = 64 words.
//
// If an entire 256 byte page is to be programmed, the last address byte (the 8 least significant address bits)
// should be set to 0. If the last address byte is not zero, and the number of clocks exceeds the remaining
// page length, the addressing will wrap to the beginning of the page. In some cases, less than 256 bytes (a
// partial page) can be programmed without having any effect on other bytes within the same page. One
// condition to perform a partial page program is that the number of clocks cannot exceed the remaining page
// length. If more than 256 bytes are sent to the device the addressing will wrap to the beginning of the page
// and overwrite previously sent data.
void write_page(uint32_t addr, uint8_t* buf, unsigned int byteSize) {
  wait_flash_idle();
  _write_enable();

  wait_spi_idle();
  spi_setup_cmd_addr(CMD_PAGE_PROG, 8, addr << 8, 24);
  spi_set_datalen(byteSize * 8);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_WR, SPI_CSN0);
  spi_write_fifo((int*)buf, byteSize * 8);

  wait_erase_write_busy_done();
}


void check_JEDEC_ID(testresult_t* result) {
  printf("Checking JEDEC ID ...\n");

  uint32_t id = read_JEDEC_ID();
  uint32_t expected_id = 0x00EF4015; 
  printf("JEDEC ID: %X\n", (unsigned int) id);

  if (id != expected_id) {
    result->errors++;
    printf("Error: Expected JEDEC ID: %X, actual ID: %X\n", (unsigned int)expected_id, (unsigned int)id);
  }
}

void _checkReadAfterEraseSector4k(testresult_t* result, uint32_t addr) {
  printf("Checking reading after erasing 4k start at: 0x%X ...\n", (unsigned int)addr);
  printf("Erasing 4k start at: 0x%X ...\n", (unsigned int)addr);
  erase_sector_4k(addr);

  // Use 1k bytes buf;
  uint32_t buf[256];
  for (uint32_t i = 0; i < 4; ++i) {
    // Init buf to zeros.
    for (uint32_t j = 0; j < sizeof(buf) / sizeof(buf[0]); ++j) {
      buf[j] = 0;
    }

    uint32_t read_addr = addr + i * sizeof(buf);
    printf("Reading 1k start at: 0x%X ...\n", (unsigned int)read_addr);
    read_words(read_addr, buf, sizeof(buf) / sizeof(buf[0]));

    // All buf values should be all ones.
    for (uint32_t j = 0; j < sizeof(buf) / sizeof(buf[0]); ++j) {
      uint32_t expected = 0xFFFFFFFF;
      if (buf[j] != expected) {
        result->errors++;
        printf("Error: Unexpected value: %X, expect: %X\n", (unsigned int)buf[j], (unsigned int)expected);
      }
    }
  }
}

void checkReadAfterEraseSector4k(testresult_t* result) {
  printf("Checking sector 4k reading after erasing ...\n");

  // All read data should be ones.
  _checkReadAfterEraseSector4k(result, 0);
  _checkReadAfterEraseSector4k(result, 4 * 1024);
  _checkReadAfterEraseSector4k(result, FLASH_LAST_ADDR + 1 - 4 * 1024);
  _checkReadAfterEraseSector4k(result, FLASH_LAST_ADDR + 1 - 2 * (4 * 1024));
}

void  _checkReadAfterEraseWriteSector4k(testresult_t* result, uint32_t addr) {
  // Make addr 4k aligned.
  addr &= ~0xFFF;

  printf("Checking reading after erasing 4k start at: 0x%X ...\n", (unsigned int)addr);
  printf("Erasing 4k start at: 0x%X ...\n", (unsigned int)addr);
  erase_sector_4k(addr);

  // Write phase
  {
    // A 4k sector has 4096 / 256 = 16 pages.
    uint32_t wordsPage[64];
    for (uint32_t pageAddr = addr; pageAddr < addr + 4096; pageAddr += sizeof(wordsPage)) {
      // Prepare values of a page.
      for (uint32_t i = 0; i < sizeof(wordsPage) / sizeof(wordsPage[0]); ++i) {
        uint32_t wordAddr = pageAddr + i * 4;
        wordsPage[i] = V(wordAddr);
      }

      // Write these values to page.
      printf("Write to 256-byte page start at: 0x%X ...\n", (unsigned int)pageAddr);
      write_page(pageAddr, (uint8_t*)wordsPage, sizeof(wordsPage));
    }
  }

  // Read back phase
  {
    // Read by 1K-bytes
    uint32_t wordsBuf[256];
    for (uint32_t readAddr = addr; readAddr < addr + 4096; readAddr += sizeof(wordsBuf)) {
      printf("Reading and checking %u words start at: 0x%X ...\n", sizeof(wordsBuf) / sizeof(wordsBuf[0]), (unsigned int)readAddr);

      read_words(readAddr, wordsBuf, sizeof(wordsBuf) / sizeof(wordsBuf[0]));
      for (uint32_t i = 0; i < sizeof(wordsBuf) / sizeof(wordsBuf[0]); ++i) {
        const uint32_t wordAddr = readAddr + i * 4;
        const uint32_t expected = V(wordAddr);
        if (wordsBuf[i] != expected) {
          result->errors++;
          printf("Error: read back error at address: 0x%X. Expected word: %X, actual word: %X\n",
                 (unsigned int)wordAddr, (unsigned int)expected, (unsigned int)wordsBuf[i]);
        }
      }
    }
  }
}


void checkReadAfterEraseWriteSector4k(testresult_t* result) {
  printf("Checking sector 4k reading after erasing / writing ...\n");

  _checkReadAfterEraseWriteSector4k(result, 0);
  _checkReadAfterEraseWriteSector4k(result, 4 * 1024);
  _checkReadAfterEraseWriteSector4k(result, FLASH_LAST_ADDR + 1 - 4 * 1024);
  _checkReadAfterEraseWriteSector4k(result, FLASH_LAST_ADDR + 1 - 2 * (4 * 1024));
}


void check_standard_mode(testresult_t *result, void (*start)(), void (*stop)());

testcase_t testcases[] = {
  { .name = "SPI Master Standard Mode",   .test = check_standard_mode       },
  {0, 0}
};

int main() {
  return run_suite(testcases);
}

void check_standard_mode(testresult_t *result, void (*start)(), void (*stop)()) {
  volatile int k;

  start();

  result->errors = 0;

  printf("Waiting for SPI flash to power up ...\n");
  // waste some time and wait for flash to power up
  for (int i = 0; i < 33333; i++) k = 0;

  printf("Setting SPI clock division ..\n");
  // SPI clock = Fsoc / (2 * (CLKDIV + 1))
  // *(volatile int*) (SPI_REG_CLKDIV) = 0x4;
  // Use 0x1 to save simulation time.
  // To run on real chip, probably set the value to 0x4.
  // NOTE: MUST NOT set SPI_REG_CLKDIV to 0x0, it may introduce timing issue.
  //       A postlayout simulation failure has been observed that mosi goes 0.805ns behind spi clk posedge,
  //       and flash model $hold check failed.
  *(volatile int*) (SPI_REG_CLKDIV) = 0x1;

  // Not used by ICBENCH pulpino
  // spi_setup_master(1); //sets direction for SPI master pins with only one CS
  check_JEDEC_ID(result);
  checkReadAfterEraseSector4k(result);
  checkReadAfterEraseWriteSector4k(result);

  stop();
}
