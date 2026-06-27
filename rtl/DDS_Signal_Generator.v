// DDS_Signal_Generator.v
// Synthesis version: ILA removed to save PL resources (for PS boot flow)
// PLL enabled: 50MHz input -> 100MHz internal clock

module DDS_Signal_Generator(
    input           clk_50mhz,
    input           rst_n,
    input [2:0]     key_in,
    input           uart_rx,
    output [7:0]    dds_out,
    output          uart_tx,
    output          led_sys,
    output          led_uart,
    output          dds_clk
);

wire [31:0] fcw_key;
wire [1:0]  wave_sel;
reg  [31:0] fcw_sel;
wire        key_vilad;
wire        wave_sel_update;

wire [31:0] fcw_uart;
wire        fcw_update;

// 1. PLL 50MHz -> 100MHz
pll_50m_to_100m pll_inst(
    .clk_in1(clk_50mhz),
    .clk_out1(clk_100mhz),
    .resetn(rst_n),
    .locked(led_sys)
);

// 2. DAC reset
assign dds_clk = clk_50mhz;

// 3. Key Control
Key_Control key_ctrl_inst(
    .clk(clk_100mhz),
    .rst_n(rst_n),
    .key_in(key_in),
    .fcw(fcw_key),
    .wave_sel(wave_sel),
    .key_vilad(key_vilad),
    .wave_sel_update(wave_sel_update)
);

// 4. HMI UART Receive
HMI_Recv hmi_recv_inst(
    .clk(clk_100mhz),
    .rst_n(rst_n),
    .HMI_RX(uart_rx),
    .HMI_Num(fcw_uart),
    .HMI_Done(fcw_update)
);

assign led_uart = 1'b0;

// 5. FCW select
always @(posedge clk_100mhz or negedge rst_n) begin
    if(!rst_n)
        fcw_sel <= 32'd10737418;
    else if(fcw_update)
        fcw_sel <= fcw_uart;
    else if(key_vilad)
        fcw_sel <= fcw_sel + fcw_key;
end

// 6. DDS Core
DDS_Core dds_core_inst(
    .clk(clk_100mhz),
    .rst_n(rst_n),
    .fcw(fcw_sel),
    .wave_sel(wave_sel),
    .dds_out(dds_out)
);

// 7. UART TX - send frequency/waveform info back
reg        uart_tx_en;
reg  [7:0] uart_tx_data;

HMI_UARTX u_uart_tx (
    .sys_clk    (clk_100mhz),
    .sys_rst_n  (rst_n),
    .pi_data    (uart_tx_data),
    .pi_flag    (uart_tx_en),
    .tx         (uart_tx)
);

// 5ms interval @ 100MHz = 500,000 cycles
localparam BYTE_INTERVAL = 32'd500_000 - 1;

// Edge detection for fcw_update, key_vilad, wave_sel_update
reg fcw_update_d, key_vilad_d, wave_sel_update_d;
wire fcw_update_rise     = fcw_update     & ~fcw_update_d;
wire key_vilad_rise      = key_vilad      & ~key_vilad_d;
wire wave_sel_update_rise = wave_sel_update & ~wave_sel_update_d;

always @(posedge clk_100mhz or negedge rst_n) begin
    if (!rst_n) begin
        fcw_update_d      <= 1'b0;
        key_vilad_d       <= 1'b0;
        wave_sel_update_d <= 1'b0;
    end else begin
        fcw_update_d      <= fcw_update;
        key_vilad_d       <= key_vilad;
        wave_sel_update_d <= wave_sel_update;
    end
end

// Capture pending flag
reg capture_pending;
always @(posedge clk_100mhz or negedge rst_n) begin
    if (!rst_n)
        capture_pending <= 1'b0;
    else if (fcw_update_rise || key_vilad_rise || wave_sel_update_rise)
        capture_pending <= 1'b1;
    else
        capture_pending <= 1'b0;
end

