task test_upio
(
  input int upio_sync_pin
);

  test_upio_wait_sync(upio_sync_pin);

  upio_in = 'b0101_0101;
  test_upio_wait_sync(upio_sync_pin);
  upio_in = 'b1010_1010;
  test_upio_wait_sync(upio_sync_pin);

  // Test OUTPUT
  upio_in = 'bz;
  test_upio_wait_sync(upio_sync_pin);
  // upio has pulldown resistor attached, and the upio_sync_pin is zero when configured as input.
  if (upio != ('b0101_0101 & ~(1 << upio_sync_pin))) begin
    exit_status_if.Done(pkg_exit_status::ERROR);
  end
  test_upio_wait_sync(upio_sync_pin);
  // upio has pulldown resistor attached, and the upio_sync_pin is zero when configured as input.
  if (upio != ('b1010_1010 & ~(1 << upio_sync_pin))) begin
    exit_status_if.Done(pkg_exit_status::ERROR);
  end
endtask

task test_upio_wait_sync
(
  input int upio_sync_pin
);

  wait(upio_o[upio_sync_pin] === 0); wait(upio_o[upio_sync_pin] === 1);// Wait for software req
endtask
