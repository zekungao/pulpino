#include <stdio.h>
#include "gpio.h"

//
// NOTE: Only 21-bit GPIO is used.
//

void check_input(int* errors, unsigned int expected) {
    unsigned int in = *PADIN;
    if (in != expected) {
      (*errors)++;
      printf("Expected input: %X, but got: %X\n", expected, in);
    }
}

void simple_check(int* perrors, int sync_pin_num) {
    ///////////////////////////
    // Set all pads as input //
    ///////////////////////////
    *PADDIR = 0;

    // Inform tb to proceed.
    set_gpio_pin_value(sync_pin_num, 0);
    set_gpio_pin_value(sync_pin_num, 1);

    check_input(perrors, 0x155555);
    // Inform tb to proceed.
    set_gpio_pin_value(sync_pin_num, 0);
    set_gpio_pin_value(sync_pin_num, 1);

    check_input(perrors, 0x0AAAAA);
    // Inform tb to proceed.
    set_gpio_pin_value(sync_pin_num, 0);
    set_gpio_pin_value(sync_pin_num, 1);

    ////////////////////////////////////////////////
    // Set all pads as output except the sync_pin //
    ////////////////////////////////////////////////
    *PADDIR = ~(1 << sync_pin_num);
    // sync pin is zero
    *PADOUT = 0x155555 & ~(1 << sync_pin_num);
    // sync pin is one
    *PADOUT = 0x155555 | (1 << sync_pin_num);

    // sync pin is zero
    *PADOUT = 0x0AAAAA & ~(1 << sync_pin_num);
    // sync pin is one
    *PADOUT = 0x0AAAAA | (1 << sync_pin_num);
}

int main(){
    int errors = 0;
    simple_check(&errors, 9);
    simple_check(&errors, 10);
    return errors != 0;
}
