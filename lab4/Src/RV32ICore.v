`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: RV32Core
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Top level of our CPU Core
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //RV32I 指令集CPU的顶层模块
//实验要求
    //无需修改
`include "Parameters.v"   
module RV32ICore(
    input wire CPU_CLK,
    input wire CPU_RST,
    input wire [31:0] CPU_Debug_DataRAM_A2,
    input wire [31:0] CPU_Debug_DataRAM_WD2,
    input wire [3:0] CPU_Debug_DataRAM_WE2,
    output wire [31:0] CPU_Debug_DataRAM_RD2,
    input wire [31:0] CPU_Debug_InstRAM_A2,
    input wire [31:0] CPU_Debug_InstRAM_WD2,
    input wire [ 3:0] CPU_Debug_InstRAM_WE2,
    output wire [31:0] CPU_Debug_InstRAM_RD2
    );
	//wire values definitions
    wire StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW;
    wire [31:0] PC_In;
    wire [31:0] PCF;
    wire [31:0] Instr, PCD;
    wire JalD, JalrD, LoadNpcD, MemToRegD, AluSrc1D;
    wire [2:0] RegWriteD;
    wire [3:0] MemWriteD;
    wire [1:0] RegReadD;
    wire [2:0] BranchTypeD;
    wire [4:0] AluContrlD;
    wire [1:0] AluSrc2D;
    wire [2:0] RegWriteW;
    wire [4:0] RdW;
    wire [31:0] RegWriteData;
    wire [31:0] DM_RD_Ext;
    wire [2:0] ImmType;
    wire [31:0] ImmD;
    wire [31:0] JalNPC;
    wire [31:0] BrNPC; 
    wire [31:0] ImmE;
    wire [6:0] OpCodeD, Funct7D;
    wire [2:0] Funct3D;
    wire [4:0] Rs1D, Rs2D, RdD;
    wire [4:0] Rs1E, Rs2E, RdE;
    wire [31:0] RegOut1D;
    wire [31:0] RegOut1E;
    wire [31:0] RegOut2D;
    wire [31:0] RegOut2E;
    wire JalrE;
    wire [2:0] RegWriteE;
    wire MemToRegE;
    wire [3:0] MemWriteE;
    wire LoadNpcE;
    wire [1:0] RegReadE;
    wire [2:0] BranchTypeE;
    wire [3:0] AluContrlE;
    wire AluSrc1E;
    wire [1:0] AluSrc2E;
    wire [31:0] Operand1;
    wire [31:0] Operand2;
    wire BranchE;
    wire [31:0] AluOutE;
    wire [31:0] AluOutM; 
    wire [31:0] ForwardData1;
    wire [31:0] ForwardData2;
    wire [31:0] PCE;
    wire [31:0] StoreDataM; 
    wire [4:0] RdM;
    wire [31:0] PCM;
    wire [2:0] RegWriteM;
    wire MemToRegM;
    wire [3:0] MemWriteM;
    wire LoadNpcM;
    wire [31:0] DM_RD;
    wire [31:0] ResultM;
    wire [31:0] ResultW;
    wire MemToRegW;
    wire [1:0] Forward1E;
    wire [1:0] Forward2E;
    wire [1:0] ForwardCSRE;
    wire [1:0] LoadedBytesSelect;
    wire [11:0] Rs_CSRD, Rs_CSRE, Rd_CSRD, Rd_CSRE, Rd_CSRM, Rd_CSRW;
    wire CSRRead, csrrwD, csrrwE;
    wire CSRWriteD, CSRWriteE, CSRWriteM, CSRWriteW;
    wire CSRReadD, CSRReadE, CSRReadM, CSRReadW;
    wire [31:0] CSRD, CSRE, CSRM, CSRW, ForwardCSRData, RegWriteData_plus_CSR;
    wire [31:0] CSRM_or_DataM, CSRW_or_DataW;
    wire MemReadD, MemReadE, MemReadM;
    wire ICacheMiss, DCacheMiss;
    wire [31:0] InstrE, InstrM, InstrW;
    wire BTB_HitF, BTB_HitD, BTB_HitE, BHT_HitF, BHT_HitD, BHT_HitE, BrInstE;
    wire [31:0] NPC, PredictPC;
    //wire values assignments
    assign {Funct7D, Rs2D, Rs1D, Funct3D, RdD, OpCodeD} = Instr;
    assign Rs_CSRD = Instr[31:20];
    assign Rd_CSRD = Instr[31:20];
    assign JalNPC=ImmD+PCD;
    assign CSRM_or_DataM = CSRWriteM ? CSRM : AluOutM;
    assign CSRW_or_DataW = CSRWriteW ? CSRW : RegWriteData;
    assign ForwardData1 = Forward1E[1]?(CSRM_or_DataM):( Forward1E[0]?CSRW_or_DataW:RegOut1E );
