# ============================================================
# flash_program.tcl
# 通过 XSCT 烧录 Flash（W25Q128JV）
# 用法：在命令行执行
#   xsct D:/FPGAmoudle/--main/--main/vivado_project/flash_program.tcl
# ============================================================

set proj_dir [file dirname [info script]]
set boot_bin [file join $proj_dir BOOT.BIN]

if {![file exists $boot_bin]} {
    puts "ERROR: BOOT.BIN 不存在: $boot_bin"
    puts "INFO: 请先完成以下步骤："
    puts "INFO:   1. 在 Vivado 中综合、实现、生成比特流"
    puts "INFO:   2. 导出硬件到 .xsa 文件"
    puts "INFO:   3. 在 Vitis 中创建 FSBL 工程并编译"
    puts "INFO:   4. 使用 bootgen 生成 BOOT.BIN"
    exit 1
}

puts "INFO: 连接到目标板..."
connect

puts "INFO: 查找目标设备..."
targets -filter {name =~ "ARM*"}

puts "INFO: 下载比特流（用于初始化 FPGA）..."
# 先通过 JTAG 下载比特流以初始化 FPGA
set bit_file [glob -directory [file join $proj_dir DDS_Signal_Generator.runs impl_1] *.bit]
if {[llength $bit_file] > 0} {
    set bit_file [lindex $bit_file 0]
    fpga -filter {name =~ "xc7z*"} $bit_file
    con
    after 2000
    stop
}

puts "INFO: 切换到 QSPI Flash 目标..."
targets -set -nocase -filter {name =~ "*QSPI*"}

puts "INFO: 自动检测 Flash..."
spi_flash -auto_detect

puts "INFO: 烧录 BOOT.BIN 到 Flash..."
program_flash -file $boot_bin -offset 0 -force

puts "INFO: ============================================================"
puts "INFO: Flash 烧录完成！"
puts "INFO: 请断开 JTAG，重新上电验证启动"
puts "INFO: ============================================================"
disconnect
exit
