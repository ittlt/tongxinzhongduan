## Pure PL Version - DDS Signal Generator
## External 50MHz clock and reset required

## 时钟和复位
set_property PACKAGE_PIN N18 [get_ports clk_50mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_50mhz]
set_property PACKAGE_PIN G19 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## PL端用户按键（3个，低电平有效）
set_property PACKAGE_PIN G20 [get_ports {key_in[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[0]}]
set_property PACKAGE_PIN H15 [get_ports {key_in[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[1]}]
set_property PACKAGE_PIN G15 [get_ports {key_in[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[2]}]

## UART串口
set_property PACKAGE_PIN B20 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PACKAGE_PIN C20 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

## 8位DDS输出 + 时钟
set_property PACKAGE_PIN U17 [get_ports dds_clk]
set_property IOSTANDARD LVCMOS33 [get_ports dds_clk]

set_property PACKAGE_PIN P15 [get_ports {dds_out[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[7]}]
set_property PACKAGE_PIN P16 [get_ports {dds_out[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[6]}]
set_property PACKAGE_PIN P14 [get_ports {dds_out[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[5]}]
set_property PACKAGE_PIN R14 [get_ports {dds_out[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[4]}]
set_property PACKAGE_PIN V16 [get_ports {dds_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[3]}]
set_property PACKAGE_PIN W16 [get_ports {dds_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[2]}]
set_property PACKAGE_PIN R16 [get_ports {dds_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[1]}]
set_property PACKAGE_PIN R17 [get_ports {dds_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dds_out[0]}]

## PL端LED指示灯
set_property PACKAGE_PIN J14 [get_ports led_sys]
set_property IOSTANDARD LVCMOS33 [get_ports led_sys]
set_property PACKAGE_PIN K19 [get_ports led_uart]
set_property IOSTANDARD LVCMOS33 [get_ports led_uart]
