// DDS信号发生器核心模块
// 功能：基于相位累加器与查找表实现正弦/方波/三角波生成，支持频率控制字更新
module DDS_Core(
    input           clk,         // 系统时钟（100MHz）
    input           rst_n,       // 复位信号（低电平有效）
    input [31:0]    fcw,         // 频率控制字（32位，决定输出频率）
    input [1:0]     wave_sel,    // 波形选择（00：正弦波，01：方波，10：三角波）
    output reg [7:0]dds_out      // DDS数字信号输出（8位，连接DAC）
);
// 内部信号定义
reg [31:0] phase_acc;  // 32位相位累加器，决定相位精度（相位范围0~2^32-1，对应0~360°）
wire [7:0] sin_lut;    // 正弦波查找表输出
wire [7:0] square_wave; // 方波输出
wire [7:0] triangle_wave; // 三角波输出
// 1. 相位累加器模块：根据频率控制字累加相位，系统时钟每周期累加一次FCW
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        phase_acc <= 32'd0;  // 复位时相位累加器清零，初始相位为0°
    end else begin
        // 相位累加：溢出后自动归零，实现相位循环（对应波形周期重复）
        phase_acc <= phase_acc + fcw;  
    end
end
// 2. 正弦波查找表（LUT）：8位幅度（0~255），取32位相位累加器高8位作为索引（256个相位点）
// 查找表数据为正弦波0~360°的幅度值，可通过MATLAB生成后导入（此处给出部分示例数据）
reg [7:0] sin_lut_table [0:255];
initial begin
    // 初始化正弦波查找表，正弦波幅度范围映射为0~255（直流偏置128，幅值127）
    sin_lut_table[0]  = 8'd128;  // 0°，幅度中点
    sin_lut_table[1]  = 8'd131;  // 1.40625°，幅度轻微上升
    sin_lut_table[2]  = 8'd134;  // 2.8125°，继续上升
    // ... 省略中间250个数据点（实际实验需补充完整256个数据）
    sin_lut_table[254] = 8'd131; // 357.1875°，幅度下降
    sin_lut_table[255] = 8'd128; // 358.59375°，回到中点
