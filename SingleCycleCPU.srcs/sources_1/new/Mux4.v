`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/14 14:44:52
// Design Name: 
// Module Name: Mux4
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


module Mux4(
    input [31:0] A0,
    input [31:0] A1,
    input [31:0] A2,
    input [31:0] A3,
    input [1:0] choice,
    output reg [31:0] result
    );

    always @(*)
    begin
        if(choice == 2'b00)
            result <= A0;
        else if(choice == 2'b01)
            result <= A1;
        else if(choice == 2'b10)
            result <= A2;
        else
            result <= A3;
    end

endmodule