// UART TX state machine - send waveform type + 6-digit BCD frequency
reg [31:0] fcw_send_buf;
reg [31:0] byte_timer;
reg [3:0]  byte_idx;
reg        sending;
reg        first_send_done;
reg [1:0]  wave_sel_buf;

// Calculate frequency: freq = fcw * f_clk / 2^32
// f_clk = 100MHz = 100_000_000, >>32
wire [63:0] freq_product = fcw_send_buf * 32'd100_000_000;
wire [31:0] freq_hz      = freq_product[63:32];

// BCD conversion
wire [3:0] bcd [0:5];
assign bcd[0] = freq_hz % 10;
assign bcd[1] = (freq_hz / 10)      % 10;
assign bcd[2] = (freq_hz / 100)     % 10;
assign bcd[3] = (freq_hz / 1000)    % 10;
assign bcd[4] = (freq_hz / 10000)   % 10;
assign bcd[5] = (freq_hz / 100000)  % 10;

always @(posedge clk_100mhz or negedge rst_n) begin
    if (!rst_n) begin
        uart_tx_en      <= 1'b0;
        uart_tx_data    <= 8'd0;
        byte_timer      <= 32'd0;
        byte_idx        <= 4'd0;
        sending         <= 1'b0;
        first_send_done <= 1'b0;
        fcw_send_buf    <= 32'd0;
        wave_sel_buf    <= 2'b00;
    end else begin
        uart_tx_en <= 1'b0;

        if (!sending) begin
            if (!first_send_done || capture_pending) begin
                fcw_send_buf    <= fcw_sel;
                wave_sel_buf    <= wave_sel;
                byte_idx        <= 4'd0;
                byte_timer      <= 32'd0;
                sending         <= 1'b1;
                first_send_done <= 1'b1;
            end
        end else begin
            if (byte_timer == BYTE_INTERVAL) begin
                byte_timer <= 32'd0;

                case (byte_idx)
                    // Waveform type: SIN / SQU / TRI
                    4'd0: begin
                        case (wave_sel_buf)
                            2'b00: uart_tx_data <= 8'h53; // 'S'
                            2'b01: uart_tx_data <= 8'h53; // 'S'
                            2'b10: uart_tx_data <= 8'h54; // 'T'
                            default: uart_tx_data <= 8'h53;
                        endcase
                    end
                    4'd1: begin
                        case (wave_sel_buf)
                            2'b00: uart_tx_data <= 8'h49; // 'I'
                            2'b01: uart_tx_data <= 8'h51; // 'Q'
                            2'b10: uart_tx_data <= 8'h52; // 'R'
                            default: uart_tx_data <= 8'h49;
                        endcase
                    end
                    4'd2: begin
                        case (wave_sel_buf)
                            2'b00: uart_tx_data <= 8'h4E; // 'N'
                            2'b01: uart_tx_data <= 8'h55; // 'U'
                            2'b10: uart_tx_data <= 8'h49; // 'I'
                            default: uart_tx_data <= 8'h4E;
                        endcase
                    end
                    // 6-digit BCD frequency
                    4'd3: uart_tx_data <= 8'h30 + bcd[5];
                    4'd4: uart_tx_data <= 8'h30 + bcd[4];
                    4'd5: uart_tx_data <= 8'h30 + bcd[3];
                    4'd6: uart_tx_data <= 8'h30 + bcd[2];
                    4'd7: uart_tx_data <= 8'h30 + bcd[1];
                    4'd8: uart_tx_data <= 8'h30 + bcd[0];
                    4'd9: uart_tx_data <= 8'h0D;
                    4'd10: uart_tx_data <= 8'h0A;
                    default: ;
                endcase
                uart_tx_en <= 1'b1;

                if (byte_idx == 4'd10) begin
                    sending  <= 1'b0;
                    byte_idx <= 4'd0;
                end else begin
                    byte_idx <= byte_idx + 1'b1;
                end
            end else begin
                byte_timer <= byte_timer + 1'b1;
            end
        end
    end
end

// ILA removed for synthesis (saves PL resources)
// For debug, add ILA in DDS_Signal_Generator_top if needed

endmodule
