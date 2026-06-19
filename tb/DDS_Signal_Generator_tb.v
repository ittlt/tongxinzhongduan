`timescale 1ns/1ps
module DDS_Signal_Generator_tb;

// 时钟与复位
reg         clk_50mhz;
reg         rst_n;
reg  [2:0]  key_in;
reg         uart_rx;
wire [7:0]  dds_out;
wire        dac_rst;
wire        uart_tx;
wire        led_sys;
wire        led_uart;

// 100MHz 时钟 = 10ns 周期
initial clk_50mhz = 1'b0;
always #5 clk_50mhz = ~clk_50mhz;

// 例化被测模块
DDS_Signal_Generator uut (
    .clk_50mhz  (clk_50mhz),
    .rst_n      (rst_n),
    .key_in     (key_in),
    .uart_rx    (uart_rx),
    .dds_out    (dds_out),
    .dac_rst    (dac_rst),
    .uart_tx    (uart_tx),
    .led_sys    (led_sys),
    .led_uart   (led_uart)
);

// 监控 uart_tx_en 上升沿，打印实际加载的 uart_tx_data
reg prev_tx_en;
always @(posedge clk_50mhz) begin
    prev_tx_en <= uut.uart_tx_en;
    if (uut.uart_tx_en && !prev_tx_en) begin
        $display("[TX EN] t=%0t  byte_idx=%0d  data=0x%02h  '%s'",
                 $time, uut.byte_idx, uut.uart_tx_data, uut.uart_tx_data);
    end
end

// UART 接收：与 HMI_UARTX 波特率精确对齐
// BAUD_CNT_MAX = 100_000_000 / 9600 = 10416 cycles
// 每 bit = 10416 * 10ns = 104160ns
parameter BIT_PERIOD = 104160;

reg [7:0] rx_byte;
integer   bit_idx;

task uart_rx_byte;
    output [7:0] data;
    begin
        // 等待起始位下降沿
        @(negedge uart_tx);
        // 起始位中间
        #(BIT_PERIOD / 2);
        // 8 位数据（LSB first）
        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            #(BIT_PERIOD);
            data[bit_idx] = uart_tx;
        end
        // 等待停止位结束
        #(BIT_PERIOD);
    end
endtask

// 主测试序列
initial begin
    rst_n   = 1'b0;
    key_in  = 3'b111;
    uart_rx = 1'b1;

    #200;               // 复位
    rst_n = 1'b1;

    // 第1次发送：上电自动触发（3波形名 + 6 BCD = 9字节）
    $display("");
    $display("========== 上电首次发送 ==========");
    repeat (9) begin
        uart_rx_byte(rx_byte);
        $display("  [RX] 0x%02h  '%s'", rx_byte, rx_byte);
    end

    // 模拟按键
    $display("");
    $display("========== 按键触发 ==========");
    #10000;
    key_in = 3'b110;
    #25_000_000;
    key_in = 3'b111;
    #10_000_000;

    repeat (9) begin
        uart_rx_byte(rx_byte);
        $display("  [RX] 0x%02h  '%s'", rx_byte, rx_byte);
    end

    // 模拟 fcw_update
    $display("");
    $display("========== FCW 更新触发 ==========");
    #10000;
    force uut.fcw_uart   = 32'd2147483;
    force uut.fcw_update = 1'b1;
    #20;
    release uut.fcw_update;
    release uut.fcw_uart;
    #10_000_000;

    repeat (9) begin
        uart_rx_byte(rx_byte);
        $display("  [RX] 0x%02h  '%s'", rx_byte, rx_byte);
    end

    $display("");
    $display("========== 仿真完成 ==========");
    #100000;
    $finish;
end

// 超时保护
initial begin
    #300_000_000;
    $display("ERROR: 仿真超时！");
    $finish;
end

// 波形输出
initial begin
    $dumpfile("DDS_sim.vcd");
    $dumpvars(0, DDS_Signal_Generator_tb);
end

endmodule
