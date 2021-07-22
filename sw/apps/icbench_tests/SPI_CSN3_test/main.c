
#include <utils.h>
#include <stdio.h>
#include <spi.h>
#include <bench.h>


uint8_t read_byte() {
  uint32_t word;

  spi_setup_cmd_addr(0, 0, 0, 0);
  spi_set_datalen(8);
  spi_setup_dummy(0, 0);
  spi_start_transaction(SPI_CMD_RD, SPI_CSN3);
  spi_read_fifo((int*)&word, 8);

  // Only keep the last byte of word.
  uint8_t ret = word;
  return ret;
}

void read_and_check_byte(testresult_t *result, uint8_t expected) {
  uint8_t v = read_byte();
  if (v != expected) {
    printf("Expect %d, but got %d\n", expected, v);
    result->errors ++;
  }
}

void check(testresult_t *result, void (*start)(), void (*stop)());

testcase_t testcases[] = {
  { .name = "SPI Quick Check",   .test = check       },
  {0, 0}
};

int main() {
  return run_suite(testcases);
}

void check(testresult_t *result, void (*start)(), void (*stop)()) {
  volatile int k;

  start();

  result->errors = 0;

  // SPI clock = Fsoc / (2 * (CLKDIV + 1))
  // Use 0x1 to save simulation time.
  // To run on real chip, probably set the value to 0x4.
  // NOTE: MUST NOT set SPI_REG_CLKDIV to 0x0, it may introduce timing issue.
  *(volatile int*) (SPI_REG_CLKDIV) = 0x1;

  read_and_check_byte(result, 0x57);
  read_and_check_byte(result, 0x56);

  stop();
}
