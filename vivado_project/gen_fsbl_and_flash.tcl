# ============================================================
# gen_fsbl_and_flash.tcl
# 用 xsct 自动生成 FSBL + BOOT.BIN 并烧录 Flash
# 用法：xsct D:/FPGAmoudle/--main/--main/vivado_project/gen_fsbl_and_flash.tcl
# ============================================================

set proj_dir "D:/FPGAmoudle/--main/--main/vivado_project"
set xsa_file "$proj_dir/DDS_Signal_Generator_wrapper.xsa"
set bit_file "$proj_dir/DDS_Signal_Generator.runs/impl_1/DDS_Signal_Generator_top.bit"
set workspace "$proj_dir/vitis_workspace"
set boot_bin "$proj_dir/BOOT.BIN"

# 检查文件
if {![file exists $xsa_file]} {
    puts "ERROR: XSA 文件不存在: $xsa_file"
    exit 1
}
if {![file exists $bit_file]} {
    puts "ERROR: 比特流文件不存在: $bit_file"
    exit 1
}

puts "INFO: ============================================================"
puts "INFO: Phase 1: 创建 Vitis 工作空间和硬件平台"
puts "INFO: ============================================================"

# 设置工作空间
setws $workspace

# 从 XSA 导入硬件平台
platform create -name "hw_platform" -hw $xsa_file
platform generate

puts "INFO: 硬件平台生成完成"

puts "INFO: ============================================================"
puts "INFO: Phase 2: 生成 FSBL"
puts "INFO: ============================================================"

# 创建 FSBL 应用工程
app create -name "fsbl" -hw hw_platform -proc ps7_cortexa9_0 -os standalone -lang c -template "Zynq FSBL"

# 生成 BSP（包含 xilffs 和 qspips 驱动）
bsp regenerate

puts "INFO: FSBL 工程创建完成，正在编译..."

# 编译 FSBL
app build -name "fsbl"

puts "INFO: FSBL 编译完成"

puts "INFO: ============================================================"
puts "INFO: Phase 3: 生成 BOOT.BIN"
puts "INFO: ============================================================"

# 查找生成的 fsbl.elf
set fsbl_elf "$workspace/fsbl/Debug/fsbl.elf"
if {![file exists $fsbl_elf]} {
    puts "ERROR: fsbl.elf 不存在: $fsbl_elf"
    # 尝试查找
    set fsbl_elf [glob -nocomplain "$workspace/fsbl/*/fsbl.elf"]
    if {$fsbl_elf eq ""} {
        puts "ERROR: 找不到 fsbl.elf"
        exit 1
    }
    set fsbl_elf [lindex $fsbl_elf 0]
}
puts "INFO: FSBL ELF: $fsbl_elf"

# 使用 bootgen 生成 BOOT.BIN
# 先创建 BIF 文件
set bif_file "$proj_dir/boot_auto.bif"
set fh [open $bif_file w]
puts $fh "the_ROM_image:"
puts $fh "\{"
puts $fh "    \[bootloader\] $fsbl_elf"
puts $fh "    $bit_file"
puts $fh "\}"
close $fh

puts "INFO: BIF 文件已生成: $bif_file"

# 调用 bootgen
set bootgen "D:/tools/Vitis/2019.2/bin/bootgen"
if {[file exists "$bootgen.bat"]} {
    set bootgen "D:/tools/Vitis/2019.2/bin/bootgen.bat"
}

puts "INFO: 调用 bootgen 生成 BOOT.BIN..."
set cmd "exec $bootgen -w -arch zynq -o $boot_bin -bif $bif_file"
puts "INFO: CMD: $cmd"
if {[catch {eval $cmd} result]} {
    puts "ERROR: bootgen 失败: $result"
    exit 1
}

if {![file exists $boot_bin]} {
    puts "ERROR: BOOT.BIN 未生成"
    exit 1
}

puts "INFO: BOOT.BIN 生成成功: $boot_bin"

puts "INFO: ============================================================"
puts "INFO: Phase 4: 烧录 Flash"
puts "INFO: ============================================================"

# 连接到板子
connect

# 查找 Zynq 目标
set targets_list [targets -filter {name =~ "xc7z*"}]
if {[llength $targets_list] == 0} {
    puts "ERROR: 未找到 Zynq 目标"
    disconnect
    exit 1
}

# 先下载比特流以初始化 FPGA
fpga -filter {name =~ "xc7z*"} $bit_file
con
after 2000
stop

# 切换到 QSPI Flash 目标
targets -set -nocase -filter {name =~ "*QSPI*"}

# 自动检测 Flash
spi_flash -auto_detect

# 烧录 BOOT.BIN
puts "INFO: 开始烧录 Flash..."
program_flash -file $boot_bin -offset 0 -force

puts "INFO: ============================================================"
puts "INFO: 全部完成！"
puts "INFO: BOOT.BIN 已烧录到 QSPI Flash"
puts "INFO: 请断开 JTAG，重新上电验证启动"
puts "INFO: ============================================================"

disconnect
exit
