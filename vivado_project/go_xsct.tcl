setws D:/FPGAmoudle/--main/--main/vivado_project/vitis_workspace
platform create -name "hw_platform" -hw D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator_wrapper.xsa
app create -name "fsbl" -platform hw_platform -domain standalone_domain -proc ps7_cortexa9_0 -template "Zynq FSBL"
bsp regenerate
app build -name "fsbl"
platform generate
puts "FSBL build done"
