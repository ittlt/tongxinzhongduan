# ============================================================
# create_ps_bd.tcl
# 在已有 Vivado 工程中创建 PS Block Design 并配置 PS7
# 用法：在 Vivado TCL Console 中执行
#   source D:/FPGAmoudle/--main/--main/vivado_project/create_ps_bd.tcl
# ============================================================

# 获取工程路径
set proj_dir [file dirname [info script]]
set proj_xpr [glob -directory $proj_dir *.xpr]
if {[llength $proj_xpr] == 0} {
    puts "ERROR: 未找到 .xpr 工程文件"
    return
}
set proj_xpr [lindex $proj_xpr 0]
puts "INFO: 打开工程 $proj_xpr"

# ============================================================
# Phase 1: 创建 Block Design
# ============================================================
puts "INFO: 创建 Block Design 'zynq_ps'"
create_bd_design "zynq_ps"

# 添加 PS7 IP
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# 自动连接 DDR 和 FIXED_IO 到外部端口
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR"} [get_bd_cells ps7]

# ============================================================
# Phase 2: 配置 PS7
# ============================================================
puts "INFO: 配置 PS7 参数"

# --- QSPI Flash 控制器 (W25Q128JV, 16MB, Quad-SPI) ---
puts "INFO: 使能 QSPI Flash 控制器"
set_property -dict [list \
    CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
    CONFIG.PCW_QSPI_GROUP_IO0 {MIO 0 .. 5} \
    CONFIG.PCW_QSPI_GRP_IO1_ENABLE {1} \
    CONFIG.PCW_QSPI_GRP_IO1_IO {MIO 6 .. 11} \
    CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {0} \
    CONFIG.PCW_QSPI_GRP_SS_ENABLE {0} \
    CONFIG.PCW_QSPI_PERIPHERAL_DATA_IO_WIDTH {4} \
    CONFIG.PCW_QSPI_PERIPHERAL_BOARD_MAX_SCLK_FREQ {200} \
    CONFIG.PCW_QSPI_PERIPHERAL_BOARD_MIN_SCLK_FREQ {22.222222} \
] [get_bd_cells ps7]

# --- 使能 QSPI 驱动所需的 BSP 设置 ---
puts "INFO: 配置 BSP 驱动（QSPI + xilffs）"
set_property -dict [list \
    CONFIG.PCW_USE_S_AXI_HP0 {0} \
    CONFIG.PCW_USE_M_AXI_GP0 {0} \
] [get_bd_cells ps7]

# --- DDR3 内存控制器 (1GB, 2x DDR3, 32-bit总线) ---
puts "INFO: 配置 DDR3 内存控制器 (1GB)"
set_property -dict [list \
    CONFIG.PCW_DDR_MEMORY_TYPE {DDR 3} \
    CONFIG.PCW_DDR_DEVICE_WIDTH {16} \
    CONFIG.PCW_DDR_RAM_WIDTH {32} \
    CONFIG.PCW_DDR_MEMORY_PART {MT41K256M16 RE-125} \
    CONFIG.PCW_DDR_SPEED_BIN {DDR3_1066F} \
    CONFIG.PCW_DDR_RAM_DDR3_ROWADDR_COUNT {15} \
    CONFIG.PCW_DDR_RAM_DDR3_COLADDR_COUNT {10} \
    CONFIG.PCW_DDR_RAM_DDR3_BANKS {4} \
    CONFIG.PCW_DDR_RAM_DDR3_T_FAW {40.0} \
    CONFIG.PCW_DDR_RAM_DDR3_RAS_ROW_COUNT {13} \
    CONFIG.PCW_DDR_RAM_DDR3_RASCAS_DELAY {7} \
    CONFIG.PCW_DDR_RAM_DDR3_TRC {48.75} \
    CONFIG.PCW_DDR_RAM_DDR3_TMRD {4} \
    CONFIG.PCW_DDR_RAM_DDR3_TMSTAB {5.0} \
    CONFIG.PCW_DDR_RAM_DDR3_TREFI {7.8} \
    CONFIG.PCW_DDR_RAM_DDR3_TRP {13.125} \
    CONFIG.PCW_DDR_RAM_DDR3_TXPR {48.75} \
] [get_bd_cells ps7]

# --- PL 时钟 FCLK_CLK0 = 50MHz ---
puts "INFO: 配置 FCLK_CLK0 = 50MHz"
set_property -dict [list \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
    CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
    CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
    CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
] [get_bd_cells ps7]

# --- 连接 AXI GP0 时钟（连到 FCLK_CLK0）---
puts "INFO: 连接 M_AXI_GP0_ACLK 到 FCLK_CLK0"
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins ps7/M_AXI_GP0_ACLK]

# --- 手动创建 FCLK_CLK0 和 FCLK_RESET0_N 外部端口 ---
puts "INFO: 创建 FCLK_CLK0 和 FCLK_RESET0_N 外部端口"
# 注意：BD 端口名会自动加 _0 后缀，wrapper 中实际端口名为 FCLK_CLK0_0 和 FCLK_RESET0_N_0
create_bd_port -type clk -dir O FCLK_CLK0_0
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_ports FCLK_CLK0_0]
create_bd_port -type rst -dir O FCLK_RESET0_N_0
connect_bd_net [get_bd_pins ps7/FCLK_RESET0_N] [get_bd_ports FCLK_RESET0_N_0]

# ============================================================
# Phase 3: 生成并验证
# ============================================================
puts "INFO: 重新生成 Block Design 布局"
regenerate_bd_layout

puts "INFO: 验证 Block Design"
validate_bd_design

puts "INFO: 保存 Block Design"
save_bd_design

# ============================================================
# Phase 4: 生成 HDL Wrapper
# ============================================================
puts "INFO: 生成 HDL Wrapper"
set wrapper_file [make_wrapper -files [get_files zynq_ps.bd] -top]
add_files -norecurse $wrapper_file
update_compile_order -fileset sources_1

# ============================================================
# Phase 5: 设置新顶层模块
# ============================================================
puts "INFO: 设置顶层模块为 DDS_Signal_Generator_top"
set_property top DDS_Signal_Generator_top [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: ============================================================"
puts "INFO: Block Design 创建完成！"
puts "INFO: ============================================================"
puts "INFO: 下一步："
puts "INFO:   1. 检查 Block Design 是否正确（Sources > Block Designs > zynq_ps）"
puts "INFO:   2. 确认 DDR3 时序参数是否匹配板上芯片"
puts "INFO:   3. 运行综合：reset_run synth_1; launch_runs synth_1 -jobs 4; wait_on_run synth_1"
puts "INFO:   4. 运行实现：launch_runs impl_1 -to_step write_bitstream; wait_on_run impl_1"
puts "INFO:   5. 导出硬件：write_hw_platform -fixed -include_bit -force -file <输出路径>.xsa"
puts "INFO: ============================================================"
