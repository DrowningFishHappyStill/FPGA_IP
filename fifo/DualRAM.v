`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/27 17:20:00
// Design Name: DualRAM
// Module Name: DualRAM
// Project Name:SingalPortRam,,,simple dual port ram
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: simple dual port ram
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:读写冲突时，写穿通到读
//////////////////////////////////////////////////////////////////////////////////
module DualRAM
#(				
    parameter   ADDR_WIDTH   =   9 ,
    parameter   DATA_WIDTH   =   8   
)
(
    input                               wrst_n  	,
    input                               wclk        ,
	
    input                               wren      	,
    input   [ADDR_WIDTH - 1:0]          waddr       ,
    input   [DATA_WIDTH - 1:0]          wdata       ,        
    input                               rden        ,
    input   [ADDR_WIDTH - 1:0]          raddr       ,


    output  [DATA_WIDTH - 1:0]          rdata       	
);
/**********************************************************************************/
localparam  depth   =   1 << ADDR_WIDTH ;

integer     i   ;
/*********************************reg and wire define******************************/
reg     [DATA_WIDTH - 1:0]  data_buffer[depth - 1:0]   ;                    

/********************************main code*****************************************/
// assign  dout = (wr_conflict == 1'b1) ? din_d1 : dout_buff   ;
assign  rdata = data_buffer[raddr]   	;
assign  rdata = data_buffer[raddr]   	;
assign  rdata = data_buffer[raddr]   	;

//
always @(posedge wclk or negedge wrst_n)begin
if(!wrst_n)
    for(i = 0; i < depth ;i = i + 1)
        data_buffer[i]     <= 0                	;
else if(wren) 
    data_buffer[waddr]     <= wdata             ;
else
    data_buffer[waddr]     <= data_buffer[waddr];  
end

// always @(posedge clkb or negedge rst_n)begin
// if(!wrst_n)
    // dout_buff             <=  0                   ;
// else if(rd_en)   
    // dout_buff             <= data_buffer[rd_addr] ;
// else
    // dout_buff             <=  dout_buff           ;  
// end


endmodule









