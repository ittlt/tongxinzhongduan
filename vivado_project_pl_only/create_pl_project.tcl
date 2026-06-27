# create_pl_project.tcl
# Create pure PL Vivado project with ILA (no PS Block Design)
# Run: vivado -mode batch -source create_pl_project.tcl

set proj_dir "D:/FPGAmoudle/--main/--main/vivado_project_pl_only"
set proj_name "DDS_Signal_Generator_PL"

# Create project
create_project $proj_name $proj_dir/$proj_name -part xc7z010clg400-1 -force

# Add RTL sources
add_files -norecurse $proj_dir/rtl/DDS_Core.v
add_files -norecurse $proj_dir/rtl/DDS_Signal_Generator.v
add_files -norecurse $proj_dir/rtl/HMI_Recv.v
add_files -norecurse $proj_dir/rtl/HMI_UARTX.v
add_files -norecurse $proj_dir/rtl/HMI_UARX.v
add_files -norecurse $proj_dir/rtl/Key_Control.v

# Add constraints
add_files -fileset constrs_1 -norecurse $proj_dir/DDS_Signal_Generator.xdc

# Add ILA IP
puts "INFO: Adding ILA IP..."
source -notrace "$proj_dir/add_ila_ip.tcl"

# Add PLL IP
puts "INFO: Adding PLL IP..."
source -notrace "$proj_dir/add_pll_ip.tcl"

# Set top module
set_property top DDS_Signal_Generator [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "INFO: Pure PL project with ILA created successfully!"
puts "INFO: Project: $proj_dir/$proj_name.xpr"
puts "INFO: Top module: DDS_Signal_Generator"
puts "INFO: ILA monitors: dds_out(8-bit), fcw_sel(32-bit), fcw_uart(32-bit)"
