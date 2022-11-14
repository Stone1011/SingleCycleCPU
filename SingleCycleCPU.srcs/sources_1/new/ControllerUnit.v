`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/12 17:37:47
// Design Name: 
// Module Name: ControllerUnit
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

// addu: 000000, rs, rt, rd, 00000, 100001 => rd := rs + rt
// subu: 000000, rs, rt, rd, 00000, 100011 => rd := rs - rt
// ori:  001101, rs, rt, 16'imm => rt := rs or imm
// lw:   100011, base(rs), rt, offset(imm) => rt := M[base+offset]
// sw:   101011, base(rs), rt, offset(imm) => M[base+offset] := rt
// beq:  000100, rs, rt, offset(imm) => if rs=rt then PC = PC + offset
// lui:  001111, 00000, rt, imm => rt := (imm<<16) | 0
// jal:  000011, target  => ($ra := PC + 8;) PC := PC[31:28] | target[25:0] | 2'b00
// jr:   000000, rs, 00000 00000, hint, 001000 => PC := rs
// syscall: 000000, [19:0] code, 001100 => $finish

module ControllerUnit(
    input [5:0] Op,
    input [5:0] Func,
                            // 0 & 1
    output reg RegDst,      // Rt & Rd for GR write
    output reg RegWrite,    // no-write & write
    output reg ALUSrc,      // GR[rt] & SignExt of imm
    // output reg PCSrc,       // PC+4 & beq
    output reg MemRead,     // no-read & read from DM
    output reg MemWrite,    // no-write & write into DM
    output reg MemToReg,    // ALU into GR & DM into GR
    // output reg [1:0] ALUop, // ALU controller signal  
    output reg Branch       // is branch
    );

    always @(*)
    begin
        // RegDst
        if(Op == 6'b000000 && Func != 6'b001100 && Func != 6'b001000)
            RegDst <= 1; // R-i
        else if(Op == 6'b000000 && Func == 6'b001100)
        begin
            #4.2;
            $finish; // syscall
        end
        else if(Op == 6'b100011 || Op == 6'b001101 || Op == 6'b000011)
            RegDst <= 0; // lw or ori or jal
        else
            RegDst <= 0; // lui

        // RegWrite: lw or ori or jal or lui or R
        if(Op == 6'b000000 || Op == 6'b100011 || Op == 6'b001101 || Op == 6'b000011 || Op == 6'b001111)
            RegWrite <= 1;
        else
            RegWrite <= 0;
        
        // ALUSrc
        if(Op == 6'b000000 || Op == 6'b000100)
            ALUSrc <= 0; // R-i or beq
        else if(Op == 6'b000011)
            ALUSrc <= 1; // jal
        else if(Op == 6'b100011 || Op == 6'b101011)
            ALUSrc <= 1; // lw or sw
        else
            ALUSrc <= 1;
        
        // PCSrc
        // Implemented in Top Level

        // MemRead
        if(Op == 6'b100011)// lw
            MemRead <= 1;
        else
            MemRead <= 0;

        // MemWrite
        if(Op == 6'b101011) // sw
            MemWrite <= 1;
        else
            MemWrite <= 0;

        // MemToReg
        if(Op == 6'b000000)
            MemToReg <= 0; // R-i
        else if(Op == 6'b100011)
            MemToReg <= 1; // lw
        else
            MemToReg <= 0;

        // ALUOp
        // Inplemented in Top Level

        // Branch: beq or jal or jr
        if(Op == 6'b000100 || Op == 6'b000011 || (Op == 6'b000000 && Func == 6'b001000))
            Branch <= 1;
        else
            Branch <= 0;

    end

endmodule

// module ALUController (
//     input [5:0] Op,
//     input [5:0] Func,
//     input clock,
//     output reg [5:0] ALUOp
//     );

//     always @(posedge clock)
//     begin
//         if(Op == 6'b000000)
//         begin
//             ALUOp <= Func;
//         end
//         else if(Op == 6'b100011 || Op == 6'b101011) // lw or sw
//             ALUOp <= 6'b100001; // A+B
//         else if(Op == 6'b001101) // ori
//             ALUOp <= 6'b100101; // A|B
//         else if(Op == 6'b000100) // beq
//             ALUOp <= 6'b100011; // A-B
//         else if(Op == 6'b001111) // lui
//             ALUOp <= 6'b100101; // 0|B
//         else
//             ALUOp <= 6'b100001;
//     end

// endmodule