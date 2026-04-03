##------------------------------------------------------------------------------
## Clock Signal
## The Nexys 4 board provides a 100 MHz clock on pin E3.
## The 10.000 ns period correctly defines this 100 MHz frequency (1/10ns = 100MHz).
##------------------------------------------------------------------------------
create_clock -period 10.000 -name clock -waveform {0.000 5.000} [get_ports clock]
set_property IOSTANDARD LVCMOS33 [get_ports clock]
set_property PACKAGE_PIN E3 [get_ports clock]

create_clock -period 41.66666 -name pclk -waveform {0.000 20.833} [get_ports pclk]

##------------------------------------------------------------------------------
## Generated Clock (Internal Logic)
## This is a logical constraint creating a 50 MHz clock from the 100 MHz input.
##------------------------------------------------------------------------------
create_generated_clock -name clkdiv2 -source [get_pins clock_50mhz_reg/C] -divide_by 2 [get_pins clock_50mhz_reg/Q]

## --------------------------------------------------------
## TIMING EXCEPTIONS (Clock Domain Crossings)
## --------------------------------------------------------
# 1. Isolate the Camera, VGA, and System Clocks from each other
set_clock_groups -name async_camera_vga -asynchronous \
    -group [get_clocks pclk] \
    -group [get_clocks clk_out2_clk_wiz_0]

# 2. Hard-kill the reset routing violations
set_false_path -from [get_clocks clkdiv2] -to [get_clocks pclk]
set_false_path -from [get_clocks clkdiv2] -to [get_clocks clk_out2_clk_wiz_0]

# 3. Tell Vivado to ignore timing from the CPU's 50MHz config registers 
# crossing over into the camera's 24MHz/25MHz clock domains.
set_false_path -from [get_cells rvx_instance/cam_enable_reg_reg]
set_false_path -from [get_cells rvx_instance/filter_enable_reg_reg]
set_false_path -from [get_cells rvx_instance/resolution_reg_reg]


##------------------------------------------------------------------------------
## Reset Signal
## Mapped to C12 (CPU_RESETN push button on the Nexys 4). Active-low.
##------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PACKAGE_PIN C12 [get_ports reset]


##------------------------------------------------------------------------------
## UART Transmit (TX) & Receive (RX)
##------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property PACKAGE_PIN D4 [get_ports uart_tx] 

set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PACKAGE_PIN C4 [get_ports uart_rx] 

##------------------------------------------------------------------------------
## Switches (SW0, SW1, SW2)
##------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports gpio[0]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[1]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[2]]

set_property PACKAGE_PIN U9 [get_ports gpio[0]]
set_property PACKAGE_PIN U8 [get_ports gpio[1]]
set_property PACKAGE_PIN R7 [get_ports gpio[2]]

## --------------------------------------------------------
## VGA INTERFACE
## --------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]

## Red Channel
set_property PACKAGE_PIN A3 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN B4 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN C5 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN A4 [get_ports {vga_r[3]}]

## Green Channel
set_property PACKAGE_PIN C6 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN A5 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN B6 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN A6 [get_ports {vga_g[3]}]

## Blue Channel
set_property PACKAGE_PIN B7 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN C7 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN D7 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN D8 [get_ports {vga_b[3]}]

## Sync Signals
set_property IOSTANDARD LVCMOS33 [get_ports vga_x_valid]
set_property IOSTANDARD LVCMOS33 [get_ports vga_y_valid]

set_property PACKAGE_PIN B11 [get_ports vga_x_valid]
set_property PACKAGE_PIN B12 [get_ports vga_y_valid]

## --------------------------------------------------------
## CAMERA INTERFACE
## Data -> Header JA
## Control -> Header JB
## --------------------------------------------------------

## Camera Data Bus (Mapped to Pmod JA)
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[*]}]

set_property PACKAGE_PIN B13 [get_ports {camera_data[7]}]
set_property PACKAGE_PIN G13 [get_ports {camera_data[6]}]
set_property PACKAGE_PIN F14 [get_ports {camera_data[5]}]
set_property PACKAGE_PIN C17 [get_ports {camera_data[4]}]
set_property PACKAGE_PIN D17 [get_ports {camera_data[3]}]
set_property PACKAGE_PIN D18 [get_ports {camera_data[2]}]
set_property PACKAGE_PIN E17 [get_ports {camera_data[1]}]
set_property PACKAGE_PIN E18 [get_ports {camera_data[0]}]

## Camera Control Signals (Mapped to Pmod JB)
set_property IOSTANDARD LVCMOS33 [get_ports sio_d]
set_property IOSTANDARD LVCMOS33 [get_ports pclk]
set_property IOSTANDARD LVCMOS33 [get_ports sio_c]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports href]
set_property IOSTANDARD LVCMOS33 [get_ports xclk]
set_property IOSTANDARD LVCMOS33 [get_ports cam_pwdn]
set_property IOSTANDARD LVCMOS33 [get_ports cam_reset]

set_property PACKAGE_PIN G14 [get_ports sio_d]
set_property PACKAGE_PIN P15 [get_ports pclk]
set_property PACKAGE_PIN V11 [get_ports sio_c]
set_property PACKAGE_PIN V15 [get_ports vsync]
set_property PACKAGE_PIN K16 [get_ports href]
set_property PACKAGE_PIN R16 [get_ports xclk]
set_property PACKAGE_PIN T9  [get_ports cam_pwdn]
set_property PACKAGE_PIN U11 [get_ports cam_reset]

##------------------------------------------------------------------------------
## Configuration Settings
## These settings are standard for the Artix-7 FPGA on the Nexys 4.
##------------------------------------------------------------------------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]