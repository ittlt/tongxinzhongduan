# add_pll_ip.tcl
# Add PLL IP to project (50MHz -> 100MHz)

# Create PLL IP
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name pll_50m_to_100m

# Configure PLL - minimal valid parameters
set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
    CONFIG.PRIM_IN_FREQ {50} \
    CONFIG.NUM_OUT_CLKS {1} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.RESET_PORT {resetn} \
] [get_ips pll_50m_to_100m]

# Generate target
generate_target all [get_ips pll_50m_to_100m]

puts "INFO: PLL IP created successfully"
