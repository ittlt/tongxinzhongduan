# flash_vivado3.tcl
# Program flash using Vivado Hardware Manager with BIN file

set bin_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator_top.bin"

open_hw_manager
connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target

set hw_dev [lindex [get_hw_devices xc7z*] 0]
current_hw_device $hw_dev

# Program the flash with the BIN file
# Use the PROGRAM.FILE property directly
set_property PROGRAM.FILE $bin_file $hw_dev
program_hw_devices $hw_dev

puts "INFO: Flash programming complete!"
disconnect_hw_server
close_hw_manager
