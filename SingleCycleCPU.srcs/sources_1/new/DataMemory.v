`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/12 16:36:52
// Design Name: 
// Module Name: DataMemory
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

// DataMemory, capacity 4 Bytes * 1024
// Synchronized Reset Signal
// Clock Posetive Edge Write
// Asynchronized Read

module DataMemory(
    input reset, 
    input clock, 
    input [31:0] address, 
    input writeEnabled, 
    input readEnabled,
    input [31:0] writeInput,
    output [31:0] readResult
    );

    reg [31:0] data [1023:0];
    integer i;

    always @(posedge clock)
    begin
        if(reset)
        begin
            for(i = 0; i < 1024; i = i + 1)
                data[i] <= 32'b0;
        end
        else if(writeEnabled)
        begin
            data[address[31:2]] <= writeInput;
        end
    end

    assign readResult = readEnabled ? data[address[31:2]] : 32'b0;

endmodule
