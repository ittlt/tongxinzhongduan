# full_build.tcl
# Complete flow: Add sources → Create PS BD → Synthesize → Implement → Bitstream → Export XSA
# Run: vivado -mode batch -source full_build.tcl

set start_time [clock seconds]
puts "=========================================="
puts "DDS Signal Generator - Full Build"
puts "Start: [clock format $start_time]"
puts "=========================================="

# Open the existing project
if {[catch {current_project}]} {
    puts "INFO: No project open"
} else {
    close_project
    puts "INFO: Closed existing project"
}
open_project DDS_Signal_Generator.xpr

# ==================== STEP 1: Add new RTL sources ====================
puts "\n===== STEP 1: Adding RTL sources ====="

# Check if new top wrapper already exists in project
set top_exists [llength [get_files -of_objects [get_filesets sources_1] DDS_Signal_Generator_top.v]]
if {$top_exists == 0} {
    add_files -norecurse "D:/FPGAmoudle/--main/--main/rtl/DDS_Signal_Generator_top.v"
    puts "INFO: Added DDS_Signal_Generator_top.v"
} else {
    puts "INFO: DDS_Signal_Generator_top.v already in project"
}

# Check if new DDS_Signal_Generator.v already exists
set dds_exists [llength [get_files -of_objects [get_filesets sources_1] DDS_Signal_Generator.v]]
if {$dds_exists == 0} {
    add_files -norecurse "D:/FPGAmoudle/--main/--main/rtl/DDS_Signal_Generator.v"
    puts "INFO: Added DDS_Signal_Generator.v"
} else {
    puts "INFO: DDS_Signal_Generator.v already in project"
}

# Remove old sim version if present
set old_sim [get_files -of_objects [get_filesets sources_1] DDS_Signal_Generator_sim.v]
if {[llength $old_sim] > 0} {
    remove_files $old_sim
    puts "INFO: Removed old DDS_Signal_Generator_sim.v"
}

update_compile_order -fileset sources_1

# ==================== STEP 1b: Add PLL IP ====================
puts "\n===== STEP 1b: Adding PLL IP ====="

# Check if PLL IP XCI exists
set pll_xci "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.srcs/sources_1/ip/pll_50m_to_100m/pll_50m_to_100m.xci"
if {[file exists $pll_xci]} {
    puts "INFO: PLL IP already exists"
} else {
    puts "INFO: PLL IP not found, creating..."
    source -notrace "D:/FPGAmoudle/--main/--main/vivado_project/add_pll_ip.tcl"
    add_files -norecurse [get_files pll_50m_to_100m.xci]
    update_compile_order -fileset sources_1
}

# ==================== STEP 2: Create PS Block Design ====================
puts "\n===== STEP 2: Creating PS Block Design ====="

# Always recreate BD (old one may be corrupted)
source -notrace "D:/FPGAmoudle/--main/--main/vivado_project/create_ps_bd.tcl"

# Regenerate HDL wrapper
puts "INFO: Regenerating HDL wrapper..."
set bd_wrapper [get_files -of_objects [get_filesets sources_1] zynq_ps_wrapper.v]
if {[llength $bd_wrapper] > 0} {
    remove_files $bd_wrapper
}
set wrapper_file [make_wrapper -files [get_files zynq_ps.bd] -top]
add_files -norecurse $wrapper_file
update_compile_order -fileset sources_1

# ==================== STEP 3: Validate and save ====================
puts "\n===== STEP 3: Validating design ====="

# Validate and save the BD
current_bd_design zynq_ps
validate_bd_design
save_bd_design

# Set top module
set_property top DDS_Signal_Generator_top [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: Top module set to DDS_Signal_Generator_top"

# ==================== STEP 4: Update XDC ====================
puts "\n===== STEP 4: Updating XDC constraints ====="

set xdc_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.srcs/constrs_1/new/DDS_Signal_Generator.xdc"
if {[file exists $xdc_file]} {
    set fp [open $xdc_file "r"]
    set xdc_content [read $fp]
    close $fp
    if {[string match "*clk_50mhz*" $xdc_content]} {
        puts "INFO: Removing old clk_50mhz pin constraint..."
        set new_xdc ""
        foreach line [split $xdc_content "\n"] {
            if {[string match "*clk_50mhz*" $line] || [string match "*rst_n*" $line]} {
                continue
            }
            append new_xdc $line "\n"
        }
        set fp [open $xdc_file "w"]
        puts $fp $new_xdc
        close $fp
        puts "INFO: XDC updated"
    } else {
        puts "INFO: XDC already updated"
    }
}

# ==================== STEP 5: Synthesis ====================
puts "\n===== STEP 5: Running Synthesis ====="
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"
if {[string match "*ERROR*" $synth_status]} {
    puts "ERROR: Synthesis failed!"
    close_project
    exit 1
}

# ==================== STEP 6: Implementation ====================
puts "\n===== STEP 6: Running Implementation ====="
launch_runs impl_1 -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"
if {[string match "*ERROR*" $impl_status]} {
    puts "ERROR: Implementation failed!"
    close_project
    exit 1
}

# ==================== STEP 7: Generate Bitstream ====================
puts "\n===== STEP 7: Generating Bitstream ====="
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Check for bitstream
set bit_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.runs/impl_1/DDS_Signal_Generator_top.bit"
if {[file exists $bit_file]} {
    puts "INFO: Bitstream generated: $bit_file"
} else {
    set alt_bit "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.runs/impl_1/DDS_Signal_Generator.bit"
    if {[file exists $alt_bit]} {
        puts "INFO: Bitstream generated (alt name): $alt_bit"
    } else {
        puts "WARNING: Bitstream file not found with expected names"
    }
}

# ==================== STEP 8: Export XSA ====================
puts "\n===== STEP 8: Exporting XSA ====="
set xsa_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator_wrapper.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_file

if {[file exists $xsa_file]} {
    puts "INFO: XSA exported successfully!"
    set xsa_size [file size $xsa_file]
    puts "INFO: XSA file size: $xsa_size bytes"
} else {
    puts "ERROR: XSA export failed!"
    close_project
    exit 1
}

close_project

set end_time [clock seconds]
set elapsed [expr {$end_time - $start_time}]
puts "\n=========================================="
puts "DONE! Total time: ${elapsed} seconds"
puts "Bitstream: $bit_file"
puts "XSA: $xsa_file"
puts "=========================================="
exit
