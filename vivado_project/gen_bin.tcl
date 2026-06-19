# gen_bin.tcl
# Generate BIN file from bitstream using write_cfgmem
set bit_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.runs/impl_1/DDS_Signal_Generator_top.bit"
set bin_file "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator_top.bin"

write_cfgmem -format BIN -interface SPIx1 -size 16 -loadbit "up 0x0 $bit_file" -force -file $bin_file

puts "BIN file generated: $bin_file"
exit
