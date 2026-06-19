# flash_vivado.tcl
# 用 Vivado Hardware Manager 烧录 Flash
# 在 Vivado TCL Console 中执行：
#   source D:/FPGAmoudle/--main/--main/vivado_project/flash_vivado.tcl

set boot_bin "D:/FPGAmoudle/--main/--main/vivado_project/BOOT.BIN"

if {![file exists $boot_bin]} {
    puts "ERROR: BOOT.BIN not found: $boot_bin"
    exit 1
}

open_hw_manager
connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target

# 查找 FPGA 设备
set hw_dev [lindex [get_hw_devices xc7z*] 0]
current_hw_device $hw_dev

# 设置 Flash 类型为 W25Q128JV
create_hw_cfgmem -hw_device $hw_dev -mem_dev [lindex [get_cfgmem_parts {w25q128jv-spi_x1_x2_x4}] 0]
set cfgmem [get_property PROGRAM.HW_CFGMEM $hw_dev]

# 配置编程参数
set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
set_property PROGRAM.FILES [list $boot_bin] $cfgmem
set_property PROGRAM.UNUSED_PIN {pullnone} $cfgmem
set_property PROGRAM.BLANK_CHECK 0 $cfgmem
set_property PROGRAM.ERASE 1 $cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
set_property PROGRAM.VERIFY 1 $cfgmem
set_property PROGRAM.CHECKSUM 0 $cfgmem

# 执行编程
program_hw_cfgmem -hw_cfgmem $cfgmem

puts "INFO: Flash programming complete!"
puts "INFO: Disconnect JTAG and power cycle to verify boot."

disconnect_hw_server
close_hw_manager
