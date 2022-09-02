`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/55 17:20:00
// Design Name: SP_RAM
// Module Name: sp_ram
// Project Name:SingalPortRam
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: test uart_tx on the board of zynq7010
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module sp_ram
#(				
    parameter   ADDR_WIDTH   =   9 ,
    parameter   DATA_WIDTH   =   8   
)
(
    
    input                               rst_n     ,
    input                               clk     ,
    input                               en      ,
    input                               wen     ,//0:read enable,,1:write enable,,write first
    input   [DATA_WIDTH - 1:0]          din     ,
    input   [ADDR_WIDTH - 1:0]          addr    ,
    
    output  reg  [DATA_WIDTH - 1:0]     dout    
);
/**********************************************************************************/
localparam  depth   =   1 << ADDR_WIDTH ;

integer     i   ;
/*********************************reg and wire define******************************/
reg     [DATA_WIDTH - 1:0]  data_buffer[depth - 1:0]   ;                    

/********************************main code*****************************************/
always @(posedge clk or negedge rst_n)begin
if(!rst_n)
    for(i = 0; i < depth ;i = i + 1)
        data_buffer[i]       <= 0                   ;
else if(en  && wen) 
    data_buffer[addr]       <= din                  ;
else
    data_buffer[addr]       <= data_buffer[addr]    ;  
end

always @(posedge clk or negedge rst_n)begin
if(!rst_n)
    dout             <=  0                   ;
else if(en && (~wen))   
    dout             <= data_buffer[addr]    ;
else
    dout             <=  0                   ;  
end


endmodule









