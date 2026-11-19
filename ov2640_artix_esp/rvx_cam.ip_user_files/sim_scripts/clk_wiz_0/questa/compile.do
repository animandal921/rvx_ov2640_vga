vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm -64 -incr -mfcu  -sv "+incdir+../../../../../../../../tools/Xilinx/2025.1/data/rsb/busdef" "+incdir+../../../../ov2640_nexys.gen/sources_1/ip/clk_wiz_0" \
"/tools/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/tools/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../../../../../tools/Xilinx/2025.1/data/rsb/busdef" "+incdir+../../../../ov2640_nexys.gen/sources_1/ip/clk_wiz_0" \
"../../../../ov2640_nexys.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_sim_netlist.v" \

vlog -work xil_defaultlib \
"glbl.v"

