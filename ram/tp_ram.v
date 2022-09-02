`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/55 17:20:00
// Design Name: SP_RAM
// Module Name: tp_ram
// Project Name:SingalPortRam,,,simple dual port ram
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: simple dual port ram
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module tp_ram
#(				
    parameter   ADDR_WIDTH   =   9 ,
    parameter   DATA_WIDTH   =   8   
)
(
    
    input                               rst_n       ,
    input                               clka        ,
    input                               clkb        ,
    input                               wr_en       ,
    input   [ADDR_WIDTH - 1:0]          wr_addr     ,
    input   [DATA_WIDTH - 1:0]          din         ,        
    input                               rd_en       ,
    input   [ADDR_WIDTH - 1:0]          rd_addr     ,
    output  [DATA_WIDTH - 1:0]          dout        
);
/**********************************************************************************/
localparam  depth   =   1 << ADDR_WIDTH ;

integer     i   ;
/*********************************reg and wire define******************************/
reg     [DATA_WIDTH - 1:0]  data_buffer[depth - 1:0]   ;                    
reg                         wr_conflict                ;

reg     [DATA_WIDTH - 1:0]  din_d1                     ;  
reg     [DATA_WIDTH - 1:0]  dout_buff                  ;
/********************************main code*****************************************/
assign  dout = (wr_conflict == 1'b1) ? din_d1 : dout_buff   ;

always @(posedge clkb or negedge rst_n)begin
if(!rst_n)
    din_d1                   <= 0                 ;       
else
    din_d1                   <= din               ;   
end

always @(posedge clkb or negedge rst_n)begin
if(!rst_n)
    wr_conflict              <= 1'b0              ;       
else if(wr_en && rd_en && (wr_addr == rd_addr) )
    wr_conflict              <= 1'b1              ;  
else
    wr_conflict              <= 1'b0              ;  
end

always @(posedge clka or negedge rst_n)begin
if(!rst_n)
    for(i = 0; i < depth ;i = i + 1)
        data_buffer[i]          <= 0                   ;
else if(wr_en) 
    data_buffer[wr_addr]     <= din                 ;
else
    data_buffer[wr_addr]     <= data_buffer[wr_addr];  
end

always @(posedge clkb or negedge rst_n)begin
if(!rst_n)
    dout_buff             <=  0                   ;
else if(rd_en)   
    dout_buff             <= data_buffer[rd_addr] ;
else
    dout_buff             <=  dout_buff           ;  
end


endmodule









