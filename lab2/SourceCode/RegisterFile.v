`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: RegisterFile
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: 
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //上升沿写入，异步读的寄存器堆，0号寄存器值始终为32'b0
    //在接入RV32Core时，输入为~clk，因此本模块时钟输入和其他部件始终相反
    //等价于例化本模块时正常接入时钟clk，同时修改代码为always@(negedge clk or negedge rst)
//实验要求
    //无需修改

module RegisterFile(
    input wire clk,
    input wire rst,
    input wire WE3,
    input wire CSR_WE,
    input wire [4:0] A1,
    input wire [4:0] A2,
    input wire [4:0] A3,
    input wire [11:0] A_CSR_1,      // 读选择
    input wire [11:0] A_CSR_2,      // 写选择
    input wire [31:0] WD3,
    input wire [31:0] WD_CSR,
    output wire [31:0] RD1,
    output wire [31:0] RD2,
    output wire [31:0] RD_CSR
    );

    reg [31:0] RegFile[31:1];
    reg [31:0] CSR [0:4095];
    integer i;
    //
    always@(negedge clk or posedge rst) 
    begin 
        if(rst)
        begin
            for(i=1;i<32;i=i+1) RegFile[i][31:0]<=32'b0;
            for (i = 0; i < 4096; i = i + 1) CSR[i] <= 32'd0;
        end
        else if( (WE3==1'b1) && (A3!=5'b0) )    RegFile[A3]<=WD3;   
        if( CSR_WE == 1'b1 )
            CSR[A_CSR_2] <= WD_CSR;
    end
    //    
//    assign RD1= (A3 == A1 && WE3 == 1'b1) ? WD3 : ((A1==5'b0)?32'b0:RegFile[A1]);  //Forwarding
//    assign RD2= (A3 == A2 && WE3 == 1'b1) ? WD3 : ((A2==5'b0)?32'b0:RegFile[A2]);
    assign RD1= (A1==5'b0) ? 32'b0 : ((A3 == A1 && WE3 == 1'b1) ? WD3 : RegFile[A1]);  //Forwarding
    assign RD2= (A2==5'b0) ? 32'b0 : ((A3 == A2 && WE3 == 1'b1) ? WD3 : RegFile[A2]);
    assign RD_CSR = (A_CSR_1 == A_CSR_2 && CSR_WE == 1'b1) ? WD_CSR : CSR[A_CSR_1];
    
endmodule
