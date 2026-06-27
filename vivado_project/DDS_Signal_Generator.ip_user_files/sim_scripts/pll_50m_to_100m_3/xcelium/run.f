-makelib xcelium_lib/xilinx_vip -sv \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "D:/tools/vivado/2019.2/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib xcelium_lib/xpm -sv \
  "D:/tools/vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/tools/vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

