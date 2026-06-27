
//////////////////////Function//////////////////
//�������������ݽ�????
///////////////Time????2019.7.21////////////

module HMI_Recv(
input wire clk,
input wire HMI_RX,
input wire rst_n,
output reg [31:0] HMI_Num,	//�ϲ������???��????(0~999999)
output reg HMI_Done		//�����������
);

wire [7:0]Data_RX;
wire Wrsig;

reg [7:0] i;
reg wrsigbuf;
reg wrsigrise;
reg [7:0] dig [0:5];	//��ʱ�洢6��ASCII����

HMI_UARX U1
(
	.sys_clk (clk),
	.sys_rst_n (rst_n),
	.uart_rxd (HMI_RX),
	.uart_done (Wrsig),
	.uart_data (Data_RX)
);

always @(posedge clk)
begin
   wrsigbuf <= Wrsig;
   wrsigrise <= (~wrsigbuf) & Wrsig;
end

//always@(posedge clk)begin
//if(wrsigrise)begin
//case(i)

//0:if(Data_RX==8'h46) i<=1;//��ʼ???? 'F'
//1:begin dig[0]<=Data_RX; i<=2; end	//????1λ��????
//2:begin dig[1]<=Data_RX; i<=3; end	//????2λ��????
//3:begin dig[2]<=Data_RX; i<=4; end	//????3λ��????
//4:begin dig[3]<=Data_RX; i<=5; end	//????4λ��????
//5:begin dig[4]<=Data_RX; i<=6; end	//????5λ��????
//6:begin dig[5]<=Data_RX; i<=7; end	//????6λ��????
//7:i<=8;  //�ȴ�dig[5]�ȶ�
//8:if(Data_RX==8'h0D || Data_RX==8'h0A) begin  //�س����ж����Խ���
//	i<=9;
//	HMI_Num <= (dig[0]-8'h30)*32'd4294967 + (dig[1]-8'h30)*32'd429497 +
//	           (dig[2]-8'h30)*32'd42950    + (dig[3]-8'h30)*32'd4295 +
//	           (dig[4]-8'h30)*32'd429       + (dig[5]-8'h30) * 32'd42;
//	HMI_Done<=1'b1;
//	end
//9:begin//�ȴ�dig[5]�ȶ�
	
//	HMI_Done<=1'b0;
//	i<=0;
//	end
////10:begin//����??
////	i<=0;
////	HMI_Done<=1'b0;
////	end
//default:i<=i+1;

//endcase
//end
//end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i        <= 8'd0;
        HMI_Done <= 1'b0;
        HMI_Num  <= 32'd0;
        dig[0]   <= 8'd0;
        dig[1]   <= 8'd0;
        dig[2]   <= 8'd0;
        dig[3]   <= 8'd0;
        dig[4]   <= 8'd0;
        dig[5]   <= 8'd0;
    end else if (wrsigrise) begin
        case (i)
            // ״̬0���ȴ�֡ͷ 'F' (0x46)
            0 : begin
                    HMI_Done <= 1'b0;
                    if (Data_RX == 8'h46)
                        i <= 1;
                    else
                        i <= 0;
                end

            // ״̬1~6������6λ����
            1 : begin dig[0] <= Data_RX; HMI_Done <= 1'b0; i <= 2; end
            2 : begin dig[1] <= Data_RX; HMI_Done <= 1'b0; i <= 3; end
            3 : begin dig[2] <= Data_RX; HMI_Done <= 1'b0; i <= 4; end
            4 : begin dig[3] <= Data_RX; HMI_Done <= 1'b0; i <= 5; end
            5 : begin dig[4] <= Data_RX; HMI_Done <= 1'b0; i <= 6; end
            6 : begin dig[5] <= Data_RX; HMI_Done <= 1'b0; i <= 7; end

            // ״̬7���жϽ��������س�0x0D����0x0A���ɽ�����
            7 : begin
                    if (Data_RX == 8'h0D || Data_RX == 8'h0A) begin
                        HMI_Num <= (dig[0]-8'h30)*32'd4294967 +
                                   (dig[1]-8'h30)*32'd429497  +
                                   (dig[2]-8'h30)*32'd42950   +
                                   (dig[3]-8'h30)*32'd4295    +
                                   (dig[4]-8'h30)*32'd429     +
                                   (dig[5]-8'h30) * 32'd42;
                        HMI_Done <= 1'b1;
                        i <= 8;
                    end else begin
                        HMI_Done <= 1'b0;
                        i <= 0;        // �쳣�ַ����ص�״̬0����Ѱ�� 'F'
                    end
                end

            // ״̬8����ɱ�־����
            8 : begin
                    HMI_Done <= 1'b0;
                    i <= 0;
                end

            // ����״̬���ص�0
            default : begin
                    HMI_Done <= 1'b0;
                    i <= 0;
                end
        endcase
    end
end
endmodule