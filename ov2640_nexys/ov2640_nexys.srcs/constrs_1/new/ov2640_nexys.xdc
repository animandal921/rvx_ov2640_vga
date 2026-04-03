## Clock signal
## Pin E3 is the 100MHz system clock
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Reset (Mapped to Switch 0 - Pin U9)
set_property PACKAGE_PIN U9 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
##filter_en SW1
set_property PACKAGE_PIN U8 [get_ports filter_en]
set_property IOSTANDARD LVCMOS33 [get_ports filter_en]

##uart send en SW2
set_property PACKAGE_PIN R7 [get_ports send_en]
set_property IOSTANDARD LVCMOS33 [get_ports send_en]

set_property IOSTANDARD LVCMOS33 [get_ports uart_txd]
set_property PACKAGE_PIN D4 [get_ports uart_txd] ; # Mapped to UART_RXD_OUT

## --------------------------------------------------------
## VGA INTERFACE
## --------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {red_out[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {green_out[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue_out[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[*]}]
## Red Channel
set_property PACKAGE_PIN A3 [get_ports {red_out[0]}]
set_property PACKAGE_PIN B4 [get_ports {red_out[1]}]
set_property PACKAGE_PIN C5 [get_ports {red_out[2]}]
set_property PACKAGE_PIN A4 [get_ports {red_out[3]}]

## Green Channel
set_property PACKAGE_PIN C6 [get_ports {green_out[0]}]
set_property PACKAGE_PIN A5 [get_ports {green_out[1]}]
set_property PACKAGE_PIN B6 [get_ports {green_out[2]}]
set_property PACKAGE_PIN A6 [get_ports {green_out[3]}]

## Blue Channel
set_property PACKAGE_PIN B7 [get_ports {blue_out[0]}]
set_property PACKAGE_PIN C7 [get_ports {blue_out[1]}]
set_property PACKAGE_PIN D7 [get_ports {blue_out[2]}]
set_property PACKAGE_PIN D8 [get_ports {blue_out[3]}]

## Sync Signals
## Mapping x_valid to HSYNC and y_valid to VSYNC based on standard VGA port usage
set_property PACKAGE_PIN B11 [get_ports x_valid]
set_property PACKAGE_PIN B12 [get_ports y_valid]

set_property IOSTANDARD LVCMOS33 [get_ports x_valid]
set_property IOSTANDARD LVCMOS33 [get_ports y_valid]

## --------------------------------------------------------
## CAMERA INTERFACE
## Data -> Header JA
## Control -> Header JB
## --------------------------------------------------------

## Camera Data Bus (Mapped to Pmod JA)
set_property PACKAGE_PIN B13 [get_ports {camera_data[7]}];#1
set_property PACKAGE_PIN G13 [get_ports {camera_data[6]}];#7
set_property PACKAGE_PIN F14 [get_ports {camera_data[5]}];#2
set_property PACKAGE_PIN C17 [get_ports {camera_data[4]}];#8
set_property PACKAGE_PIN D17 [get_ports {camera_data[3]}];#3
set_property PACKAGE_PIN D18 [get_ports {camera_data[2]}];#9
set_property PACKAGE_PIN E17 [get_ports {camera_data[1]}];#4
set_property PACKAGE_PIN E18 [get_ports {camera_data[0]}];#10

## Camera Control Signals (Mapped to Pmod JB)
set_property PACKAGE_PIN G14 [get_ports sio_d];#1
set_property PACKAGE_PIN P15 [get_ports pclk];#2
set_property PACKAGE_PIN V11 [get_ports sio_c];#3
set_property PACKAGE_PIN V15 [get_ports vsync];#4
set_property PACKAGE_PIN K16 [get_ports href];#7
set_property PACKAGE_PIN R16 [get_ports xclk];#8
set_property PACKAGE_PIN T9 [get_ports pwdn];#9
set_property PACKAGE_PIN U11 [get_ports reset];#10

## IO Standards for CameraS
set_property IOSTANDARD LVCMOS33 [get_ports sio_d]
set_property IOSTANDARD LVCMOS33 [get_ports sio_c]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports href]
set_property IOSTANDARD LVCMOS33 [get_ports pclk]
set_property IOSTANDARD LVCMOS33 [get_ports xclk]
set_property IOSTANDARD LVCMOS33 [get_ports pwdn]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
create_clock -period 41.66666 -name pclk -waveform {0.000 20.833} [get_ports pclk]

set_clock_groups -name async_camera_vga -asynchronous \
    -group [get_clocks pclk] \
    -group [get_clocks clk_out1_clk_wiz_0]