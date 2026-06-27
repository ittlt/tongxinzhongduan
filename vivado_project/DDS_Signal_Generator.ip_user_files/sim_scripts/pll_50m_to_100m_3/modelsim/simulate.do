onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xilinx_vip -L xpm -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.pll_50m_to_100m xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {pll_50m_to_100m.udo}

run -all

quit -force
