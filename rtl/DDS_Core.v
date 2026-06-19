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
reg  [31:0] phase_acc;      // 32位相位累加器
wire [7:0]  sin_lut;        // 正弦波查找表输出
wire [7:0]  square_wave;    // 方波输出
wire [7:0]  triangle_wave;  // 三角波输出

// 1. 相位累加器模块
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        phase_acc <= 32'd0;
    end else begin
        phase_acc <= phase_acc + fcw;
    end
end

// 2. 正弦波查找表（LUT）：8位幅度（0~255），256个相位点
// 数据计算公式：128 + 127 * sin(2*pi*i/256)
reg [7:0] sin_lut_table [0:255];
initial begin
    sin_lut_table[  0] = 8'd128;  // 0.00°
    sin_lut_table[  1] = 8'd131;
    sin_lut_table[  2] = 8'd134;
    sin_lut_table[  3] = 8'd137;
    sin_lut_table[  4] = 8'd140;
    sin_lut_table[  5] = 8'd144;
    sin_lut_table[  6] = 8'd147;
    sin_lut_table[  7] = 8'd150;
    sin_lut_table[  8] = 8'd153;  // 11.25°
    sin_lut_table[  9] = 8'd156;
    sin_lut_table[ 10] = 8'd159;
    sin_lut_table[ 11] = 8'd162;
    sin_lut_table[ 12] = 8'd165;
    sin_lut_table[ 13] = 8'd168;
    sin_lut_table[ 14] = 8'd171;
    sin_lut_table[ 15] = 8'd174;
    sin_lut_table[ 16] = 8'd177;  // 22.50°
    sin_lut_table[ 17] = 8'd179;
    sin_lut_table[ 18] = 8'd182;
    sin_lut_table[ 19] = 8'd185;
    sin_lut_table[ 20] = 8'd188;
    sin_lut_table[ 21] = 8'd191;
    sin_lut_table[ 22] = 8'd193;
    sin_lut_table[ 23] = 8'd196;
    sin_lut_table[ 24] = 8'd199;  // 33.75°
    sin_lut_table[ 25] = 8'd201;
    sin_lut_table[ 26] = 8'd204;
    sin_lut_table[ 27] = 8'd206;
    sin_lut_table[ 28] = 8'd209;
    sin_lut_table[ 29] = 8'd211;
    sin_lut_table[ 30] = 8'd213;
    sin_lut_table[ 31] = 8'd216;
    sin_lut_table[ 32] = 8'd218;  // 45.00°
    sin_lut_table[ 33] = 8'd220;
    sin_lut_table[ 34] = 8'd222;
    sin_lut_table[ 35] = 8'd224;
    sin_lut_table[ 36] = 8'd226;
    sin_lut_table[ 37] = 8'd228;
    sin_lut_table[ 38] = 8'd230;
    sin_lut_table[ 39] = 8'd232;
    sin_lut_table[ 40] = 8'd234;  // 56.25°
    sin_lut_table[ 41] = 8'd235;
    sin_lut_table[ 42] = 8'd237;
    sin_lut_table[ 43] = 8'd239;
    sin_lut_table[ 44] = 8'd240;
    sin_lut_table[ 45] = 8'd241;
    sin_lut_table[ 46] = 8'd243;
    sin_lut_table[ 47] = 8'd244;
    sin_lut_table[ 48] = 8'd245;  // 67.50°
    sin_lut_table[ 49] = 8'd246;
    sin_lut_table[ 50] = 8'd248;
    sin_lut_table[ 51] = 8'd249;
    sin_lut_table[ 52] = 8'd250;
    sin_lut_table[ 53] = 8'd250;
    sin_lut_table[ 54] = 8'd251;
    sin_lut_table[ 55] = 8'd252;
    sin_lut_table[ 56] = 8'd253;  // 78.75°
    sin_lut_table[ 57] = 8'd253;
    sin_lut_table[ 58] = 8'd254;
    sin_lut_table[ 59] = 8'd254;
    sin_lut_table[ 60] = 8'd254;
    sin_lut_table[ 61] = 8'd255;
    sin_lut_table[ 62] = 8'd255;
    sin_lut_table[ 63] = 8'd255;
    sin_lut_table[ 64] = 8'd255;  // 90.00°
    sin_lut_table[ 65] = 8'd255;
    sin_lut_table[ 66] = 8'd255;
    sin_lut_table[ 67] = 8'd255;
    sin_lut_table[ 68] = 8'd254;
    sin_lut_table[ 69] = 8'd254;
    sin_lut_table[ 70] = 8'd254;
    sin_lut_table[ 71] = 8'd253;
    sin_lut_table[ 72] = 8'd253;  // 101.25°
    sin_lut_table[ 73] = 8'd252;
    sin_lut_table[ 74] = 8'd251;
    sin_lut_table[ 75] = 8'd250;
    sin_lut_table[ 76] = 8'd250;
    sin_lut_table[ 77] = 8'd249;
    sin_lut_table[ 78] = 8'd248;
    sin_lut_table[ 79] = 8'd246;
    sin_lut_table[ 80] = 8'd245;  // 112.50°
    sin_lut_table[ 81] = 8'd244;
    sin_lut_table[ 82] = 8'd243;
    sin_lut_table[ 83] = 8'd241;
    sin_lut_table[ 84] = 8'd240;
    sin_lut_table[ 85] = 8'd239;
    sin_lut_table[ 86] = 8'd237;
    sin_lut_table[ 87] = 8'd235;
    sin_lut_table[ 88] = 8'd234;  // 123.75°
    sin_lut_table[ 89] = 8'd232;
    sin_lut_table[ 90] = 8'd230;
    sin_lut_table[ 91] = 8'd228;
    sin_lut_table[ 92] = 8'd226;
    sin_lut_table[ 93] = 8'd224;
    sin_lut_table[ 94] = 8'd222;
    sin_lut_table[ 95] = 8'd220;
    sin_lut_table[ 96] = 8'd218;  // 135.00°
    sin_lut_table[ 97] = 8'd216;
    sin_lut_table[ 98] = 8'd213;
    sin_lut_table[ 99] = 8'd211;
    sin_lut_table[100] = 8'd209;
    sin_lut_table[101] = 8'd206;
    sin_lut_table[102] = 8'd204;
    sin_lut_table[103] = 8'd201;
    sin_lut_table[104] = 8'd199;  // 146.25°
    sin_lut_table[105] = 8'd196;
    sin_lut_table[106] = 8'd193;
    sin_lut_table[107] = 8'd191;
    sin_lut_table[108] = 8'd188;
    sin_lut_table[109] = 8'd185;
    sin_lut_table[110] = 8'd182;
    sin_lut_table[111] = 8'd179;
    sin_lut_table[112] = 8'd177;  // 157.50°
    sin_lut_table[113] = 8'd174;
    sin_lut_table[114] = 8'd171;
    sin_lut_table[115] = 8'd168;
    sin_lut_table[116] = 8'd165;
    sin_lut_table[117] = 8'd162;
    sin_lut_table[118] = 8'd159;
    sin_lut_table[119] = 8'd156;
    sin_lut_table[120] = 8'd153;  // 168.75°
    sin_lut_table[121] = 8'd150;
    sin_lut_table[122] = 8'd147;
    sin_lut_table[123] = 8'd144;
    sin_lut_table[124] = 8'd140;
    sin_lut_table[125] = 8'd137;
    sin_lut_table[126] = 8'd134;
    sin_lut_table[127] = 8'd131;
    sin_lut_table[128] = 8'd128;  // 180.00°
    sin_lut_table[129] = 8'd125;
    sin_lut_table[130] = 8'd122;
    sin_lut_table[131] = 8'd119;
    sin_lut_table[132] = 8'd116;
    sin_lut_table[133] = 8'd112;
    sin_lut_table[134] = 8'd109;
    sin_lut_table[135] = 8'd106;
    sin_lut_table[136] = 8'd103;  // 191.25°
    sin_lut_table[137] = 8'd100;
    sin_lut_table[138] = 8'd 97;
    sin_lut_table[139] = 8'd 94;
    sin_lut_table[140] = 8'd 91;
    sin_lut_table[141] = 8'd 88;
    sin_lut_table[142] = 8'd 85;
    sin_lut_table[143] = 8'd 82;
    sin_lut_table[144] = 8'd 79;  // 202.50°
    sin_lut_table[145] = 8'd 77;
    sin_lut_table[146] = 8'd 74;
    sin_lut_table[147] = 8'd 71;
    sin_lut_table[148] = 8'd 68;
    sin_lut_table[149] = 8'd 65;
    sin_lut_table[150] = 8'd 63;
    sin_lut_table[151] = 8'd 60;
    sin_lut_table[152] = 8'd 57;  // 213.75°
    sin_lut_table[153] = 8'd 55;
    sin_lut_table[154] = 8'd 52;
    sin_lut_table[155] = 8'd 50;
    sin_lut_table[156] = 8'd 47;
    sin_lut_table[157] = 8'd 45;
    sin_lut_table[158] = 8'd 43;
    sin_lut_table[159] = 8'd 40;
    sin_lut_table[160] = 8'd 38;  // 225.00°
    sin_lut_table[161] = 8'd 36;
    sin_lut_table[162] = 8'd 34;
    sin_lut_table[163] = 8'd 32;
    sin_lut_table[164] = 8'd 30;
    sin_lut_table[165] = 8'd 28;
    sin_lut_table[166] = 8'd 26;
    sin_lut_table[167] = 8'd 24;
    sin_lut_table[168] = 8'd 22;  // 236.25°
    sin_lut_table[169] = 8'd 21;
    sin_lut_table[170] = 8'd 19;
    sin_lut_table[171] = 8'd 17;
    sin_lut_table[172] = 8'd 16;
    sin_lut_table[173] = 8'd 15;
    sin_lut_table[174] = 8'd 13;
    sin_lut_table[175] = 8'd 12;
    sin_lut_table[176] = 8'd 11;  // 247.50°
    sin_lut_table[177] = 8'd 10;
    sin_lut_table[178] = 8'd  8;
    sin_lut_table[179] = 8'd  7;
    sin_lut_table[180] = 8'd  6;
    sin_lut_table[181] = 8'd  6;
    sin_lut_table[182] = 8'd  5;
    sin_lut_table[183] = 8'd  4;
    sin_lut_table[184] = 8'd  3;  // 258.75°
    sin_lut_table[185] = 8'd  3;
    sin_lut_table[186] = 8'd  2;
    sin_lut_table[187] = 8'd  2;
    sin_lut_table[188] = 8'd  2;
    sin_lut_table[189] = 8'd  1;
    sin_lut_table[190] = 8'd  1;
    sin_lut_table[191] = 8'd  1;
    sin_lut_table[192] = 8'd  1;  // 270.00°
    sin_lut_table[193] = 8'd  1;
    sin_lut_table[194] = 8'd  1;
    sin_lut_table[195] = 8'd  1;
    sin_lut_table[196] = 8'd  2;
    sin_lut_table[197] = 8'd  2;
    sin_lut_table[198] = 8'd  2;
    sin_lut_table[199] = 8'd  3;
    sin_lut_table[200] = 8'd  3;  // 281.25°
    sin_lut_table[201] = 8'd  4;
    sin_lut_table[202] = 8'd  5;
    sin_lut_table[203] = 8'd  6;
    sin_lut_table[204] = 8'd  6;
    sin_lut_table[205] = 8'd  7;
    sin_lut_table[206] = 8'd  8;
    sin_lut_table[207] = 8'd 10;
    sin_lut_table[208] = 8'd 11;  // 292.50°
    sin_lut_table[209] = 8'd 12;
    sin_lut_table[210] = 8'd 13;
    sin_lut_table[211] = 8'd 15;
    sin_lut_table[212] = 8'd 16;
    sin_lut_table[213] = 8'd 17;
    sin_lut_table[214] = 8'd 19;
    sin_lut_table[215] = 8'd 21;
    sin_lut_table[216] = 8'd 22;  // 303.75°
    sin_lut_table[217] = 8'd 24;
    sin_lut_table[218] = 8'd 26;
    sin_lut_table[219] = 8'd 28;
    sin_lut_table[220] = 8'd 30;
    sin_lut_table[221] = 8'd 32;
    sin_lut_table[222] = 8'd 34;
    sin_lut_table[223] = 8'd 36;
    sin_lut_table[224] = 8'd 38;  // 315.00°
    sin_lut_table[225] = 8'd 40;
    sin_lut_table[226] = 8'd 43;
    sin_lut_table[227] = 8'd 45;
    sin_lut_table[228] = 8'd 47;
    sin_lut_table[229] = 8'd 50;
    sin_lut_table[230] = 8'd 52;
    sin_lut_table[231] = 8'd 55;
    sin_lut_table[232] = 8'd 57;  // 326.25°
    sin_lut_table[233] = 8'd 60;
    sin_lut_table[234] = 8'd 63;
    sin_lut_table[235] = 8'd 65;
    sin_lut_table[236] = 8'd 68;
    sin_lut_table[237] = 8'd 71;
    sin_lut_table[238] = 8'd 74;
    sin_lut_table[239] = 8'd 77;
    sin_lut_table[240] = 8'd 79;  // 337.50°
    sin_lut_table[241] = 8'd 82;
    sin_lut_table[242] = 8'd 85;
    sin_lut_table[243] = 8'd 88;
    sin_lut_table[244] = 8'd 91;
    sin_lut_table[245] = 8'd 94;
    sin_lut_table[246] = 8'd 97;
    sin_lut_table[247] = 8'd100;
    sin_lut_table[248] = 8'd103;  // 348.75°
    sin_lut_table[249] = 8'd106;
    sin_lut_table[250] = 8'd109;
    sin_lut_table[251] = 8'd112;
    sin_lut_table[252] = 8'd116;
    sin_lut_table[253] = 8'd119;
    sin_lut_table[254] = 8'd122;
    sin_lut_table[255] = 8'd125;
end

// 取相位累加器高8位作为查找表索引
assign sin_lut = sin_lut_table[phase_acc[31:24]];

// 3. 方波生成：相位高8位大于127输出255，否则输出0
assign square_wave = (phase_acc[31:24] > 8'd127) ? 8'd255 : 8'd0;

// 4. 三角波生成：0~127线性递增，128~255线性递减
assign triangle_wave = (phase_acc[31:24] <= 8'd127) ?
                       (phase_acc[31:24] << 1) :
                       (8'd255 - ((phase_acc[31:24] - 8'd128) << 1));

// 5. 波形选择与输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dds_out <= 8'd0;
    end else begin
        case(wave_sel)
            2'b00: dds_out <= sin_lut;
            2'b01: dds_out <= square_wave;
            2'b10: dds_out <= triangle_wave;
            default: dds_out <= sin_lut;
        endcase
    end
end

endmodule
