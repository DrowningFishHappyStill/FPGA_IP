`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/22 20:00:00
// Design Name: RAM
// Module Name: RAM
// Project Name:RAM
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: test RAM on the board of zynq7010
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
module uart_rx
#(
	parameter			XorCheck	=	1'b0	  ,
	parameter			ClkFre		=	50_000_000,
	parameter			BaudRate	=	115200	  
	
)
(
	input	     		clk				,
	input	     		rst_n			,
	
	input				uart_rx			,
	output  [7:0]		rx_data			,
	output 	reg	     	rx_done			,
	output				rx_busy			,
	output	reg	 		check_err		
    );
/*************parameter define**************/
localparam	Bps			= 	(ClkFre/BaudRate)		;


localparam   idle		=	4'b0001;
localparam   recv		=	4'b0010;
localparam   check		=	4'b0100;
localparam   stop		=	4'b1000;
/*************reg and wire define***********/	
	
reg		[31:0]	cnt_bps				;
reg		[3:0]	cur_sta,nex_sta		;//current state and next state	
reg		        uart_rx_d1			;
reg		        uart_rx_d2			;
reg		[7:0]	rx_data_d1			;
reg				clr_cnt_flag		;
reg		[3:0]	cnt_bit				;
reg				Xor					;
reg			    sta_flag			;
reg				err_flag			;

wire            en_flag             ;

/*************main code********************/
ila_1 u_ila_3 (
	.clk(clk), // input wire clk


	.probe0(cur_sta), // input wire [3:0] probe0
	.probe1(uart_rx_d1), // input wire [0:0]  probe1 
	.probe2(rx_busy), // input wire [0:0]  probe2
	.probe3(en_flag),
	.probe4(cnt_bps),
	.probe5(cnt_bit),
    .probe6(rx_data_d1[3:0])
);
//////uart tx
assign	rx_busy =	(cur_sta == idle) ? 1'b0 : 1'b1;
assign	en_flag	=	uart_rx_d2 &(~uart_rx_d1);
assign	rx_data =   (cur_sta == stop)?rx_data_d1:8'd0;

always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		uart_rx_d1	<= 1'b0		 ;
		uart_rx_d2	<= 1'b0		 ;
		end                      
	else begin                   
		uart_rx_d1	<= uart_rx	 ;
		uart_rx_d2	<= uart_rx_d1;
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
					nex_sta	<=	recv;
				else
					nex_sta	<=	idle;
			end
			recv	:	begin
				if(cnt_bit	== 4'd9 && cnt_bps == (Bps - 2'd2))begin
					if(XorCheck)
						nex_sta	<=	check;
					else
						nex_sta	<=	stop ;
					end
				else
					nex_sta	<=	recv;
			end	
			check	:	begin
				if(sta_flag)	
					nex_sta	<=	stop;
				else
					nex_sta	<=	check;
			end
			stop	:	begin
				if(cnt_bps == (Bps/2 + 2'd3))
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
		rx_data_d1	 	<= 8'd0   ;
		cnt_bit 		<= 4'b0   ;
		Xor				<= 1'b0   ;
		sta_flag 	 	<= 1'b0   ;
		err_flag	 	<= 1'b0   ;
		rx_done			<= 1'b0	  ;
		check_err		<= 1'b0	  ;
		clr_cnt_flag 	<= 1'b0   ;
		end
	else begin
		case(cur_sta)
			idle	:	begin			
				clr_cnt_flag <= 1'b1   ;
				cnt_bit 	 <= 4'b0   ;
				sta_flag 	 <= 1'b0   ;
				rx_data_d1	 <= 8'd0   ;
				err_flag	 <= 1'b0   ;
			end
			recv	:	begin	
				clr_cnt_flag 	<= 1'b0;
				if(cnt_bps == (Bps/2))	begin
					cnt_bit 	<= cnt_bit	+ 1'b1   				 	;
					Xor			<= Xor ^uart_rx_d1					  	;
					rx_data_d1	<= {uart_rx_d1,rx_data_d1[7:1]}			;
					end
				else	begin
					cnt_bit 	<= cnt_bit								;
					rx_data_d1	<= rx_data_d1                           ;
					end				
			end	
			check	:	begin
				if(cnt_bps == (Bps/2))	begin
					sta_flag	 <= 1'b1   								;
					if(Xor == rx_data_d1)
						err_flag	 <= 1'b0   							;
					else
						err_flag	 <= 1'b1   							;
					end
				else	begin
						err_flag	 <= err_flag   						;
						sta_flag	 <= 1'b0   							;		
					end
			end
			stop	:	begin
				if(cnt_bps == (Bps/2))	begin					
//					sta_flag	 <= 1'b1   								;
					rx_done		 <= 1'b1								;
					if(err_flag)
						check_err<= 1'b1								;	
					else if(rx_data_d1 == 1'b0)
						check_err<= 1'b1								;
					else
						check_err<= 1'b0								;
					end
				else	begin					
//					sta_flag	 <= 1'b0   								;
					rx_done		 <= 1'b0								;
					end					
			end
			default	:begin
				cnt_bit <= 4'b0   ;
				Xor		<= 1'b0   ;
			end
		endcase
	end			
end

endmodule