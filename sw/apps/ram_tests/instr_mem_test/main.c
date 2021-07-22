#include <stdio.h>

unsigned int cnt = 0;

#define INC_1 do { \
    asm volatile("addi %[c], %[a], 1\n" \
                 : [c] "+r" (cnt) \
                 : [a] "r"  (cnt)); \
} while(0)

#define INC_2 do { INC_1; INC_1; } while(0)
#define INC_4 do { INC_2; INC_2; } while(0)
#define INC_8 do { INC_4; INC_4; } while(0)
#define INC_16 do { INC_8; INC_8; } while(0)
#define INC_32 do { INC_16; INC_16; } while(0)
#define INC_64 do { INC_32; INC_32; } while(0)
#define INC_128 do { INC_64; INC_64; } while(0)
#define INC_256 do { INC_128; INC_128; } while(0)
#define INC_512 do { INC_256; INC_256; } while(0)
#define INC_1024 do { INC_512; INC_512; } while(0)
#define INC_2048 do { INC_1024; INC_1024; } while(0)
#define INC_4096 do { INC_2048; INC_2048; } while(0)


int main() {
  // With 4096 and 2048 volatile asm addi, the size of text segment:
  // $ size ./apps/ram_tests/instr_mem_test/instr_mem_test.elf
  //    text   data    bss    dec    hex   filename
  //   31572    144   4220  35936   8c60   ./apps/ram_tests/instr_mem_test/instr_mem_test.elf
  //   About 30.8KB
  INC_4096;
  INC_2048;

  unsigned int expected = 4096 + 2048;
  if (cnt != expected) {
      printf("Instruction memory failure detected\n");
      printf("cnt value is not expected. Actual value: %u, expected: %u\n", cnt, expected);
      return 1;
  }
  printf("cnt value: %u\n", cnt);
  printf("Instruction memory test success!\n");
  return 0;
}
