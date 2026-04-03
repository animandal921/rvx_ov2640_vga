transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../../../../../../tools/Xilinx/2025.1/data/rsb/busdef" "+incdir+../../../../ov2640_nexys.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"/tools/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/tools/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../../../../../tools/Xilinx/2025.1/data/rsb/busdef" "+incdir+../../../../ov2640_nexys.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"../../../../ov2640_nexys.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_sim_netlist.v" \

vlog -work xil_defaultlib \
"glbl.v"

