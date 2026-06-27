// DDS_Signal_Generator_top.v
// System top wrapper: PS7 Block Design + DDS Signal Generator (PL)
// PS7 provides FCLK_CLK0 (50MHz) and FCLK_RESET0_N to PL

module DDS_Signal_Generator_top(
    // DDR3 & FIXED_IO (directly connected to PS7)
    inout [14:0] DDR_addr,
    inout [2:0]  DDR_ba,
    inout        DDR_cas_n, DDR_ck_n, DDR_ck_p, DDR_cke, DDR_cs_n,
    inout [3:0]  DDR_dm,
    inout [31:0] DDR_dq,
    inout [3:0]  DDR_dqs_n, DDR_dqs_p,
    inout        DDR_odt, DDR_ras_n, DDR_reset_n, DDR_we_n,
    inout        FIXED_IO_ddr_vrn, FIXED_IO_ddr_vrp,
    inout [53:0] FIXED_IO_mio,
    inout        FIXED_IO_ps_clk, FIXED_IO_ps_porb, FIXED_IO_ps_srstb,
    // PL I/O
    input [2:0]  key_in,
    input        uart_rx,
    output [7:0] dds_out,
    output       uart_tx, led_sys, led_uart, dds_clk
);

    wire FCLK_CLK0;
    wire FCLK_RESET0_N;

    // PS7 Block Design instance
    zynq_ps ps7_i (
        .DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FCLK_CLK0_0(FCLK_CLK0),
        .FCLK_RESET0_N_0(FCLK_RESET0_N),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb)
    );

    // DDS Signal Generator (PL logic)
    // Uses FCLK_CLK0 (50MHz) as input, PLL inside will generate 100MHz
    DDS_Signal_Generator dds_inst (
        .clk_50mhz(FCLK_CLK0),
        .rst_n(FCLK_RESET0_N),
        .key_in(key_in),
        .uart_rx(uart_rx),
        .dds_out(dds_out),
        .uart_tx(uart_tx),
        .led_sys(led_sys),
        .led_uart(led_uart),
        .dds_clk(dds_clk)
    );

endmodule
