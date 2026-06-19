# gen_xsa.tcl - Regenerate XSA hardware export
# Run: vivado -mode batch -source gen_xsa.tcl

open_project DDS_Signal_Generator.xpr

# Check if implementation is complete
set impl_runs [get_runs impl_1]
set status [get_property STATUS $impl_runs]
puts "INFO: impl_1 status: $status"

if {[string match "*Complete*" $status]} {
    puts "INFO: Implementation complete, exporting XSA..."
    write_hw_platform -fixed -include_bit -force \
      -file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator_wrapper.xsa"
    puts "INFO: XSA exported to DDS_Signal_Generator_wrapper.xsa"
} else {
    puts "ERROR: Implementation not complete. Status: $status"
    puts "INFO: Need to run synthesis and implementation first."
}

close_project
exit
