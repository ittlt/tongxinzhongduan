# ============================================================
# create_ps_bd.tcl
# Create PS Block Design for Zynq-7010 with QSPI and DDR3
# ============================================================

puts "INFO: Creating Block Design 'zynq_ps'"

# Remove existing BD if it exists
if {[llength [get_files -of_objects [get_filesets sources_1] *.bd]] > 0} {
    puts "INFO: Removing existing BD..."
    remove_files [get_files zynq_ps.bd]
    file delete -force "D:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.srcs/sources_1/bd/zynq_ps"
}

# Create Block Design
create_bd_design "zynq_ps"

# Add PS7 IP
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Auto-connect DDR and FIXED_IO to external ports
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR"} [get_bd_cells ps7]

# ============================================================
# Configure PS7
# ============================================================

# --- QSPI Flash (W25Q128JV, 16MB) ---
# Note: QSPI config must be done after DDR config to avoid mutex conflicts
puts "INFO: QSPI will be configured after DDR"

# --- DDR3 (1GB, 32-bit, MT41K256M16) ---
puts "INFO: Configuring DDR3"
set_property -dict [list \
    CONFIG.PCW_DDR_MEMORY_TYPE {DDR 3} \
    CONFIG.PCW_DDR_DEVICE_WIDTH {16} \
    CONFIG.PCW_DDR_RAM_WIDTH {32} \
    CONFIG.PCW_DDR_MEMORY_PART {MT41K256M16 RE-125} \
    CONFIG.PCW_DDR_SPEED_BIN {DDR3_1066F} \
] [get_bd_cells ps7]

# --- QSPI Flash (W25Q128JV, 16MB) - Configure after DDR ---
puts "INFO: Configuring QSPI Flash"
set_property -dict [list \
    CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
] [get_bd_cells ps7]

# --- PL Clock FCLK_CLK0 = 50MHz ---
puts "INFO: Configuring FCLK_CLK0 = 50MHz"
set_property -dict [list \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
] [get_bd_cells ps7]

# Connect M_AXI_GP0_ACLK to FCLK_CLK0
puts "INFO: Connecting M_AXI_GP0_ACLK"
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins ps7/M_AXI_GP0_ACLK]

# Create external ports for FCLK_CLK0 and FCLK_RESET0_N
puts "INFO: Creating FCLK external ports"
create_bd_port -type clk -dir O FCLK_CLK0_0
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_ports FCLK_CLK0_0]
create_bd_port -type rst -dir O FCLK_RESET0_N_0
connect_bd_net [get_bd_pins ps7/FCLK_RESET0_N] [get_bd_ports FCLK_RESET0_N_0]

# ============================================================
# Validate and Save
# ============================================================
puts "INFO: Regenerating layout"
regenerate_bd_layout

puts "INFO: Validating design"
validate_bd_design

puts "INFO: Saving design"
save_bd_design

# Generate HDL Wrapper
puts "INFO: Generating HDL Wrapper"
set wrapper_file [make_wrapper -files [get_files zynq_ps.bd] -top]
add_files -norecurse $wrapper_file
update_compile_order -fileset sources_1

puts "INFO: Block Design creation complete!"
