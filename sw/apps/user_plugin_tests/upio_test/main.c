#include <stdio.h>
#include "user_plugin/apb.h"

void set_upio_pin_value(int pinnumber, int value) {
  int v = UP_APB_PADOUT;

  if (value == 0) {
    v &= ~(1 << pinnumber);
  } else {
    v |= 1 << pinnumber;
  }
  UP_APB_PADOUT = v;
}


void check_input(int* perrors, unsigned int expected) {
    unsigned int in = UP_APB_PADIN;
    if (in != expected) {
      (*perrors)++;
      printf("Expected input: %X, but got: %X\n", expected, in);
    }
}


void simple_check(int* perrors, int sync_pin_idx) {
    ///////////////////////////
    // Set all pads as input //
    ///////////////////////////
    UP_APB_PADDIR = 0;

    // Inform tb to proceed.
    set_upio_pin_value(sync_pin_idx, 0);
    set_upio_pin_value(sync_pin_idx, 1);

    check_input(perrors, 0x55);
    // Inform tb to proceed.
    set_upio_pin_value(sync_pin_idx, 0);
    set_upio_pin_value(sync_pin_idx, 1);

    check_input(perrors, 0xAA);
    // Inform tb to proceed.
    set_upio_pin_value(sync_pin_idx, 0);
    set_upio_pin_value(sync_pin_idx, 1);

    ////////////////////////////////////////////////
    // Set all pads as output except the sync_pin //
    ////////////////////////////////////////////////
    UP_APB_PADDIR = ~(1 << sync_pin_idx);
    // sync pin is zero
    UP_APB_PADOUT = 0x55 & ~(1 << sync_pin_idx);
    // sync pin is one
    UP_APB_PADOUT = 0x55 | (1 << sync_pin_idx);

    // sync pin is zero
    UP_APB_PADOUT = 0xAA & ~(1 << sync_pin_idx);
    // sync pin is one
    UP_APB_PADOUT = 0xAA | (1 << sync_pin_idx);
}


int main() {
    int errors = 0;
    simple_check(&errors, 0);
    simple_check(&errors, 1);
    return !(errors == 0);
}
