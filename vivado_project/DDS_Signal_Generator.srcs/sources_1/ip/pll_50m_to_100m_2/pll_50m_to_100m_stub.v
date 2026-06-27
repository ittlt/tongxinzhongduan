// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Jun 27 20:58:07 2026
// Host        : FAN running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/FPGAmoudle/--main/--main/vivado_project/DDS_Signal_Generator.srcs/sources_1/ip/pll_50m_to_100m_2/pll_50m_to_100m_stub.v
// Design      : pll_50m_to_100m
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module pll_50m_to_100m(clk_out1, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,resetn,locked,clk_in1" */;
  output clk_out1;
  input resetn;
  output locked;
  input clk_in1;
endmodule