end
// 取相位累加器高8位作为查找表索引，获取对应正弦波幅度值
assign sin_lut = sin_lut_table[phase_acc[31:24]];  
// 3. 方波生成：根据相位累加器高8位判断，大于127输出高电平（255），否则输出低电平（0）
// 方波占空比为50%，幅度范围0~255
assign square_wave = (phase_acc[31:24] > 8'd127) ? 8'd255 : 8'd0;
// 4. 三角波生成：相位累加器高8位0~127时线性递增，128~255时线性递减
// 幅度范围0~254，保证线性变化
assign triangle_wave = (phase_acc[31:24] <= 8'd127) ? 
                 phase_acc[31:24] << 1 :  // 0~127：0~254递增（左移1位等价于×2）
                (8'd255 - (phase_acc[31:24] - 8'd128) << 1);  // 128~255：254~0递减
// 5. 波形选择与输出：根据wave_sel信号选择对应波形，复位时输出低电平
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dds_out <= 8'd0;  // 复位时输出低电平，确保DAC初始状态稳定
    end else begin
        case(wave_sel)
            2'b00: dds_out <= sin_lut;       // 选择正弦波输出
            2'b01: dds_out <= square_wave;   // 选择方波输出
            2'b10: dds_out <= triangle_wave; // 选择三角波输出
            default: dds_out <= sin_lut;     // 默认输出正弦波，提高系统容错性
        endcase
    end
end
endmodule
6.3 按键消抖与频率控制模块代码（Verilog）
// 按键消抖与频率控制模块
// 功能：实现4个按键的消抖处理，生成频率控制字与波形选择信号，输出至DDS核心模块
module Key_Control(
    input           clk,         // 系统时钟（100MHz）
    input           rst_n,       // 复位信号（低电平有效）
    input [3:0]     key_in,      // 按键输入（4位，对应Freq+、Freq-、Wave_Sel、Confirm）
    output reg [31:0]fcw,         // 输出频率控制字（送至DDS核心模块）
    output reg [1:0]wave_sel,    // 输出波形选择信号（送至DDS核心模块）
    output reg      led_key      // 按键有效指示LED（高电平有效）
);
// 内部信号定义
reg [19:0] cnt_debounce;  // 消抖计数器（100MHz时钟，计数20ms需1000000个时钟周期，2^20≈1048576≥1000000）
reg [3:0] key_sync;       // 按键同步信号（两级寄存器消除亚稳态）
reg [3:0] key_delay1;     // 按键延迟信号1
reg [3:0] key_delay2;     // 按键延迟信号2
wire [3:0] key_edge;      // 按键下降沿检测（按键按下时触发，消抖后）
reg [1:0] wave_sel_reg;   // 波形选择寄存器（暂存波形选择状态）
reg [31:0] fcw_reg;       // 频率控制字寄存器（暂存频率控制字）
// 参数定义（频率控制字计算：FCW = 频率值 * 2^32 / 系统时钟频率（100MHz））
parameter FCW_DEFAULT = 32'd10737418;  // 默认频率控制字（对应100kHz：100000 * 2^32 / 100000000 = 10737418.24，取整）
parameter FCW_STEP = 32'd107374;       // 频率步进控制字（对应1kHz：1000 * 2^32 / 100000000 = 107374.1824，取整）
parameter FCW_MIN = 32'd10737;         // 频率下限控制字（对应100Hz：100 * 2^32 / 100000000 = 10737.41824，取整）
// 1. 按键同步与消抖处理：两级同步消除亚稳态，20ms消抖确认按键状态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key_sync <= 4'b1111;  // 初始状态为高电平（上拉电阻作用）
        key_delay1 <= 4'b1111;
        key_delay2 <= 4'b1111;
        cnt_debounce <= 20'd0;
    end else begin
        // 两级寄存器同步，消除按键信号亚稳态
        key_sync <= key_in;
        key_delay1 <= key_sync;
        key_delay2 <= key_delay1;
        // 消抖计数：当按键状态变化时，计数器清零重新计数；状态稳定时，计数器累加
        if(key_delay1 != key_delay2) begin
            cnt_debounce <= 20'd0;
        end else begin
            cnt_debounce <= cnt_debounce + 20'd1;
        end
    end
end
// 2. 按键下降沿检测：消抖计数满20ms后，检测到key_delay2由高变低则判定为有效按键
assign key_edge = key_delay2 & (~key_delay1) & (cnt_debounce == 20'd1_000_000);
// 3. 频率控制字与波形选择逻辑：根据有效按键信号更新频率控制字和波形选择状态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcw_reg <= FCW_DEFAULT;    // 复位时加载默认频率控制字（100kHz）
        wave_sel_reg <= 2'b00;     // 初始选择正弦波
        led_key <= 1'b0;           // 复位时按键指示LED熄灭
    end else begin
        led_key <= 1'b0;           // 默认LED熄灭，仅按键有效时点亮
        case(key_edge)
            4'b0001: begin  // Freq+按键按下（key_in[0]对应Freq+）
                fcw_reg <= fcw_reg + FCW_STEP;  // 频率增加1kHz
                led_key <= 1'b1;                // 按键有效，LED点亮
            end
            4'b0010: begin  // Freq-按键按下（key_in[1]对应Freq-）
                // 频率下限保护：确保频率不低于100Hz
                if(fcw_reg >= FCW_MIN + FCW_STEP) begin
                    fcw_reg <= fcw_reg - FCW_STEP;  // 频率减少1kHz
                end
                led_key <= 1'b1;                    // 按键有效，LED点亮
            end
            4'b0100: begin  // Wave_Sel按键按下（key_in[2]对应Wave_Sel）
               wave_sel_reg <= wave_sel_reg + 2'd1; // 切换波形（正弦->方波->三角波）
               if(wave_sel_reg == 2'b10) begin      // 三角波之后回到正弦波，循环切换
               wave_sel_reg <= 2'b00;
                end
                led_key <= 1'b1;                      // 按键有效，LED点亮
            end
            4'b1000: begin  // Confirm按键按下（key_in[3]对应Confirm）
                // 确认锁定当前频率与波形（此处直接保持当前状态，无额外锁定逻辑）
                led_key <= 1'b1;                      // 按键有效，LED点亮
            end
            default: begin  // 无按键操作，保持当前状态
                fcw_reg <= fcw_reg;
                wave_sel_reg <= wave_sel_reg;
            end
        endcase
    end
end
// 4. 输出赋值：将暂存的频率控制字和波形选择信号输出至DDS核心模块
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcw <= FCW_DEFAULT;
        wave_sel <= 2'b00;
    end else begin
        fcw <= fcw_reg;
        wave_sel <= wave_sel_reg;
    end
end
endmodule
6.4 UART接收与指令解析模块代码（Verilog）
// UART接收与指令解析模块
// 功能：实现UART异步接收（9600bps），解析PC端频率控制指令，生成频率控制字输出至DDS核心模块
module UART_Parse(
    input           clk,         // 系统时钟（100MHz）
    input           rst_n,       // 复位信号（低电平有效）
    input           uart_rx,     // UART接收引脚
    output reg [31:0]fcw_uart,   // 解析后的频率控制字（送至DDS核心模块）
    output reg      fcw_update,  // 频率控制字更新标志（高电平有效，通知DDS模块更新）
    output reg      led_uart     // 串口通信状态指示LED（高电平有效）
);
// 内部信号定义
reg [15:0] cnt_baud;      // 波特率时钟计数器（9600bps，100MHz时钟下，波特率周期≈10417个时钟周期）
reg [3:0] cnt_bit;        // 位计数器（0-9：对应起始位+8位数据位+1位停止位）
reg [7:0] uart_data;      // 接收的数据字节（8位）
reg [7:0] cmd_buf [0:5];  // 指令缓存（存储ASCII码格式的频率指令，格式：“Fxxxxxx”，共6个数据字节）
reg [2:0] cmd_cnt;        // 指令字节计数器（0-6，计数接收的指令字节数）
reg uart_rx_sync1;        // 接收信号同步寄存器1
reg uart_rx_sync2;        // 接收信号同步寄存器2
reg uart_rx_sync3;        // 接收信号同步寄存器3
wire uart_rx_neg;         // 接收信号下降沿检测（用于捕获起始位）
reg recv_flag;            // 单字节接收完成标志
// 参数定义（波特率相关）
parameter BAUD_CNT = 16'd10416;  // 9600bps波特率计数最大值（100MHz/9600 - 1 ≈ 10416）
parameter BAUD_HALF = 16'd5208;  // 波特率半周期计数（用于位采样，确保在位周期中间采样）
parameter FCW_DEFAULT = 32'd10737418;  // 默认频率控制字（100kHz）
// 1. 接收信号同步与下降沿检测：三级同步消除亚稳态，检测起始位下降沿
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_rx_sync1 <= 1'b1;
        uart_rx_sync2 <= 1'b1;
        uart_rx_sync3 <= 1'b1;
    end else begin
        // 三级寄存器同步，消除UART接收信号的亚稳态
        uart_rx_sync1 <= uart_rx;
        uart_rx_sync2 <= uart_rx_sync1;
        uart_rx_sync3 <= uart_rx_sync2;
    end
end
// 检测下降沿（uart_rx_sync2由1变0，且uart_rx_sync3为1）
assign uart_rx_neg = ~uart_rx_sync2 & uart_rx_sync3;
// 2. 波特率时钟生成与位计数：检测到起始位后，启动波特率计数与位计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_baud <= 16'd0;
        cnt_bit <= 4'd0;
        recv_flag <= 1'b0;
        led_uart <= 1'b0;
    end else if(uart_rx_neg) begin  // 检测到起始位，开始接收过程
        cnt_baud <= BAUD_HALF;     // 计数至半周期，准备在第一位数据的中间位置采样
        cnt_bit <= 4'd1;           // 位计数器置1（起始位为0，对应cnt_bit=0）
        recv_flag <= 1'b0;
        led_uart <= 1'b1;          // 串口接收中，LED点亮
    end else if(cnt_bit != 4'd0) begin  // 正在接收数据（位计数器不为0）
        cnt_baud <= cnt_baud + 16'd1;
        if(cnt_baud == BAUD_CNT) begin  // 一个波特率周期结束
            cnt_baud <= 16'd0;
            cnt_bit <= cnt_bit + 4'd1;
           if(cnt_bit == 4'd9) begin  // 接收完成（已接收起始位+8位数据位+1位停止位）
                cnt_bit <= 4'd0;
                recv_flag <= 1'b1;     // 单字节接收完成标志置1
                led_uart <= 1'b0;      // 接收完成，LED熄灭
            end
        end
    end else begin
        recv_flag <= 1'b0;  // 无接收过程，接收完成标志清零
    end
end
// 3. UART数据接收：在每个位周期的中间位置采样数据（8位数据位，无校验位，1位停止位）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_data <= 8'd0;
    end else if(cnt_bit != 4'd0 && cnt_baud == BAUD_HALF) begin  
// 在位周期中间采样，确保采样稳定
        case(cnt_bit)
            4'd2: uart_data[0] <= uart_rx_sync2;  // 第1位数据（LSB，最低有效位）
            4'd3: uart_data[1] <= uart_rx_sync2;
            4'd4: uart_data[2] <= uart_rx_sync2;
            4'd5: uart_data[3] <= uart_rx_sync2;
            4'd6: uart_data[4] <= uart_rx_sync2;
            4'd7: uart_data[5] <= uart_rx_sync2;
            4'd8: uart_data[6] <= uart_rx_sync2;
            4'd9: uart_data[7] <= uart_rx_sync2;  // 第8位数据（MSB，最高有效位）
            default: ;  // 其他位（起始位、停止位）不采样
        endcase
    end
end
// 4. 指令解析：指令格式为“Fxxxxxx”，F为指令头（ASCII码0x46），后接6位ASCII码表示的频率值（单位Hz）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cmd_cnt <= 3'd0;
        fcw_uart <= FCW_DEFAULT;  // 复位时加载默认频率控制字（100kHz）
        fcw_update <= 1'b0;
    end else if(recv_flag) begin  // 单字节接收完成，开始解析
        if(cmd_cnt == 3'd0) begin  // 接收第一个字节，判断是否为指令头
            if(uart_data == 8'h46) begin  // 指令头为'F'（ASCII码0x46），确认指令有效
                cmd_cnt <= 3'd1;
            end else begin
                cmd_cnt <= 3'd0;  // 指令头错误，丢弃当前接收数据
            end
        end else if(cmd_cnt <= 3'd6) begin  // 接收后续6位频率数字的ASCII码
            cmd_buf[cmd_cnt-1] <= uart_data;  // 存储到指令缓存
            cmd_cnt <= cmd_cnt + 3'd1;
            if(cmd_cnt == 3'd6) begin  // 6位数字接收完成，开始转换为频率值
                cmd_cnt <= 3'd0;
             // 将ASCII码转换为十进制频率值（ASCII码0x30对应数字0，0x39对应数字9）
                reg [23:0] freq;  // 频率值暂存（最大支持999999Hz，24位足够存储）
                freq = (cmd_buf[0]-8'h30)*100000 + (cmd_buf[1]-8'h30)*10000 + 
                       (cmd_buf[2]-8'h30)*1000 + (cmd_buf[3]-8'h30)*100 + 
                       (cmd_buf[4]-8'h30)*10 + (cmd_buf[5]-8'h30)*1;
                // 计算频率控制字：FCW = 频率值 * 2^32 / 100MHz
                fcw_uart <= (freq << 32) / 100_000_000;
                fcw_update <= 1'b1;  // 频率控制字更新标志置1，通知DDS模块更新
            #10 fcw_update <= 1'b0; // 延迟10个时钟周期后清零标志（确保DDS模块捕获）
            end
        end
    end
end
endmodule
6.5 系统顶层模块代码（Verilog）
// 系统顶层模块：整合各功能模块，实现完整DDS信号发生器功能
// 模块间信号交互：PLL生成100MHz时钟，按键/串口模块生成控制信号，DDS核心模块生成数字波形，输出至DAC
module DDS_Signal_Generator(
    input           clk_50mhz,   // 50MHz系统时钟输入（DE2实验板板载晶振）
    input           rst_n,       // 复位信号（低电平有效）
    input [3:0]     key_in,      // 按键输入（4位）
    input           uart_rx,     // UART接收引脚
    output [7:0]    dds_out,     // DDS数字信号输出（连接DAC）
    output          dac_rst,     // DAC复位控制
    output          led_key,     // 按键状态指示LED
    output          led_uart,    // 串口状态指示LED
    output          led_sys      // 系统工作状态指示LED（PLL锁定状态）
);
// 内部信号定义
wire        clk_100mhz;      // PLL输出100MHz系统时钟
wire [31:0] fcw_key;         // 按键控制模块输出的频率控制字
wire [31:0] fcw_uart;        // UART解析模块输出的频率控制字
wire [1:0]  wave_sel;         // 波形选择信号（来自按键控制模块）
wire        fcw_update;       // UART频率控制字更新标志
reg [31:0]  fcw_sel;          // 频率控制字选择输出（选择按键或串口控制字）
// 1. PLL模块实例化（将50MHz输入时钟倍频至100MHz，提供系统同步时钟）
// 注：pll_50m_to_100m模块为通过Quartus II MegaWizard生成的PLL IP核
pll_50m_to_100m pll_inst(
    .inclk0(clk_50mhz),  // PLL输入时钟（50MHz）
    .c0(clk_100mhz),     // PLL输出时钟（100MHz）
    .locked(led_sys)     // PLL锁定标志（高电平有效，作为系统工作状态指示）
);
// 2. DAC复位控制：复位信号低电平时DAC复位，复位完成后高电平使能DAC工作
assign dac_rst = rst_n;
// 3. 按键控制模块实例化：处理按键输入，生成频率控制字和波形选择信号
Key_Control key_ctrl_inst(
    .clk(clk_100mhz),
    .rst_n(rst_n),
    .key_in(key_in),
    .fcw(fcw_key),
    .wave_sel(wave_sel),
    .led_key(led_key)
);
// 4. HMI串口接收模块实例化：接收PC端串口指令，解析生成频率控制字
wire [31:0] hmi_num;
wire hmi_done;

HMI_Recv hmi_recv_inst(
    .clk(clk_100mhz),
    .rst_n(rst_n),
    .HMI_RX(uart_rx)
);

// 将HMI_Num转换为频率控制字
// HMI_Num是频率值(Hz)，FCW = 频率值 * 2^32 / 100MHz
always @(posedge clk_100mhz or negedge rst_n) begin
    if(!rst_n) begin
        fcw_uart <= 32'd10737418;
        fcw_update <= 1'b0;
    end else if(hmi_recv_inst.HMI_Done) begin
        fcw_uart <= (hmi_recv_inst.HMI_Num << 32) / 100_000_000;
        fcw_update <= 1'b1;
    end else begin
        fcw_update <= 1'b0;
    end
end
// 5. 频率控制字选择逻辑：串口控制优先，当有串口更新标志时选择串口控制字，否则选择按键控制字
always @(posedge clk_100mhz or negedge rst_n) begin
    if(!rst_n) begin
        fcw_sel <= 32'd10737418;  // 复位时默认选择100kHz频率控制字
    end else if(fcw_update) begin
        fcw_sel <= fcw_uart;       // 串口更新时，选择UART解析的频率控制字
    end else begin
        fcw_sel <= fcw_key;        // 无串口更新时，选择按键控制的频率控制字
    end
end
// 6. DDS核心模块实例化：根据选择的频率控制字和波形选择信号，生成数字波形输出
DDS_Core dds_core_inst(
    .clk(clk_100mhz),
    .rst_n(rst_n),
    .fcw(fcw_sel),
    .wave_sel(wave_sel),
    .dds_out(dds_out)
);
endmodule
