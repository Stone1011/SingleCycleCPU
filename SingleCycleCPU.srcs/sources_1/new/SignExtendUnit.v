`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/12 21:32:20
// Design Name: 
// Module Name: SignExtendUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SignExtendUnit(
    input [15:0] in,
    output [31:0] out
    );

    assign out[15:0] = in;
    assign out[31:16] = in[15] ? 16'hffff : 16'h0000;

endmodule
