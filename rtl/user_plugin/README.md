# User Plugin

The user plugin is intended to be used by users to implement their own logic, and integrate them to PULPino SoC.

Only sources under `rtl` directory will be part of the SoC.

Other directories / files can be created on users needs, e.g.
- `tb` for IP level testbench resources


## Hierarchy

- [pulpino_top_with_pads](/rtl/chip_top/pulpino_top_with_pads.sv)
  - [pulpino_top_wrapper](/rtl/chip_top/pulpino_top_wrapper.sv)
    - [pulpino_top](/rtl/pulpino_top.sv)
      - [peripherals](/rtl/peripherals.sv)
        - [user_plugin](/rtl/user_plugin/rtl/user_plugin.sv)


## Ports

 - `clk_i`: SoC clock input

 - `rst_n`: SoC reset input

 - `apb_slv`: APB slave
   - Memory map: `32'h1A10_8000` ~ `32'h1A10_8FFF`
   - Related RTL:
     - [rtl/includes/apb_bus.sv](/rtl/includes/apb_bus.sv)

 - `axi_slv`: AXI4 slave
   - Memory map: `32'h1A12_0000` ~ `32'h1A13_FFFF`

 - `axi_mstr`: AXI4 master
   - Used to access memory space

 - `upio_*`: User Plugin IO<br>
             These signals are connected to IO pads.
   - `upio_in_i`: Inputs from IO pads
   - `upio_out_o`: Outputs to IO pads
   - `upio_dir_o`: Outputs control to IO pads
     - `0`: Corresponding IO pad is input only
     - `1`: Corresponding IO pad is both intput and output

 - `int_o`: Interruption output to CPU core


## Demos

Two simple demos have been implemented to show essential features.

### APB User Plugin

#### Hierarchy

- [user_plugin](/rtl/user_plugin/rtl/user_plugin.sv)
  - [apb_up](/rtl/user_plugin/rtl/apb_up.sv)


#### Features

- Peripheral registers reading/writing via APB slave
- Simple data processing
- Interruption control
- User plugin IO (UPIO) control


#### Software

- Headers
  - [apb_up.h](/sw/libs/sys_lib/inc/user_plugin/apb.h)

- Apps
  - [apb_up_test](/sw/apps/user_plugin_tests/apb_up_test)
    - Demo features
      - Registers reading/writing
      - Simple data processing
      - Interruption control
  - [upio_test](/sw/apps/user_plugin_tests/upio_test)
    - Demo features
      - Registers reading/writing
      - IO pad reading/writing
      - IO pad input/output control


#### Run Demos

```sh
cd pulpino/build
make apb_up_test.vsim
make upio_test.vsim
```


### AXI User Plugin

#### Hierarchy

- [user_plugin](/rtl/user_plugin/rtl/user_plugin.sv)
  - [axi_up](/rtl/user_plugin/rtl/axi_up.sv)


#### Features

- Simple peripheral registers reading/writing by word via AXI slave
- Simple data processing
  - Read word from memory directly via AXI master
  - Process read data
  - Write processed word to memory directly via AXI master
- Interruption control


#### Software

- Headers
  - [axi_up.h](/sw/libs/sys_lib/inc/user_plugin/axi.h)

- Apps
  - [axi_up_test](/sw/apps/user_plugin_tests/axi_up_test)
    - Demo features (same as AXI User Pulgin features)


## How to Integrate User's Logic via User Plugin

### RTL

An user is free to implement his/her logic with given `user_plugin` interface. Including but not limited to
- Keep `user_plugin` module/port unchanged
- Modify/remove any file under `rtl/user_plugin`
- Execute [`make vcompile`](/SIM.md) after RTL change 

### Software

An user is free to implement his/her software by either modifying an existing one or adding a new one.

#### How to Add an User's Test

Assume the user's test directory is called `user_test`

1. Make directory for the new test
   ```sh
   cd sw/apps/user_plugin_tests
   mkdir user_test
   ```

1. Add sources (assume only `main.c` is added)
   ```sh
   touch main.c
   # Edit main.c with your favourite editor.
   ```
   More than one source files can be added.

1. Create and edit `CMakeLists.txt` under `user_test` directory
   ```sh
   touch CMakeLists.txt
   # Edit CMakeLists.txt with your favourite editor.
   ```

   The content of `CMakeLists.txt` is like
   ```cmake
   add_application(user_test main.c LABELS "up_tests" TB_TEST "USER_TEST")
   ```

   - `user_test` is the application name. It can be any string, as long as it is not conflict with other application names.
   - `main.c` is the source file. If there are more than one source files, write all of them here.
   - `up_tests` is the label. To be consistent with other tests under `user_plugin_tests` just use `up_tests`.
   - `USER_TEST` is the test name. It can be any string, as long as it is not conflict with other tests names.

1. Add the test to the cmake system

   Add
   ```cmake
   add_subdirectory(user_test)
   ```
   to the last of `sw/apps/user_plugin_tests/CMakeLists.txt`

1. Execute [`cmake_configure.gcc.sh`](/SIM.md) with proper operands

1. Run the `user_test` only
   ```sh
   cd build
   make user_test.vsim
   ```
