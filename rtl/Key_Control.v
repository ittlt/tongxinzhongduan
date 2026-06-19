// 按键消抖与频率控制模块（简洁版 - 延时消抖）
module Key_Control(
    input           clk,
    input           rst_n,
    input [2:0]     key_in,
    output reg [31:0]fcw,
    output reg [1:0]wave_sel,
    output reg      key_vilad,
    output reg      wave_sel_update
);

reg [19:0] cnt [0:2];
reg [2:0]  key_db;
reg [2:0]  key_db_prev;
reg key_u;
reg wave_sel_u;

integer i;

parameter FCW_DEFAULT = 32'd0;
parameter FCW_STEP    = 32'd107374;
parameter FCW_MIN     = 32'd10737;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key_db      <= 3'b111;
        key_db_prev <= 3'b111;
        for(i=0; i<3; i=i+1) cnt[i] <= 20'd0;
    end else begin
        key_db_prev <= key_db;
        for(i=0; i<3; i=i+1) begin
            if(key_in[i] == key_db[i])
                cnt[i] <= 20'd0;
            else if(cnt[i] < 20'd1_000_000)
                cnt[i] <= cnt[i] + 20'd1;
            else
                key_db[i] <= key_in[i];
        end
    end
end

wire [2:0] key_fall = key_db_prev & (~key_db);

reg [31:0] fcw_reg;
reg [1:0]  wave_sel_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcw_reg      <= FCW_DEFAULT;
        wave_sel_reg <= 2'b00;
        key_u        <= 1'b0;
        wave_sel_u   <= 1'b0;
    end else begin
        key_u      <= 1'b0;
        wave_sel_u <= 1'b0;
        case(key_fall)
            3'b001: begin
                fcw_reg <= FCW_STEP;
                key_u <= 1'b1;
            end
            3'b010: begin
                fcw_reg <= -FCW_STEP;
                key_u <= 1'b1;
            end
            3'b100: begin
                wave_sel_reg <= (wave_sel_reg == 2'b10) ? 2'b00 : wave_sel_reg + 2'd1;
                wave_sel_u <= 1'b1;
            end
            default: begin fcw_reg <= fcw_reg; wave_sel_reg <= wave_sel_reg; end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcw             <= FCW_DEFAULT;
        wave_sel        <= 2'b00;
        key_vilad       <= 1'b0;
        wave_sel_update <= 1'b0;
    end else begin
        fcw             <= fcw_reg;
        wave_sel        <= wave_sel_reg;
        key_vilad       <= key_u;
        wave_sel_update <= wave_sel_u;
    end
end

endmodule
