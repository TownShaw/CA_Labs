`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: HarzardUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Deal with harzards in pipline
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //HarzardUnit用来处理流水线冲突，通过插入气泡，forward以及冲刷流水段解决数据相关和控制相关，组合逻辑电路
    //可以最后实现。前期测试CPU正确性时，可以在每两条指令间插入四条空指令，然后直接把本模块输出定为，不forward，不stall，不flush 
//输入
    //CpuRst                                    外部信号，用来初始化CPU，当CpuRst==1时CPU全局复位清零（所有段寄存器flush），Cpu_Rst==0时cpu开始执行指令
    //ICacheMiss, DCacheMiss                    为后续实验预留信号，暂时可以无视，用来处理cache miss
    //BranchE, JalrE, JalD                      用来处理控制相关
    //Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW     用来处理数据相关，分别表示源寄存器1号码，源寄存器2号码，目标寄存器号码
    //RegReadE RegReadD[1]==1                   表示A1对应的寄存器值被使用到了，RegReadD[0]==1表示A2对应的寄存器值被使用到了，用于forward的处理
    //RegWriteM, RegWriteW                      用来处理数据相关，RegWrite!=3'b0说明对目标寄存器有写入操作
    //MemToRegE                                 表示Ex段当前指令 从Data Memory中加载数据到寄存器中
//输出
    //StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW    控制五个段寄存器进行stall（维持状态不变）和flush（清零）
    //Forward1E, Forward2E                                                              控制forward
//实验要求  
    //补全模块
    
    
module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss,
    input wire BranchE, JalrE, JalD,
    input wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    input wire [1:0] RegReadE,
    input wire MemToRegE,
    input wire [2:0] RegWriteM, RegWriteW,
    input wire CSRReadE, CSRWriteM, CSRWriteW,
    input wire [11:0] Rs_CSRE, Rd_CSRM, Rd_CSRW,
    output reg StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW,
    output reg [1:0] Forward1E, Forward2E,
    output reg [1:0] ForwardCSRE
    );
    always @(*)
    begin
        if (CpuRst)
        begin
            StallF = 1'b0;
            FlushF = 1'b1;
            StallD = 1'b0;
            FlushD = 1'b1;
            StallE = 1'b0;
            FlushE = 1'b1;
            StallM = 1'b0;
            FlushM = 1'b1;
            StallW = 1'b0;
            FlushW = 1'b1;
            Forward1E = 2'b00;
            Forward2E = 2'b00;
            ForwardCSRE = 2'b00;
        end
        else
        begin

            if (Rs1E == RdM && RegWriteM != 3'b000)                     //handle Rs1E
            begin
                if (RegReadE[1] == 1'b1 && RdM != 5'd0)
                    Forward1E = 2'b10;                                 //data comes from AluOutM
                else
                    Forward1E = 2'b00;
            end
            else if (Rs1E == RdW && RegWriteW != 3'b000)
            begin
                if (RegReadE[1] == 1'b1 && RdW != 5'd0)
                    Forward1E = 2'b01;                                 //data comes from RegWriteData
                else
                    Forward1E = 2'b00;
            end
            else
                Forward1E = 2'b00;
            
            if (Rs2E == RdM && RegWriteM != 3'b000)                     //handle Rs2E
            begin
                if (RegReadE[0] == 1'b1 && RdM != 5'd0)
                    Forward2E = 2'b10;                                 //data comes from AluOutM
                else
                    Forward2E = 2'b00;
            end
            else if (Rs2E == RdW && RegWriteW != 3'b000)
            begin
                if (RegReadE[0] == 1'b1 && RdW != 5'd0)
                    Forward2E = 2'b01;                                 //data comes from RegWriteData
                else
                    Forward2E = 2'b00;
            end
            else
                Forward2E = 2'b00;

            if ((Rs1D == RdE || Rs2D == RdE) && MemToRegE == 1'b1)   //Load Inst && Data Relevent
            begin
                StallF = 1'b1;
                StallD = 1'b1;
            end
            else
            begin
                StallF = 1'b0;
                StallD = 1'b0;
            end

            if (BranchE == 1'b1 || JalrE == 1'b1)                        //handle Jal && Jalr && Branch
            begin
                FlushD = 1'b1;
            end
            else if (JalD == 1'b1)
            begin
                FlushD = 1'b1;
            end
            else
            begin
                FlushD = 1'b0;
            end

            if (((Rs1D == RdE || Rs2D == RdE) && MemToRegE == 1'b1) || (BranchE == 1'b1 || JalrE == 1'b1))  //when load or branch, FlushE
                FlushE = 1'b1;
            else
                FlushE = 1'b0;
            
            if (CSRReadE == 1'b1 && CSRWriteM == 1'b1 && Rs_CSRE == Rd_CSRM)
                ForwardCSRE = 2'b10;
            else if (CSRReadE == 1'b1 && CSRWriteW == 1'b1 && Rs_CSRE == Rd_CSRW)
                ForwardCSRE = 2'b01;
            else
                ForwardCSRE = 2'b00;

            StallM = 1'b0;
            StallW = 1'b0;
            FlushF = 1'b0;
            FlushM = 1'b0;
            FlushW = 1'b0;
        end
    end
    // assign ForwardData1 = Forward1E[1] ? (AluOutM) : ( Forward1E[0] ? RegWriteData : RegOut1E );
    // assign Operand1 = AluSrc1E ? PCE : ForwardData1;
    // assign ForwardData2 = Forward2E[1] ? (AluOutM) : ( Forward2E[0] ? RegWriteData : RegOut2E );
    // assign Operand2 = AluSrc2E[1] ? (ImmE) : ( AluSrc2E[0] ? Rs2E : ForwardData2 );
    // assign RegWriteData = ~MemToRegW?ResultW:DM_RD_Ext;     MemToReg = 0 <--> ResultW, MemToReg = 1 <--> DM_RD_Ext
    // 请补全此处代码

endmodule

  