`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/12 16:37:53
// Design Name: 
// Module Name: InstructionMemory
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

// READ_ONLY MEMORY for instructions

module InstructionMemory(
    input [31:0] address,
    output [31:0] readResult
    );

    reg [31:0] data [1023:0];

    initial
    begin
        $readmemh("C:\\CPU\\mips1.txt", data);
    end

    // always @(*)
    // begin
    //     readResult = data[address[31:2]];
    // end

    assign readResult = data[address[11:2]];

endmodule
