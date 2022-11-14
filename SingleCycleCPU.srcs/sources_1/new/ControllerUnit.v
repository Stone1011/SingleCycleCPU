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
    output reg [1:0] RegDst,      // 00 Rt & 01 Rd & 10 $ra 
    output reg RegWrite,    // no-write & write
    output reg [1:0] ALUSrc,      // 00 GR[rt] & 01 SignExt of imm & 10 imm << 16 & 11 0
    output reg [1:0] PCSrc,       // next PC value signal, def inline
    output reg PCJumpEnabled,
    output reg MemRead,     // no-read & read from DM
    output reg MemWrite,    // no-write & write into DM
    output reg [1:0] MemToReg,    // What into Reg?
    output reg [5:0] ALUOp // ALU controller signal  
    // output reg Branch,      // is branch
    // output reg [1:0] regWriteContent    // 00 memoryContent & 01 PC + 4 & 10 ALUResult
    );

    always @(*)
    begin
        // RegDst
        // 00 Rt & 01 Rd & 10 $ra 
        if(Op == 6'b000000 && Func != 6'b001100 && Func != 6'b001000) // not syscall or jr
            RegDst <= 2'b01; // R-i
        else if(Op == 6'b000000 && Func == 6'b001100)
        begin
            $finish; // syscall
        end
        else if(Op == 6'b100011 || Op == 6'b001101 || Op == 6'b001111)
            RegDst <= 2'b00; // lw or ori or lui
        else if(Op == 6'b000011) // jal
            RegDst <= 2'b10;
        else
            RegDst <= 2'b11;

        // RegWrite: lw or ori or jal or lui or R
        if(Op == 6'b000000 || Op == 6'b100011 || Op == 6'b001101 || Op == 6'b000011 || Op == 6'b001111)
            RegWrite <= 1;
        else
            RegWrite <= 0;
        
        // ALUSrc
        // 00 GR[rt] & 01 SignExt of imm & 10 imm << 16 & 11 0
        if(Op == 6'b000000 || Op == 6'b000100)
            ALUSrc <= 2'b00; // R-i or beq
        else if(Op == 6'b100011 || Op == 6'b101011 || Op == 6'b001101)
            ALUSrc <= 2'b01; // lw or sw or ori
        else if(Op == 6'b001111)
            ALUSrc <= 2'b10;
        else // if(Op == 6'b000011)
            ALUSrc <= 2'b11; // jal and others
        
        // PCSrc & PCJumpEnabled
        // 00 regReadA, 01 PC + (immExt << 2) + 4, 10 {PC[31:28],target[25:0],2'b00}
        if(Op == 6'b000000 && Func == 6'b001000) // jr
        begin
            PCJumpEnabled <= 1;
            PCSrc <= 2'b00;
        end
        else if(Op == 6'b000100) // beq
        begin
            PCJumpEnabled <= 1; // need to & ALUResult == zero
            PCSrc <= 2'b01;
        end
        else if(Op == 6'b000011) // jal
        begin
            PCSrc <= 2'b10;
            PCJumpEnabled <= 1;
        end
        else
        begin
            PCSrc <= 2'b11;
            PCJumpEnabled <= 0;
        end

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

        // MemToReg: What into Regs
        // 00 ALU, 01 Mem, 10 PC + 4, 11 other(ALU into Regs)
        if(Op == 6'b000000)
            MemToReg <= 2'b00; // R-i
        else if(Op == 6'b100011)
            MemToReg <= 2'b01; // lw
        else if(Op == 6'b000011) // jal
            MemToReg <= 2'b10;
        else
            MemToReg <= 2'b00;

        // ALUOp
        if(Op == 6'b000000)
            ALUOp <= Func;
        else if(Op == 6'b100011 || Op == 6'b101011) // lw or sw
            ALUOp <= 6'b100001; // A+B
        else if(Op == 6'b001101) // ori
            ALUOp <= 6'b100101; // A|B
        else if(Op == 6'b000100) // beq
            ALUOp <= 6'b100011; // A-B
        else if(Op == 6'b001111) // lui
            ALUOp <= 6'b100101; // 0|B
        else
            ALUOp <= 6'b100001;

        // // Branch: beq or jal or jr
        // if(Op == 6'b000100 || Op == 6'b000011 || (Op == 6'b000000 && Func == 6'b001000))
        //     Branch <= 1;
        // else
        //     Branch <= 0;

    end

endmodule
