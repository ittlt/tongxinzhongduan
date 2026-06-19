# ============================================================
# build_and_flash.tcl
# 综合、实现、生成比特流、导出硬件、烧录 Flash
# 用法：在 Vivado TCL Console 中执行
#   source D:/FPGAmoudle/--main/--main/vivado_project/build_and_flash.tcl
# ============================================================

set proj_dir [file dirname [info script]]
set proj_xpr [glob -directory $proj_dir *.xpr]
if {[llength $proj_xpr] == 0} {
    puts "ERROR: 未找到 .xpr 工程文件"
    return
}
set proj_xpr [lindex $proj_xpr 0]

# 输出路径
set xsa_out [file join $proj_dir DDS_Signal_Generator_wrapper.xsa]
set bit_out [file join $proj_dir DDS_Signal_Generator.runs impl_1 DDS_Signal_Generator_top.bit]
set bin_out [file join $proj_dir BOOT.BIN]

puts "INFO: ============================================================"
puts "INFO: Phase 1: 综合"
puts "INFO: ============================================================"
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    puts "ERROR: 综合失败！"
    return
}
puts "INFO: 综合完成"

puts "INFO: ============================================================"
puts "INFO: Phase 2: 实现 + 生成比特流"
puts "INFO: ============================================================"
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!"} {
    puts "ERROR: 实现失败！"
    return
}
puts "INFO: 实现完成，比特流已生成"

puts "INFO: ============================================================"
puts "INFO: Phase 3: 导出硬件到 XSA"
puts "INFO: ============================================================"
write_hw_platform -fixed -include_bit -force -file $xsa_out
puts "INFO: 硬件平台已导出到: $xsa_out"

puts "INFO: ============================================================"
puts "INFO: Phase 4: 烧录 Flash（通过 Vivado Hardware Manager）"
puts "INFO: ============================================================"
puts "INFO: 请按以下步骤手动操作："
puts "INFO:   1. 在 Vivado 中打开 Hardware Manager"
puts "INFO:   2. Auto Connect 连接到开发板"
puts "INFO:   3. 右键 Flash > Program Flash"
puts "INFO:   4. 选择 BOOT.BIN 文件"
puts "INFO:   5. Flash Type: qspi_single_x4"
puts "INFO:   6. Offset: 0x0"
puts "INFO:   7. 点击 Program"
puts "INFO: ============================================================"
puts "INFO: 完成后断开 JTAG，重新上电验证启动"
puts "INFO: ============================================================"
