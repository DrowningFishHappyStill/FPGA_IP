`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Time Studio
// Engineer: He Jiakang
// 
// Create Date: 2022/08/55 17:20:00
// Design Name: sync_fifo
// Module Name: sync_fifo
// Project Name:sync_fifo
// Target Devices: zynq 7010 
// Tool Versions: 2018.3
// Description: test sync_fifo on the board of zynq7010
// 
// Dependencies: 1 latancy
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module sync_fifo
#(				
    parameter   ADDR_WIDTH   =   4 ,
    parameter   DATA_WIDTH   =   8   
)
(
    
    input                               i_rst_n  		,
    input                               i_clk    		,
    input                               i_wr_en  		,
    input                               i_rd_en  		,			//0:read enable,,1:write enable,,write first
    input   [DATA_WIDTH - 1:0]          i_din    		,
    output  [DATA_WIDTH - 1:0]     		o_dout   		,
	output   						    o_empty			,
  	output   						    o_full		 
);
/**********************************************************************************/
localparam  depth   =   1 << ADDR_WIDTH ;

integer     i   ;
/*********************************reg and wire define******************************/                    
reg		[ADDR_WIDTH    :0]	count					   ;
reg		[ADDR_WIDTH - 1:0]	wr_addr					   ;
reg		[ADDR_WIDTH - 1:0]	rd_addr					   ;


wire						ram_wr_en				   ;
wire							ram_rd_en				   ;

wire						full					   ;
wire						empty					   ;
/********************************main code*****************************************/
tp_ram
#(				
    .ADDR_WIDTH   (ADDR_WIDTH			) ,
    .DATA_WIDTH   (DATA_WIDTH			)   
)
u_tp_ram( 
    .rst_n       (i_rst_n	),
    .clka        (i_clk		),
    .clkb        (i_clk		),
    .wr_en       (ram_wr_en	),
    .wr_addr     (wr_addr	),
    .din         (i_din		),       
    .rd_en       (ram_rd_en	),
    .rd_addr     (rd_addr	),
    .dout        (o_dout	)
);

assign empty = (count == 0) ? 1'b1 : 1'b0 		;
assign full  = (count == depth) ? 1'b1 : 1'b0 	;
assign ram_wr_en = (i_wr_en && (~full))  ? 1'b1 : 1'b0 ;
assign ram_rd_en = (i_rd_en && (~empty)) ? 1'b1 : 1'b0 ;


always @(posedge i_clk or negedge i_rst_n)begin
if(!i_rst_n)
    count             <=  0                   ;
else if(i_wr_en && i_rd_en)   
    count             <= count   			  ;
else if(i_wr_en && (~full))
    count             <= count   + 1'b1		  ;
else if(i_rd_en && (~empty))
    count             <= count   - 1'b1		  ;
else    
    count             <= count   			  ;	
end

//renew address
always @(posedge i_clk or negedge i_rst_n)begin
if(!i_rst_n) 
    wr_addr          <=  0                    ;	 
else if(full == 0 && i_wr_en == 1 )   
    wr_addr          <=  wr_addr  + 1'b1      ; 
else    
    wr_addr          <=  0                    ;
end

always @(posedge i_clk or negedge i_rst_n)begin
if(!i_rst_n) 
    rd_addr          <=  0                    ;	 
else if(empty == 0 && i_rd_en == 1 )   
    rd_addr          <=  rd_addr  + 1'b1      ; 
else    
    rd_addr          <=  rd_addr              ;
end

endmodule









