`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/55 17:20:00
// Design Name: bidirection_io
// Module Name: bidirection_io
// Project Name:bidirection_io
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: bidirection_io
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:三态门
//////////////////////////////////////////////////////////////////////////////////
module bidirection_io
#(				
    parameter   DATA_WIDTH   =   8   
)
(
    
    inout   [DATA_WIDTH - 1:0]  io_data      ,
    input                       direction    ,//1 input ，0 output
                                              
    input   [DATA_WIDTH - 1:0]  i_data       ,
    output  [DATA_WIDTH - 1:0]  o_data       
    
);
/**********************************************************************************/
assign  o_data = io_data    ;
assign  i_data = (~direction) ? o_data : 'bz;


endmodule









