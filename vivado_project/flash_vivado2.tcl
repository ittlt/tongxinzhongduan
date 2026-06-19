# flash_vivado2.tcl
# Use Vivado Hardware Manager to program flash
# Run from Vivado TCL Console (Windows, not WSL)

set boot_bin "D:/FPGAmoudle/--main/--main/vivado_project/BOOT.BIN"

# Open hardware manager
open_hw_manager
connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target

# Get the FPGA device
set hw_dev [lindex [get_hw_devices xc7z*] 0]
current_hw_device $hw_dev

# Try different cfgmem part names for W25Q128JV
set cfgmem_parts {
    "s25fl128sxxxxxx0-spi_x1_x2_x4"
    "w25q128-spi_x1_x2_x4"
    "w25q128jv-spi_x1_x2_x4"
    "s25fl128s-spi_x1_x2_x4"
}

set cfgmem_created 0
foreach part $cfgmem_parts {
    puts "INFO: Trying cfgmem part: $part"
    if {[catch {create_hw_cfgmem -hw_device $hw_dev -mem_dev [lindex [get_cfgmem_parts $part] 0]} result]} {
        puts "WARNING: Failed with $part: $result"
    } else {
        puts "INFO: Successfully created cfgmem with part: $part"
        set cfgmem_created 1
        break
    }
}

if {!$cfgmem_created} {
    puts "ERROR: Could not create cfgmem with any known part"
    disconnect_hw_server
    close_hw_manager
    exit 1
}

set cfgmem [get_property PROGRAM.HW_CFGMEM $hw_dev]

# Configure programming
set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
set_property PROGRAM.FILES [list $boot_bin] $cfgmem
set_property PROGRAM.UNUSED_PIN {pullnone} $cfgmem
set_property PROGRAM.BLANK_CHECK 0 $cfgmem
set_property PROGRAM.ERASE 1 $cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
set_property PROGRAM.VERIFY 1 $cfgmem
set_property PROGRAM.CHECKSUM 0 $cfgmem

# Program
program_hw_cfgmem -hw_cfgmem $cfgmem

puts "INFO: Flash programming complete!"
disconnect_hw_server
close_hw_manager
