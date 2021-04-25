`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: DataExt 
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Data Extension module
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //DataExt是用来处理非字对齐load的情形，同时根据load的不同模式对Data Mem中load的数进行符号或�?�无符号拓展，组合�?�辑电路
//输入
    //IN                    是从Data Memory中load�?32bit�?
    //LoadedBytesSelect     等价于AluOutM[1:0]，是读Data Memory地址的低两位�?
                            //因为DataMemory是按字（32bit）进行访问的，所以需要把字节地址转化为字地址传给DataMem
                            //DataMem�?次返回一个字，低两位地址用来�?32bit字中挑�?�出我们�?要的字节
    //RegWriteW             表示不同�? 寄存器写入模�? ，所有模式定义在Parameters.v�?
//输出
    //OUT表示要写入寄存器的最终�??
//实验要求  
    //补全模块  

`include "Parameters.v"
module DataExt(
    input wire [31:0] IN,
    input wire [1:0] LoadedBytesSelect,
    input wire [2:0] RegWriteW,
    output reg [31:0] OUT
    );

    // 请补全此处代�?
    always @(*)
    begin
        case (LoadedBytesSelect)
            2'b00:
            begin
                case (RegWriteW)
                    `NOREGWRITE: OUT <= 32'hxxxxxxxx;
                    `LB: OUT <= { {24{IN[7]}}, IN[7:0] };
                    `LH: OUT <= { {16{IN[15]}}, IN[15:0] };
                    `LW: OUT <= IN;
                    `LBU: OUT <= { 24'd0, IN[7:0] };
                    `LHU: OUT <= { 16'd0, IN[15:0] };
                    default: OUT <= 32'hxxxxxxxx;
                endcase
            end
            2'b01:
            begin
                case (RegWriteW)
                    `NOREGWRITE: OUT <= 32'hxxxxxxxx;
                    `LB: OUT <= { {24{IN[15]}}, IN[15:8] };
                    `LH: OUT <= { {16{IN[23]}}, IN[23:8] };
                    `LW: OUT <= { {8{IN[31]}}, IN[31:8] };
                    `LBU: OUT <= { 24'd0, IN[15:8] };
                    `LHU: OUT <= { 16'd0, IN[23:8] };
                    default: OUT <= 32'hxxxxxxxx;
                endcase
            end
            2'b10:
            begin
                case (RegWriteW)
                    `NOREGWRITE: OUT <= 32'hxxxxxxxx;
                    `LB: OUT <= { {24{IN[23]}}, IN[23:16] };
                    `LH: OUT <= { {16{IN[31]}}, IN[31:16] };
                    `LW: OUT <= { {16{IN[31]}}, IN[31:16] };
                    `LBU: OUT <= { 24'd0, IN[23:16] };
                    `LHU: OUT <= { 16'd0, IN[31:16] };
                    default: OUT <= 32'hxxxxxxxx;
                endcase
            end
            2'b11:
            begin
                case (RegWriteW)
                    `NOREGWRITE: OUT <= 32'hxxxxxxxx;
                    `LB: OUT <= { {24{IN[31]}}, IN[31:24] };
                    `LH: OUT <= { {24{IN[31]}}, IN[31:24] };
                    `LW: OUT <= { {24{IN[31]}}, IN[31:24] };
                    `LBU: OUT <= { 24'd0, IN[31:24] };
                    `LHU: OUT <= { 24'd0, IN[31:24] };
                    default: OUT <= 32'hxxxxxxxx;
                endcase
            end
            default: OUT <= 32'hxxxxxxxx;
        endcase
    end

endmodule

