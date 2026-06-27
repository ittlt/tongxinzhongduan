vlib work
vlib riviera

vlib riviera/xilinx_vip
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xilinx_vip riviera/xilinx_vip
vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xilinx_vip  -sv2k12 "+incdir+D:/tools/vivado/2019.2/data/xilinx_vip/include" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"D:/tools/vivado/2019.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../DDS_Signal_Generator.srcs/sources_1/ip/pll_50m_to_100m_3" "+incdir+D:/tools/vivado/2019.2/data/xilinx_vip/include" \
"D:/tools/vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93 \
"D:/tools/vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

