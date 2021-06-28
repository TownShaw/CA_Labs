`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: NPC_Generator
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Choose Next PC value
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //NPC_Generator是用来生成Next PC值的模块，根据不同的跳转信号选择不同的新PC值
//输入
    //PCF              旧的PC值
    //JalrTarget       jalr指令的对应的跳转目标
    //BranchTarget     branch指令的对应的跳转目标
    //JalTarget        jal指令的对应的跳转目标
    //BranchE==1       Ex阶段的Branch指令确定跳转
    //JalD==1          ID阶段的Jal指令确定跳转
    //JalrE==1         Ex阶段的Jalr指令确定跳转
//输出
    //PC_In            NPC的值
//实验要求
    //补全模块  

module NPC_Generator(
    input wire [31:0] PCF, PCE, JalrTarget, BranchTarget, JalTarget, PredictPC,
    input wire BranchE,JalD,JalrE,BTB_HitF,BTB_HitE,BHT_HitF,BHT_HitE,BrInstE,
    output reg [31:0] PC_In
    );

    always @(*)
    begin
        if (JalrE)
            PC_In = JalrTarget;
        else if (BranchE & ~(BHT_HitE & BTB_HitE))         //BTB 未命中 或 BHT 为 0, 表示在 IF 段未跳转, 因此在此时需要 Branch
            PC_In = BranchTarget;
        else if (~BranchE & (BTB_HitE & BHT_HitE) & BrInstE)
            PC_In = PCE + 4;
        else if (JalD)
            PC_In = JalTarget;
        else if (BTB_HitF & BHT_HitF)       //仅当 BTB 命中且 BHT 为 1 时才预测
            PC_In = PredictPC;
        else
            PC_In = PCF + 4;
    end
    // 请补全此处代码

endmodule
