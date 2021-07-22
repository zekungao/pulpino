
if (NOT DEFINED MEMLOAD)
  message(FATAL_ERROR "MEMLOAD not defined. It must be defined." )
endif()

if (NOT "${MEMLOAD}" STREQUAL "STANDALONE")
  add_application(SPI_test SPI_test.cpp LABELS "arduino" TB_TEST "ARDUINO_SPI")
else()
  message("SPI_test conflicts with flash boot (both use cs0), and it is disabled on standalone boot (when MEMLOAD==STANDALONE)")
endif()
