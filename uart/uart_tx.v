`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/15 19:00:00
// Design Name: UART_TX
// Module Name: uart_tx
// Project Name:uart_tx
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: test uart_tx on the board of zynq7010
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//notice:组合逻辑不包含触发器
//              if(en_flag)
//					nex_sta	<=	send;
//				else
//					nex_sta	<=	idle;
//nex_sta	<=	nex_sta;错
//////////////////////////////////////////////////////////////////////////////////
module uart_tx
#(
	parameter			XorCheck	=	1'b0	  ,
	parameter			ClkFre		=	50_000_000,
	parameter			BaudRate	=	115200	  
	
)
(
	input	     		clk				,
	input	     		rst_n			,
	
	input				tx_en			,
	input  [7:0]		tx_data			,
	output reg	     	uart_tx			,
	output				tx_busy					 
    );
/*************parameter define**************/
localparam	Bps			= 	(ClkFre/BaudRate)		;


localparam   idle		=	4'b0001;
localparam   send		=	4'b0010;
localparam   check		=	4'b0100;
localparam   stop		=	4'b1000;
/*************reg and wire define***********/	
	
reg		[31:0]	cnt_bps				;
reg		[3:0]	cur_sta,nex_sta		;//current state and next state	
reg		        tx_en_d1,tx_en_d2	;
reg		[7:0]	tx_data_d1			;
reg				clr_cnt_flag		;
reg		[3:0]	cnt_bit				;
reg				Xor					;
reg			    sta_flag			;

wire            en_flag             ;

/*************main code********************/

ila_1 u_ila_1 (
	.clk(clk), // input wire clk


	.probe0(cur_sta), // input wire [3:0] probe0
	.probe1(tx_en), // input wire [0:0]  probe1 
	.probe2(uart_tx), // input wire [0:0]  probe2
	.probe3(en_flag),
	.probe4(cnt_bps),
	.probe5(cnt_bit),
    .probe6(cur_sta)
);
//////uart tx
assign	tx_busy =	(cur_sta == idle) ? 1'b0 : 1'b1;
assign	en_flag	=	tx_en_d1 &(~tx_en_d2);

always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		tx_en_d1	<= 1'b0		 ;
		tx_en_d2	<= 1'b0		 ;
		end                      
	else begin                   
		tx_en_d1	<= tx_en	 ;
		tx_en_d2	<= tx_en_d1	 ;
		end 
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n) 
		cnt_bps	<= 32'd0		 ;
	else if(clr_cnt_flag)
		cnt_bps	<= 32'd0		 ;
	else if(cnt_bps < Bps - 1'b1)
		cnt_bps	<= cnt_bps + 1'b1;
	else
		cnt_bps	<= 32'd0		 ;
end

//state machine
always @(posedge clk or negedge rst_n)begin
	if(!rst_n) 
		cur_sta <= idle	  ;
	else 
		cur_sta <= nex_sta;
end

always @(*)begin
	if(!rst_n) 
		nex_sta <= idle	  ;
	else begin
		case(cur_sta)
			idle	:	begin
				if(en_flag)
					nex_sta	<=	send;
				else
					nex_sta	<=	idle;
			end
			send	:	begin
				if(cnt_bit	== 4'd9)begin
					if(XorCheck)
						nex_sta	<=	check;
					else
						nex_sta	<=	stop ;
					end
				else
					nex_sta	<=	send;
			end	
			check	:	begin
				if(sta_flag)	
					nex_sta	<=	stop;
				else
					nex_sta	<=	check;
			end
			stop	:	begin
				if(sta_flag)
					nex_sta	<=	idle;
				else
					nex_sta	<=	stop;
			end
			default:nex_sta	<=	idle;
		endcase
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		uart_tx <= 1'b1	  ;
		cnt_bit <= 4'b0   ;
		Xor		<= 1'b0   ;
		end
	else begin
		case(cur_sta)
			idle	:	begin
				uart_tx 	 <= 1'b1   ;
				clr_cnt_flag <= 1'b1   ;
				cnt_bit 	 <= 4'b0   ;
				sta_flag 	 <= 1'b0   ;
				tx_data_d1	 <= tx_data;
			end

			send	:	begin
				
				if(cnt_bps == Bps - 2'd2)	begin
					cnt_bit <= cnt_bit	+ 1'b1   				 		;
					Xor		<= Xor ^tx_data_d1[cnt_bit - 1'b1]   	    ; 
					end
				else
					cnt_bit <= cnt_bit									;
					
				if(cnt_bit	== 4'b0)begin
					uart_tx 	 <= 1'b0   		 				 		;
					clr_cnt_flag <= 1'b0   								;
					end
				else if(cnt_bit	>= 4'd1 && cnt_bit	<= 4'd8)begin
					uart_tx 	 <= tx_data_d1[cnt_bit - 1'b1]   		;
					clr_cnt_flag <= 1'b0   								;
					end
				else begin
				    uart_tx 	 <= 1'b1   								;
					clr_cnt_flag <= 1'b1   								;
					end
			end	
			check	:	begin
				uart_tx	<= Xor;		
				if(cnt_bps < Bps - 1'b1)	begin
					clr_cnt_flag <= 1'b0   								;
					sta_flag	 <= 1'b0   								;
					end
				else	begin
					clr_cnt_flag <= 1'b1   								;
					sta_flag	 <= 1'b1   								;
					end				
			end
			stop	:	begin
				uart_tx	<= 1'b1;
				if(cnt_bps < Bps - 1'b1)	begin
					clr_cnt_flag <= 1'b0   								;
					sta_flag	 <= 1'b0   								;
					end
				else	begin
					clr_cnt_flag <= 1'b1   								;
					sta_flag	 <= 1'b1   								;
					end					
			end
			default	:begin
				uart_tx <= 1'b1	  ;
				cnt_bit <= 4'b0   ;
				Xor		<= 1'b0   ;
			end
		endcase
	end			
end

endmodule
