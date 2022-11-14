`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/12 16:34:20
// Design Name: 
// Module Name: ProgramCounter
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


module ProgramCounter(
    input reset, 
    input clock, 
    input jumpEnabled, 
    input [31:0] jumpInput,
    output [31:0] pcValue
    );
    
    reg [31:0] pc;
    assign pcValue = pc;
    
    always @(posedge clock)
    begin
        #5;
        if(reset)
            pc <= 32'h3000;
        else if(jumpEnabled)
            pc <= jumpInput;
        else
        begin
            pc <= pc + 32'h4;
        end
    end

endmodule
