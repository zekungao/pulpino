#include <stdio.h>

//
// These are defined in link.common.ld 
//
// extern unsigned int* _bss_end;
// extern unsigned int* _stack_start;
// extern unsigned int  _stack_len;
//
// But actual value of the above variables are not right (print to uart).
// https://wiki.osdev.org/Linker_Scripts
//
// Thus, according to link.common.ld, a simple method is to declare a large array.

unsigned int bigArray[22 * 1024 / sizeof(unsigned int)];

// https://en.wikipedia.org/wiki/Linear_congruential_generator
// Use a random-number-generation-like method to generate number for each address.
#define V(addr) ((1103515245 * (unsigned int)(addr) + 12345) % 0x80000000)

int main() {
  unsigned int* endAddr = bigArray + sizeof(bigArray) / sizeof(unsigned int);

  printf("bigArray length: %u bytes\n", sizeof(bigArray));
  printf("bigArray start address: 0x%x\n", (unsigned int)bigArray);
  printf("bigArray end addresss (exclusive): 0x%x\n", (unsigned int)endAddr);

  printf("Writing memory ...\n");
  for (unsigned int* addr = bigArray; addr < endAddr; ++addr) {
      unsigned int v = V(addr);
      *addr = v;
  }

  printf("Reading memory and checking ...\n");
  for (unsigned int* addr = bigArray; addr < endAddr; ++addr) {
      unsigned int v = *addr;
      unsigned int expected = V(addr);
      if (v != expected) {
          printf("Read check failure detected\n");
          printf("Address: 0x%x, value: 0x%x, expected: 0x%x\n", (unsigned int)addr , v, expected);
          return 1;
      }
  }

  printf("Data memory test success!\n");
  return 0;
}
