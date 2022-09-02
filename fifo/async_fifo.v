`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/27 17:20:00
// Design Name: async_fifo
// Module Name: async_fifo
// Project Name:async_fifo
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: test async_fifo on the board of zynq7010
// 
// Dependencies: 1 latancy
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module async_fifo
#(				
    parameter   ADDR_WIDTH   =   4 ,
    parameter   DATA_WIDTH   =   8   
)
(
    input                               i_wrst_n  		,
    input                               i_wclk    		,
    input                               i_w_en  		,
	input   [DATA_WIDTH - 1:0]          i_wdata    		,
  	output   						    o_wfull		    ,
	
	input                               i_rrst_n  		,
    input                               i_rclk    		,
    input                               i_r_en  		,
	output  [DATA_WIDTH - 1:0]          o_rdata    		,
  	output   						    o_rempty		  	 
);
/**********************************************************************************/
localparam  depth   =   1 << ADDR_WIDTH ;

integer     i   ;
/*********************************reg and wire define******************************/                    
reg		[ADDR_WIDTH    :0]	count					   ;
reg		[ADDR_WIDTH - 1:0]	wr_addr					   ;
reg		[ADDR_WIDTH - 1:0]	rd_addr					   ;

reg							wfull					   ;                  
reg		[ADDR_WIDTH    :0]	wbin					   ;
reg     [ADDR_WIDTH    :0]  wptr                       ;

reg							rempty					   ;                  
reg		[ADDR_WIDTH    :0]	rbin					   ;
reg     [ADDR_WIDTH    :0]  rptr                       ;

reg		[ADDR_WIDTH    :0]	wq1_rptr				   ;
reg		[ADDR_WIDTH    :0]	wq2_rptr				   ;
reg		[ADDR_WIDTH    :0]	rq1_wptr				   ;
reg		[ADDR_WIDTH    :0]	rq2_wptr				   ;


wire						ram_wr_en				   ;
wire						ram_rd_en				   ;
// wire						wfull					   ;
// wire						rempty					   ;
wire	[ADDR_WIDTH - 1:0]	waddr					   ;
wire	[ADDR_WIDTH - 1:0]	raddr					   ;
// wire	[ADDR_WIDTH    :0]	wptr					   ;
// wire	[ADDR_WIDTH    :0]	rptr					   ;
wire						duam_ram_en				   ;
wire						wfull_val				   ;
wire	[ADDR_WIDTH    :0]	wgraynext				   ;
wire	[ADDR_WIDTH    :0]	wbinnext				   ;
wire						rempty_val				   ;
wire	[ADDR_WIDTH    :0]	rgraynext				   ;
wire	[ADDR_WIDTH    :0]	rbinnext				   ;
/********************************main code*****************************************/
/*
*dual ram_rd_en
*/
DualRAM
#(				
    .ADDR_WIDTH   (ADDR_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH)  
)
u_DualRAM(
    .wrst_n  	(i_wrst_n	),
    .wclk       (i_wclk		),
    .wren      	(i_w_en		), 
    .waddr      (waddr		),
    .wdata      (i_wdata	),      
    .rden       (i_r_en		),
    .raddr      (raddr		),

    .rdata      (o_rdata	)
);

assign	o_rempty 	= rempty			;
assign	o_wfull 	= wfull				;
assign	duam_ram_en = i_w_en & (~wfull)	;
/*
*检测满、空状态之前，将指针同步到其他时钟域
*/
always @(posedge i_wclk or negedge i_wrst_n)begin
if(!i_wrst_n)
    {wq2_rptr , wq1_rptr}    <=  0                     ;
else    
    {wq2_rptr , wq1_rptr}    <=  {wq1_rptr , rptr  }   ;
end

always @(posedge i_rclk or negedge i_rrst_n)begin
if(!i_rrst_n)
    {rq2_wptr , rq1_wptr}    <=  0                     ;
else    
    {rq2_wptr , rq1_wptr}    <=  {rq1_wptr ,   wptr}   ;
end
/*
*空满比较逻辑
*/
///满信号产生及地址传递
//gray码计数逻辑                                   
assign wbinnext 	= (~wfull) ? (wbin + i_w_en) : wbin;
assign wgraynext	= (wbinnext >> 1) ^  wbinnext  	   ;	//二进制到gray码的转换
assign waddr		= wbin[ADDR_WIDTH - 1:0]  		   ;

assign wfull_val	= (wgraynext == {~wq2_rptr[ADDR_WIDTH : ADDR_WIDTH -1],wq2_rptr[ADDR_WIDTH - 2: 0]})  	   ;													    
//renew address
always @(posedge i_rclk or negedge i_rrst_n)begin
if(!i_rrst_n) begin
    wbin          	<=  0                    ;	 
	wptr          	<=  0                    ;	 
	end
else  begin  
    wbin          	<=  wbinnext             ;	 
	wptr          	<=  wgraynext            ;	
	end
end

always @(posedge i_rclk or negedge i_rrst_n)begin
if(!i_rrst_n) begin
    wfull          	<=  0                    ;	  
	end
else  begin  
    wfull          	<=  wfull_val           ;	 
	end
end
///空信号产生及地址传递
//gray码计数逻辑                                   
assign rbinnext 	= (~rempty) ? (rbin + i_r_en) : rbin   ;
assign rgraynext	= (rbinnext >> 1) ^  rbinnext  		   ;	//二进制到gray码的转换
assign raddr		= rbin[ADDR_WIDTH - 1:0]  		  	   ;

assign rempty_val	= (rgraynext == rq2_wptr)  		   	   ;
													    
//renew address
always @(posedge i_rclk or negedge i_rrst_n)begin
if(!i_rrst_n) begin
    rbin          	<=  0                    ;	 
	rptr          	<=  0                    ;	 
	end
else  begin  
    rbin          	<=  rbinnext             ;	 
	rptr          	<=  rgraynext            ;	
	end
end

always @(posedge i_rclk or negedge i_rrst_n)begin
if(!i_rrst_n) begin
    rempty          <=  1                    ;	  
	end
else  begin  
    rempty          <=  rempty_val           ;	 
	end
end

endmodule
