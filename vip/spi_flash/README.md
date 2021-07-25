The verilog model of the W25Q16JV flash is proprietary code of Winbond Electronics Corporation, which can currently be downloaded from here:
[W25Q16JV Verilog Model](https://www.winbond.com/hq/support/documentation/?__locale=en&line=%2Fproduct%2Fcode-storage-flash-memory%2Findex.html&family=%2Fproduct%2Fcode-storage-flash-memory%2Fserial-nor-flash%2Findex.html&category=%2F.categories%2Fresources%2Fverilog-model%2F&pno=W25Q16JV)

Once the model has been downloaded, put file w25q16jv.v to the w25q16jv directory.

To activate the model
1. Set parameter `USE_W25Q16JV_MODEL` to 1 in [tb/tb_chip_top.sv](/tb/tb_chip_top.sv)
1. Execute `make vcompile` to compile RTL mentioned by [simulation document](/SIM.md)

When the SPI flash is active, it is possible to use it for a more realistic boot simulation, where the PULPino chip boots from boot ROM and then 
fetches its own program from the flash drive.
