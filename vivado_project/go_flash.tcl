connect
targets
targets -set 4
fpga -file D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.runs/impl_1/DDS_Signal_Generator_top.bit
after 1000
targets -set 2
program_flash -file D:/FPGAmoudle/--main/--main/vivado_project/BOOT.BIN -offset 0 -force
disconnect
exit