//    assign ForwardData1 = Forward1E[1]?((RdM == 5'd0) ? 32'd0 : AluOutM):( Forward1E[0]?((RdW == 5'd0) ? 32'd0 : RegWriteData):RegOut1E );
    assign Operand1 = (RegReadE[1] == 1'b0 && CSRReadE == 1'b1) ? Rs1E : (AluSrc1E ? PCE : ForwardData1);
    assign ForwardData2 = Forward2E[1]?(CSRM_or_DataM):( Forward2E[0]?CSRW_or_DataW:RegOut2E );
    assign Operand2 = ForwardCSRE[1] ? AluOutM : ( ForwardCSRE[0] ? ResultW : (CSRReadE ? CSRE : (AluSrc2E[1] ? (ImmE) : ( AluSrc2E[0] ? Rs2E : ForwardData2 ))));
    assign ResultM = LoadNpcM ? (PCM+4) : AluOutM;
    assign RegWriteData = (~MemToRegW ? ResultW : DM_RD_Ext);     //MemToReg = 0 <--> ResultW, MemToReg = 1 <--> DM_RD_Ext
    assign RegWriteData_plus_CSR = CSRWriteW ? CSRW : RegWriteData;
    assign ForwardCSRData = ForwardCSRE[1] ? AluOutM : (ForwardCSRE[0] ? ResultW : CSRE);
    assign BrInstE = (BranchTypeE != `NOBRANCH);

reg [31:0] Predict_Success = 0;
reg [31:0] Predict = 0;
always @(posedge CPU_CLK or negedge CPU_RST) begin
    if (CPU_RST) begin
        Predict <= 0;
        Predict_Success <= 0;
    end
    if (BrInstE)
    begin
        Predict <= Predict + 1;
        if (~((BHT_HitE & BTB_HitE) ^ BranchE)) begin
            Predict_Success <= Predict_Success + 1;
        end
    end
end
    //Module connections
    // ---------------------------------------------
    // PC-IF
    // ---------------------------------------------
    NPC_Generator NPC_Generator1(
        .PCF(PCF),
        .PCE(PCE),
        .JalrTarget(AluOutE), 
        .BranchTarget(BrNPC),
        .JalTarget(JalNPC),
        .BranchE(BranchE),
        .JalD(JalD),
        .JalrE(JalrE),
        .PC_In(PC_In),
        .BTB_HitF(BTB_HitF),
        .BTB_HitE(BTB_HitE),
        .BHT_HitF(BHT_HitF),
        .BHT_HitE(BHT_HitE),
        .PredictPC(PredictPC),
        .BrInstE(BrInstE)
    );

    BTB_BHT BTB1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .BranchE(BranchE),
        .BTB_HitF(BTB_HitF),
        .BTB_HitE(BTB_HitE),
        .BrInstE(BrInstE),
        .PCF(PCF),
        .PCE(PCE),
        .BrNPC(BrNPC),
        .PredictPC(PredictPC),
        .BHT_HitF(BHT_HitF),
        .BHT_HitE(BHT_HitE)
    );
/*
    BTB_BHT BTB_BHT1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .BranchE(BranchE),
        .BTB_HitF(BTB_HitF),
        .BTB_HitE(BTB_HitE),
        .BrInstE(BrInstE),
        .PCF(PCF),
        .PCE(PCE),
        .BrNPC(BrNPC),
        .PredictPC(PredictPC),
        .BHT_HitF(BHT_HitF),
        .BHT_HitE(BHT_HitE)
    );
*/
    IFSegReg IFSegReg1(
        .clk(CPU_CLK),
        .en(~StallF),
        .clear(FlushF), 
        .PC_In(PC_In),
        .PCF(PCF)
    );

    // ---------------------------------------------
    // ID stage
    // ---------------------------------------------

    IDSegReg IDSegReg1(
        .clk(CPU_CLK),
        .clear(FlushD),
        .en(~StallD),
        .A(PCF),
        .RD(Instr),
        .A2(CPU_Debug_InstRAM_A2),
        .WD2(CPU_Debug_InstRAM_WD2),
        .WE2(CPU_Debug_InstRAM_WE2),
        .RD2(CPU_Debug_InstRAM_RD2),
        .PCF(PCF),
        .PCD(PCD),
        .BTB_HitF(BTB_HitF),
        .BTB_HitD(BTB_HitD),
        .BHT_HitF(BHT_HitF),
        .BHT_HitD(BHT_HitD)
    );

    ControlUnit ControlUnit1(
        .Op(OpCodeD),
        .Fn3(Funct3D),
        .Fn7(Funct7D),
        .JalD(JalD),
        .JalrD(JalrD),
        .RegWriteD(RegWriteD),
        .MemToRegD(MemToRegD),
        .MemWriteD(MemWriteD),
        .LoadNpcD(LoadNpcD),
        .RegReadD(RegReadD),
        .BranchTypeD(BranchTypeD),
        .AluContrlD(AluContrlD),
        .AluSrc1D(AluSrc1D),
        .AluSrc2D(AluSrc2D),
        .ImmType(ImmType),
        .CSRWriteD(CSRWriteD),
        .CSRReadD(CSRReadD),
        .csrrwD(csrrwD),
        .MemReadD(MemReadD)
    );

    ImmOperandUnit ImmOperandUnit1(
        .In(Instr[31:7]),
        .Type(ImmType),
        .Out(ImmD)
    );

    RegisterFile RegisterFile1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .WE3(|RegWriteW),
        .A1(Rs1D),
        .A2(Rs2D),
        .A3(RdW),
        .WD3(RegWriteData_plus_CSR),
        .RD1(RegOut1D),
        .RD2(RegOut2D),
        .CSR_WE(CSRWriteW),
        .WD_CSR(ResultW),
        .RD_CSR(CSRD),
        .A_CSR_1(Rs_CSRD),
        .A_CSR_2(Rd_CSRW)
    );

    // ---------------------------------------------
    // EX stage
    // ---------------------------------------------
    EXSegReg EXSegReg1(
        .clk(CPU_CLK),
        .en(~StallE),
        .clear(FlushE),
        .PCD(PCD),
        .PCE(PCE), 
        .JalNPC(JalNPC),
        .BrNPC(BrNPC), 
        .ImmD(ImmD),
        .ImmE(ImmE),
        .RdD(RdD),
        .RdE(RdE),
        .Rs1D(Rs1D),
        .Rs1E(Rs1E),
        .Rs2D(Rs2D),
        .Rs2E(Rs2E),
        .RegOut1D(RegOut1D),
        .RegOut1E(RegOut1E),
        .RegOut2D(RegOut2D),
        .RegOut2E(RegOut2E),
        .JalrD(JalrD),
        .JalrE(JalrE),
        .RegWriteD(RegWriteD),
        .RegWriteE(RegWriteE),
        .MemToRegD(MemToRegD),
        .MemToRegE(MemToRegE),
        .MemWriteD(MemWriteD),
        .MemWriteE(MemWriteE),
        .LoadNpcD(LoadNpcD),
        .LoadNpcE(LoadNpcE),
        .RegReadD(RegReadD),
        .RegReadE(RegReadE),
        .BranchTypeD(BranchTypeD),
        .BranchTypeE(BranchTypeE),
        .AluContrlD(AluContrlD),
        .AluContrlE(AluContrlE),
        .AluSrc1D(AluSrc1D),
        .AluSrc1E(AluSrc1E),
        .AluSrc2D(AluSrc2D),
        .AluSrc2E(AluSrc2E),
        .CSRD(CSRD),
        .CSRE(CSRE),
        .CSRWriteD(CSRWriteD),
        .CSRWriteE(CSRWriteE),
        .CSRReadD(CSRReadD),
        .CSRReadE(CSRReadE),
        .csrrwD(csrrwD),
        .csrrwE(csrrwE),
        .Rd_CSRD(Rd_CSRD),
        .Rd_CSRE(Rd_CSRE),
        .Rs_CSRD(Rs_CSRD),
        .Rs_CSRE(Rs_CSRE),
        .MemReadD(MemReadD),
        .MemReadE(MemReadE),
        .InstrD(Instr),
        .InstrE(InstrE),
        .BTB_HitD(BTB_HitD),
        .BTB_HitE(BTB_HitE),
        .BHT_HitD(BHT_HitD),
        .BHT_HitE(BHT_HitE)
    	); 

    ALU ALU1(
        .Operand1(Operand1),
        .Operand2(Operand2),
        .AluContrl(AluContrlE),
        .AluOut(AluOutE)
    	);

    BranchDecisionMaking BranchDecisionMaking1(
        .BranchTypeE(BranchTypeE),
        .Operand1(Operand1),
        .Operand2(Operand2),
        .BranchE(BranchE)
        );

    // ---------------------------------------------
    // MEM stage
    // ---------------------------------------------
    MEMSegReg MEMSegReg1(
        .clk(CPU_CLK),
        .en(~StallM),
        .clear(FlushM),
        .AluOutE(AluOutE),
        .AluOutM(AluOutM), 
        .ForwardData2(ForwardData2),
        .StoreDataM(StoreDataM), 
        .RdE(RdE),
        .RdM(RdM),
        .PCE(PCE),
        .PCM(PCM),
        .RegWriteE(RegWriteE),
        .RegWriteM(RegWriteM),
        .MemToRegE(MemToRegE),
        .MemToRegM(MemToRegM),
        .MemWriteE(MemWriteE),
        .MemWriteM(MemWriteM),
        .LoadNpcE(LoadNpcE),
        .LoadNpcM(LoadNpcM),
        .CSRE(ForwardCSRData),
        .CSRM(CSRM),
        .CSRWriteE(CSRWriteE),
        .CSRWriteM(CSRWriteM),
        .CSRReadE(CSRReadE),
        .CSRReadM(CSRReadM),
        .Rd_CSRE(Rd_CSRE),
        .Rd_CSRM(Rd_CSRM),
        .MemReadE(MemReadE),
        .MemReadM(MemReadM),
        .InstrE(InstrE),
        .InstrM(InstrM)
    );

    // ---------------------------------------------
    // WB stage
    // ---------------------------------------------
    WBSegReg WBSegReg1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .en(~StallW),
        .clear(FlushW),
        .A(AluOutM),
        .WD(StoreDataM),
        .WE(MemWriteM),
        .RD(DM_RD),
        .LoadedBytesSelect(LoadedBytesSelect),
        .A2(CPU_Debug_DataRAM_A2),
        .WD2(CPU_Debug_DataRAM_WD2),
        .WE2(CPU_Debug_DataRAM_WE2),
        .RD2(CPU_Debug_DataRAM_RD2),
        .ResultM(ResultM),
        .ResultW(ResultW), 
        .RdM(RdM),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .MemToRegM(MemToRegM),
        .MemToRegW(MemToRegW),
        .CSRM(CSRM),
        .CSRW(CSRW),
        .CSRWriteM(CSRWriteM),
        .CSRWriteW(CSRWriteW),
        .CSRReadM(CSRReadM),
        .CSRReadW(CSRReadW),
        .Rd_CSRM(Rd_CSRM),
        .Rd_CSRW(Rd_CSRW),
        .DCacheMiss(DCacheMiss),
        .MemReadM(MemReadM),
        .InstrM(InstrM),
        .InstrW(InstrW)
    );
    
    DataExt DataExt1(
        .IN(DM_RD),
        .LoadedBytesSelect(LoadedBytesSelect),
        .RegWriteW(RegWriteW),
        .OUT(DM_RD_Ext)
    );
    // ---------------------------------------------
    // Harzard Unit
    // ---------------------------------------------
    HarzardUnit HarzardUnit1(
        .CpuRst(CPU_RST),
        .BranchE(BranchE),
        .BrInstE(BrInstE),
        .BTB_HitE(BTB_HitE),
        .BHT_HitE(BHT_HitE),
        .JalrE(JalrE),
        .JalD(JalD),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RegReadE(RegReadE),
        .MemToRegE(MemToRegE),
        .RdE(RdE),
        .RdM(RdM),
        .RegWriteM(RegWriteM),
        .RdW(RdW),
        .RegWriteW(RegWriteW),
        .ICacheMiss(1'b0),
        .DCacheMiss(DCacheMiss),
        .StallF(StallF),
        .FlushF(FlushF),
        .StallD(StallD),
        .FlushD(FlushD),
        .StallE(StallE),
        .FlushE(FlushE),
        .StallM(StallM),
        .FlushM(FlushM),
        .StallW(StallW),
        .FlushW(FlushW),
        .Forward1E(Forward1E),
        .Forward2E(Forward2E),
        .CSRReadE(CSRReadE),
        .CSRWriteM(CSRWriteM),
        .CSRWriteW(CSRWriteW),
        .Rs_CSRE(Rs_CSRE),
        .Rd_CSRM(Rd_CSRM),
        .Rd_CSRW(Rd_CSRW),
        .ForwardCSRE(ForwardCSRE)
    	);    
    	         
endmodule

