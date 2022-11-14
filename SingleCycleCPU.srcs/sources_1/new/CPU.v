`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/12 23:20:00
// Design Name: 
// Module Name: CPU
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

// A clock cycle for 10ns (100MHz)

module CPU(
    input reset,
    input clock
    );

    wire [31:0] instruction;

    // Decoding
    wire [5:0] Op, Func;
    wire [4:0] rs, rt, rd;
    wire [15:0] imm;
    wire [25:0] target;
    assign Op = instruction[31:26];
    assign Func = instruction[5:0];
    assign rs = instruction[25:21];
    assign rt = instruction[20:16];
    assign rd = instruction[15:11];
    assign imm = instruction[15:0];
    assign target = instruction[25:0];

    always @(posedge clock)
    begin
        $display("Now the instruction Op is: %b", Op);
    end

    // ALU module
    wire [31:0] dataA;
    reg [31:0] dataB; // ALU Operands
    reg [5:0] ALUOp; // ALU Operator Code
    wire [31:0] ALUResult; // ALU Calc Result
    ArithmeticLogicUnit ALU(.A(dataA), .B(dataB), .Op(ALUOp), .C(ALUResult), .Over());
    
    // PC module
    reg jumpEnabled;
    reg [31:0] jumpInput;
    wire [31:0] PC;
    ProgramCounter PCModule(.reset(reset), .clock(clock), .jumpEnabled(jumpEnabled), .jumpInput(jumpInput), .pcValue(PC));

    // IM module
    InstructionMemory IM(.address(PC), .readResult(instruction));

    // GR module
    reg [4:0] regWrite;
    wire regWriteEnabled;
    reg regWriteEnabledReg;
    reg [31:0] regWriteContent;
    wire [31:0] regReadA, regReadB;
    GeneralPurposeRegisters GR(.readNoA(rs), .readNoB(rt), .reset(reset), .writeNo(regWrite), .writeEnabled(regWriteEnabledReg), .writeContent(regWriteContent), .clock(clock), .readResultA(regReadA), .readResultB(regReadB));
    assign dataA = regReadA;

    always @(posedge clock)
    begin
        // Simulate: write regs next cycle
        // Update the signal after 1ns
        #1;
        regWriteEnabledReg <= regWriteEnabled;
    end

    // DM module
    wire readDM, writeDM; // signal whether should read & write
    wire [31:0] memoryContent; // read content from DM
    DataMemory DM(.reset(reset), .clock(clock), .address(ALUResult), .writeEnabled(writeDM), .readEnabled(readDM), .writeInput(regReadB), .readResult(memoryContent));

    // CU module
    wire RegDst, ALUSrc, MemToReg, Branch;
    ControllerUnit CU(.Op(Op), .Func(Func), .RegDst(RegDst), .RegWrite(regWriteEnabled), .ALUSrc(ALUSrc), .MemRead(readDM), .MemWrite(writeDM), .MemToReg(MemToReg), .Branch(Branch));

    // imm sign extend
    wire [31:0] immExt;
    SignExtendUnit SEU(.in(imm), .out(immExt));

    // target sign extend
    wire [31:0] targetExt;
    assign targetExt[27:2] = target;
    assign targetExt[31:28] = target[25] ? 4'b1111 : 4'b0000;
    assign targetExt[1:0] = 2'b00;

    // write back Reg's code
    always @(posedge clock)
    begin
        #1;
        if(RegDst == 0 && Op == 6'b000011) // jal
            regWrite <= 5'b11111; // $ra
        else if(RegDst == 0) // lw or ori or lui
            regWrite <= rt;
        else// if(RegDst == 1)
            regWrite <= rd;
    end

    // write back Reg's data
    always @(posedge clock)
    begin
        #2;
        if(MemToReg == 1 && Op != 6'b000011) // DM into GR
            regWriteContent <= memoryContent;
        else if(Op == 6'b000011 && MemToReg == 1)
            regWriteContent <= PC + 4; // jal
        else // ALU into GR
            regWriteContent <= ALUResult;
    end

    // ALU's second input
    always @(posedge clock)
    begin
        #1;
        if(ALUSrc == 0)
            dataB <= regReadB;
        // else if(Op == 6'b000011)
        //     dataB <= targetExt; // jal, actually not meaningful
        else if(Op == 6'b100011 || Op == 6'b101011 || Op == 6'b001101)// lw or sw or ori
            dataB <= immExt;
        else if(Op == 6'b001111) // lui
            dataB <= (imm << 16);
        else
            dataB <= 0;
    end

    // PC value
    always @(posedge clock)
    begin
        #4.8;
        if(Branch)
        begin
            if(Op == 6'b000000) // jr
            begin
                jumpEnabled <= 1;
                jumpInput <= regReadA; // PC := rs
            end
            if(Op == 6'b000100) // beq
            begin
                if(ALUResult == 0)
                begin
                    jumpEnabled <= 1;
                    jumpInput <= PC + (immExt << 2) + 4;
                end
                else
                    jumpEnabled <= 0;
            end
            else // jal
            begin
                jumpEnabled <= 1;
                jumpInput[31:28] <= PC[31:28];
                jumpInput[27:2] <= target[25:0];
                jumpInput[1:0] <= 2'b00;
            end
        end
        else
            jumpEnabled <= 0;
    end

    // ALU function code: ALUOp
    // ALUController ALUC(.Op(Op), .Func(Func), .clock(clock), .ALUOp(ALUOp));
    always @(posedge clock)
    begin
        if(Op == 6'b000000)
        begin
            ALUOp <= Func;
        end
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
    end

endmodule
