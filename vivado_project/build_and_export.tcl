# build_and_export.tcl
# Complete flow: Synthesize → Implement → Bitstream → Export XSA
# Run: vivado -mode batch -source build_and_export.tcl

set start_time [clock seconds]
puts "=========================================="
puts "DDS Signal Generator - Build & Export XSA"
puts "Start: [clock format $start_time]"
puts "=========================================="

open_project DDS_Signal_Generator.xpr

# Check current state
puts "INFO: Part: [get_property PART [current_project]]"
puts "INFO: Top module: [get_property TOP [current_fileset]]"

# Update compile order
update_compile_order -fileset sources_1

# Launch Synthesis
puts "\n===== STEP 1: Synthesis ====="
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

# Launch Implementation
puts "\n===== STEP 2: Implementation ====="
launch_runs impl_1 -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"
if {[string match "*ERROR*" $impl_status]} {
    puts "ERROR: Implementation failed!"
    close_project
    exit 1
}

# Generate Bitstream
puts "\n===== STEP 3: Generate Bitstream ====="
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

set bit_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.runs/impl_1/DDS_Signal_Generator_top.bit"
if {[file exists $bit_file]} {
    puts "INFO: Bitstream generated: $bit_file"
} else {
    puts "ERROR: Bitstream not found!"
    close_project
    exit 1
}

# Export XSA
puts "\n===== STEP 4: Export XSA ====="
set xsa_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator_wrapper.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_file

if {[file exists $xsa_file]} {
    puts "INFO: XSA exported: $xsa_file"
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
