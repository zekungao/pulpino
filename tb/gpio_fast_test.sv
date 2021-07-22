task test_gpio_fast
(
  input int gpio_sync_pin
);

  test_gpio_fast_wait_sync(gpio_sync_pin);

  gpio_in = 'b1_0101_0101_0101_0101_0101;
  test_gpio_fast_wait_sync(gpio_sync_pin);
  gpio_in = 'b0_1010_1010_1010_1010_1010;
  test_gpio_fast_wait_sync(gpio_sync_pin);

  // Test OUTPUT
  gpio_in = 'bz;
  test_gpio_fast_wait_sync(gpio_sync_pin);
  // gpio has pulldown resistor attached, and the gpio_sync_pin is zero when configured as input.
  if (gpio != ('b1_0101_0101_0101_0101_0101 & ~(1 << gpio_sync_pin))) begin
    exit_status_if.Done(pkg_exit_status::ERROR);
  end
  test_gpio_fast_wait_sync(gpio_sync_pin);
  // gpio has pulldown resistor attached, and the gpio_sync_pin is zero when configured as input.
  if (gpio != ('b0_1010_1010_1010_1010_1010 & ~(1 << gpio_sync_pin))) begin
    exit_status_if.Done(pkg_exit_status::ERROR);
  end
endtask

task test_gpio_fast_wait_sync
(
  input int gpio_sync_pin
);

  wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1);// Wait for software req
endtask
