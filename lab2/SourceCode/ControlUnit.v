`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////
//功能和接口说�?
    //ControlUnit       是本CPU的指令译码器，组合�?�辑电路
//输入
    // Op               是指令的操作码部�?
    // Fn3              是指令的func3部分
    // Fn7              是指令的func7部分
//输出
    // JalD==1          表示Jal指令到达ID译码阶段
    // JalrD==1         表示Jalr指令到达ID译码阶段
    // RegWriteD        表示ID阶段的指令对应的寄存器写入模�?
    // MemToRegD==1     表示ID阶段的指令需要将data memory读取的�?�写入寄存器,
    // MemWriteD        �?4bit，为1的部分表示有效，对于data memory�?32bit字按byte进行写入,MemWriteD=0001表示只写入最�?1个byte，和xilinx bram的接口类�?
    // LoadNpcD==1      表示将NextPC输出到ResultM
    // RegReadD         表示A1和A2对应的寄存器值是否被使用到了，用于forward的处�?
    // BranchTypeD      表示不同的分支类型，�?有类型定义在Parameters.v�?
    // AluContrlD       表示不同的ALU计算功能，所有类型定义在Parameters.v�?
    // AluSrc2D         表示Alu输入�?2的�?�择
    // AluSrc1D         表示Alu输入�?1的�?�择
    // ImmType          表示指令的立即数格式
//实验要求  
    //补全模块  

`include "Parameters.v"   
module ControlUnit(
    input wire [6:0] Op,
    input wire [2:0] Fn3,
    input wire [6:0] Fn7,
    output wire JalD,
    output wire JalrD,
    output reg [2:0] RegWriteD,
    output wire MemToRegD,
    output reg [3:0] MemWriteD,
    output wire LoadNpcD,
    output reg [1:0] RegReadD,      //used for hazard unit
    output reg [2:0] BranchTypeD,
    output reg [3:0] AluContrlD,
    output wire [1:0] AluSrc2D,
    output wire AluSrc1D,
    output reg [2:0] ImmType
    );

    assign JalD = (Op == 7'b1101111) ? 1'b1 : 1'b0;
    assign JalrD = (Op == 7'b1100111) ? 1'b1 : 1'b0;
    assign MemToRegD = (Op == 7'b0000011) ? 1'b1 : 1'b0;
    assign LoadNpcD = (Op == 7'b1100111 || Op == 7'b1101111) ? 1'b1 : 1'b0; // Jal || Jalr
    assign AluSrc1D = (Op == 7'b0010111) ? 1'b1 : 1'b0;  //AUIPC
    assign AluSrc2D[0] = (Op == 7'b0010011) ? 1'b1 : 1'b0;  //SLLI, SRLI, SRAI, *I
    assign AluSrc2D[1] = ((Op == 7'b0010011 && Fn3 != 3'b001 && Fn3 != 3'b101) || Op == 7'b1100111 || Op == 7'b0000011 || Op == 7'b0100011 || Op == 7'b0110111 || Op == 7'b0010111) ? 1'b1 : 1'b0;  //ADDI ... ANDI / Jalr / LW / SW / LUI, AUIPC
    
    always @(*)
    begin
        case (Op)
            7'b0010011: // SLLI/SRLI/SRAI
            begin
                RegWriteD <= `LW;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `ITYPE;
                MemWriteD <= 3'd0;
                case (Fn3)
                    3'b000: AluContrlD <= `ADD;     //ADDI
                    3'b001: AluContrlD <= `SLL;     //SLLI
                    3'b010: AluContrlD <= `SLT;     //SLTI
                    3'b011: AluContrlD <= `SLTU;    //SLTIU
                    3'b100: AluContrlD <= `XOR;     //XORI
                    3'b101:
                    begin
                        if (Fn7 == 7'd0)
                            AluContrlD <= `SRL;     //SRLI
                        else
                            AluContrlD <= `SRA;     //SRAI
                    end
                    3'b110: AluContrlD <= `OR;      //ORI
                    3'b111: AluContrlD <= `AND;     //ANDI
                    default: AluContrlD <= `ADD;    //Anything
                endcase
                /*
                if (Fn3 == 3'b001)
                    AluContrlD <= `SLL;
                else if (Fn3 == 3'b101 && Fn7 == 7'd0)
                    AluContrlD <= `SRL;
                else if (Fn3 == 3'b101 && Fn7 == 7'b0100000)
                    AluContrlD <= `SRA;
                else
                    AluContrlD <= `SLL;
                */
            end
            7'b0110011:
            begin
                RegWriteD <= `LW;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `RTYPE;
                MemWriteD <= 3'd0;
                case (Fn3)
                    3'b000:
                    begin
                        if (Fn7 == 7'd0)
                            AluContrlD <= `ADD;     //ADD
                        else
                            AluContrlD <= `SUB;     //SUB
                    end
                    3'b001: AluContrlD <= `SLL;     //SLL
                    3'b010: AluContrlD <= `SLT;     //SLT
                    3'b011: AluContrlD <= `SLTU;    //SLTU
                    3'b100: AluContrlD <= `XOR;     //XOR
                    3'b101:
                    begin
                        if (Fn7 == 7'd0)
                            AluContrlD <= `SRL;     //SRL
                        else
                            AluContrlD <= `SRA;     //SRA
                    end
                    3'b110: AluContrlD <= `OR;      //OR
                    3'b111: AluContrlD <= `AND;     //AND
                    default: AluContrlD <= `ADD;    //Anything
                endcase
                /*
                if (Fn3 == 3'b000)
                begin
                    if (Fn7 == 7'd0)
                        AluContrlD <= `ADD; //ADD
                    else
                        AluContrlD <= `SUB; //SUB
                end
                else if (Fn3 == 3'b001)
                    AluContrlD <= `SLL;     //SLL
                else if (Fn3 == 3'b010)
                    AluContrlD <= `SLT;     //SLT
                else if (Fn3 == 3'b011)
                    AluContrlD <= `SLTU;    //SLTU
                else if (Fn3 == 3'b100)
                    AluContrlD <= `XOR;     //XOR
                else if (Fn3 == )
                */
            end
            7'b0010011:
            begin
                RegWriteD <= `LW;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `ITYPE;
                MemWriteD <= 3'd0;
                case (Fn3)
                endcase
            end
            7'b0110111: //LUI
            begin
                RegWriteD <= `LW;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `UTYPE;
                MemWriteD <= 3'd0;
                AluContrlD <= `LUI;
            end
            7'b0010111: //AUIPC
            begin
                RegWriteD <= `LW;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `UTYPE;
                MemWriteD <= 3'd0;
                AluContrlD <= `ADD;
            end
            7'b1100111: //JALR
            begin
                RegWriteD <= `NOREGWRITE;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `ITYPE;
                MemWriteD <= 3'd0;
                AluContrlD <= `ADD;
            end
            7'b1101111: //JAL
            begin
                RegWriteD <= `NOREGWRITE;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `JTYPE;
                MemWriteD <= 3'd0;
                AluContrlD <= `ADD;
            end
            7'b1100011: //Branch
            begin
                RegWriteD <= `NOREGWRITE;
                ImmType <= `ITYPE;
                MemWriteD <= 3'd0;
                AluContrlD <= `ADD;
                case (Fn3)
                    3'b000: BranchTypeD <= `BEQ;        //BEQ
                    3'b001: BranchTypeD <= `BNE;        //BNE
                    3'b100: BranchTypeD <= `BLT;        //BLT
                    3'b101: BranchTypeD <= `BGE;        //BGE
                    3'b110: BranchTypeD <= `BLTU;       //BLTU
                    3'b111: BranchTypeD <= `BGEU;       //BGEU
                    default: BranchTypeD <= `NOBRANCH;  //Anything
                endcase
            end
            7'b0000011: //Load
            begin
                BranchTypeD <= `NOBRANCH;
                ImmType <= `ITYPE;
                MemWriteD <= 3'd0;
                AluContrlD <= `ADD;
                case (Fn3)
                    3'b000: RegWriteD <= `LB;
                    3'b001: RegWriteD <= `LH;
                    3'b010: RegWriteD <= `LW;
                    3'b100: RegWriteD <= `LBU;
                    3'b101: RegWriteD <= `LHU;
                    default: RegWriteD <= `NOREGWRITE;
                endcase
            end
            7'b0100011: //Store
            begin
                RegWriteD <= `NOREGWRITE;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `STYPE;
                AluContrlD <= `ADD;
                case (Fn3)
                    3'b000: MemWriteD <= 4'b0001;   //SB
                    3'b001: MemWriteD <= 4'b0011;   //SH
                    3'b010: MemWriteD <= 4'b1111;   //SW
                    default: MemWriteD <= 4'b0000;  //Anything
                endcase
            end
            default:
            begin
                RegWriteD <= `NOREGWRITE;
                MemWriteD <= 3'd0;
                BranchTypeD <= `NOBRANCH;
                ImmType <= `RTYPE;
                AluContrlD <= `ADD;
            end
        endcase
    end
    // 请补全此处代�?

endmodule

