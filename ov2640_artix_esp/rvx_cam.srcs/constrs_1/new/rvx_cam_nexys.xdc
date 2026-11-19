## ------------------------------------------------------------------------------
## Clock and Reset (Arty A7)
## ------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports clock]
set_property PACKAGE_PIN E3 [get_ports clock]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clock]

create_clock -period 41.66666 -name pclk -waveform {0.000 20.833} [get_ports pclk]

set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PACKAGE_PIN C2 [get_ports reset]

## ------------------------------------------------------------------------------
## Switches (SW0 = Cam En, SW1 = Filter En, SW2 = Res)
## ------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[2]}]

set_property PACKAGE_PIN A8  [get_ports {gpio[0]}]
set_property PACKAGE_PIN C11 [get_ports {gpio[1]}]
set_property PACKAGE_PIN C10 [get_ports {gpio[2]}]

## --------------------------------------------------------
## DIAGNOSTIC LEDS (Arty A7 Green LEDs LD4-LD7)
## --------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property PACKAGE_PIN H5  [get_ports {led[0]}] 
set_property PACKAGE_PIN J5  [get_ports {led[1]}] 
set_property PACKAGE_PIN T9  [get_ports {led[2]}] 
set_property PACKAGE_PIN T10 [get_ports {led[3]}] 

## --------------------------------------------------------
## PARALLEL BUS TO ESP32 (Arty Arduino Header IO0-IO10)
## --------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {out_data[*]}]
set_property PACKAGE_PIN V15 [get_ports {out_data[0]}] ;# IO0
set_property PACKAGE_PIN U16 [get_ports {out_data[1]}] ;# IO1
set_property PACKAGE_PIN P14 [get_ports {out_data[2]}] ;# IO2
set_property PACKAGE_PIN T11 [get_ports {out_data[3]}] ;# IO3
set_property PACKAGE_PIN R12 [get_ports {out_data[4]}] ;# IO4
set_property PACKAGE_PIN T14 [get_ports {out_data[5]}] ;# IO5
set_property PACKAGE_PIN T15 [get_ports {out_data[6]}] ;# IO6
set_property PACKAGE_PIN T16 [get_ports {out_data[7]}] ;# IO7

set_property IOSTANDARD LVCMOS33 [get_ports out_pclk]
set_property PACKAGE_PIN N15 [get_ports out_pclk]      ;# IO8

set_property IOSTANDARD LVCMOS33 [get_ports out_vsync]
set_property PACKAGE_PIN M16 [get_ports out_vsync]     ;# IO9

set_property IOSTANDARD LVCMOS33 [get_ports out_href]
set_property PACKAGE_PIN V17 [get_ports out_href]      ;# IO10

## --------------------------------------------------------
## PC UART (Unused but kept for RVX Core stability)
## --------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property PACKAGE_PIN D10 [get_ports uart_tx]

set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PACKAGE_PIN A9 [get_ports uart_rx]

## --------------------------------------------------------
## CAMERA INTERFACE (Mapped to Pmod JA & JB)
## --------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[*]}]
set_property PACKAGE_PIN G13 [get_ports {camera_data[7]}] ;# JA1
set_property PACKAGE_PIN B11 [get_ports {camera_data[6]}] ;# JA2
set_property PACKAGE_PIN A11 [get_ports {camera_data[5]}] ;# JA3
set_property PACKAGE_PIN D12 [get_ports {camera_data[4]}] ;# JA4
set_property PACKAGE_PIN D13 [get_ports {camera_data[3]}] ;# JA7
set_property PACKAGE_PIN B18 [get_ports {camera_data[2]}] ;# JA8
set_property PACKAGE_PIN A18 [get_ports {camera_data[1]}] ;# JA9
set_property PACKAGE_PIN K16 [get_ports {camera_data[0]}] ;# JA10

set_property IOSTANDARD LVCMOS33 [get_ports sio_d]
set_property IOSTANDARD LVCMOS33 [get_ports pclk]
set_property IOSTANDARD LVCMOS33 [get_ports sio_c]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports href]
set_property IOSTANDARD LVCMOS33 [get_ports xclk]
set_property IOSTANDARD LVCMOS33 [get_ports cam_pwdn]
set_property IOSTANDARD LVCMOS33 [get_ports cam_reset]

set_property PACKAGE_PIN E15 [get_ports sio_d]     ;# JB1
set_property PACKAGE_PIN E16 [get_ports pclk]      ;# JB2
set_property PACKAGE_PIN D15 [get_ports sio_c]     ;# JB3
set_property PACKAGE_PIN C15 [get_ports vsync]     ;# JB4
set_property PACKAGE_PIN J17 [get_ports href]      ;# JB7
set_property PACKAGE_PIN J18 [get_ports xclk]      ;# JB8
set_property PACKAGE_PIN K15 [get_ports cam_pwdn]  ;# JB9
set_property PACKAGE_PIN J15 [get_ports cam_reset] ;# JB10

## --------------------------------------------------------
## VGA INTERFACE (Disabled safely)
## --------------------------------------------------------
set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pclk_IBUF]