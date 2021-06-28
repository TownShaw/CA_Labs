`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: WBSegReg
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Write Back Segment Register
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //WBSegReg是Write Back段寄存器，
    //类似于IDSegReg.V中对Bram的调用和拓展，它同时包含了一个同步读写的Bram
    //（此处你可以调用我们提供的InstructionRam，它将会自动综合为block memory，你也可以替代性的调用xilinx的bram ip核）。
    //同步读memory 相当于 异步读memory 的输出外接D触发器，需要时钟上升沿才能读取数据。
    //此时如果再通过段寄存器缓存，那么需要两个时钟上升沿才能将数据传递到Ex段
    //因此在段寄存器模块中调用该同步memory，直接将输出传递到WB段组合逻辑
    //调用mem模块后输出为RD_raw，通过assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );
    //从而实现RD段寄存器stall和clear功能
//实验要求  
    //你需要补全WBSegReg模块，需补全的片段截取如下
    //DataRam DataRamInst (
    //    .clk    (???),                      //请完善代码
    //    .wea    (???),                      //请完善代码
    //    .addra  (???),                      //请完善代码
    //    .dina   (???),                      //请完善代码
    //    .douta  ( RD_raw         ),
    //    .web    ( WE2            ),
    //    .addrb  ( A2[31:2]       ),
    //    .dinb   ( WD2            ),
    //    .doutb  ( RD2            )
    //);   
//注意事项
    //输入到DataRam的addra是字地址，一个字32bit
    //请配合DataExt模块实现非字对齐字节load
    //请通过补全代码实现非字对齐store


module WBSegReg(
    input wire clk,
    input wire rst,
    input wire en,
    input wire clear,
    //Data Memory Access
    input wire [31:0] A,
    input wire [31:0] WD,
    input wire [3:0] WE,
    output wire [31:0] RD,
    output reg [1:0] LoadedBytesSelect,
    //Data Memory Debug
    input wire [31:0] A2,
    input wire [31:0] WD2,
    input wire [3:0] WE2,
    output wire [31:0] RD2,
    //input control signals
    input wire [31:0] ResultM,
    output reg [31:0] ResultW, 
    input wire [4:0] RdM,
    output reg [4:0] RdW,
    //output constrol signals
    input wire [2:0] RegWriteM,
    output reg [2:0] RegWriteW,
    input wire MemToRegM,
    output reg MemToRegW,
    input wire [31:0] CSRM,
    output reg [31:0] CSRW,
    input wire CSRWriteM,
    output reg CSRWriteW,
    input wire CSRReadM,
    output reg CSRReadW,
    input wire [11:0] Rd_CSRM,
    output reg [11:0] Rd_CSRW,
    output wire DCacheMiss,
    input wire MemReadM,
    input wire [31:0] InstrM,
    output reg [31:0] InstrW
    );
    reg [31:0] mem_count = 0;
    reg [31:0] miss_count = 0;
    reg [31:0] hit_count = 0;
    reg miss_delay = 0;
    wire WE_en;
    assign WE_en = |WE;
    //
    initial begin
        LoadedBytesSelect = 2'b00;
        RegWriteW         =  1'b0;
        MemToRegW         =  1'b0;
        ResultW           =     0;
        RdW               =  5'b0;
        CSRW              = 32'd0;
        CSRWriteW         =  1'b0;
        CSRReadW          =  1'b0;
        Rd_CSRW           = 11'd0;
        InstrW            = 32'd0;
        mem_count         = 32'd0;
        miss_count        = 32'd0;
        hit_count         = 32'd0;
        miss_delay        =  1'b0;
    end
    //
    always@(posedge clk)
        if(en) begin
            LoadedBytesSelect <= clear ? 2'b00 : A[1:0];
            RegWriteW         <= clear ?  1'b0 : RegWriteM;
            MemToRegW         <= clear ?  1'b0 : MemToRegM;
            ResultW           <= clear ?     0 : ResultM;
            RdW               <= clear ?  5'b0 : RdM;
            CSRW              <= clear ? 32'd0 : CSRM;
            CSRWriteW         <= clear ?  1'b0 : CSRWriteM;
            CSRReadW          <= clear ?  1'b0 : CSRReadM;
            Rd_CSRW           <= clear ? 12'd0 : Rd_CSRM;
            InstrW            <= clear ? 32'd0 : InstrM;
            if (MemReadM == 1'bx || WE_en == 1'bx)
            begin
                mem_count <= mem_count;
                miss_count <= miss_count;
                hit_count <= hit_count;
            end
            else
            begin
                mem_count         <= (MemReadM == 1'b1 || WE_en == 1'b1) ? mem_count + 1 : mem_count;
                miss_count        <= ((MemReadM == 1'b1 || WE_en == 1'b1) && miss_delay == 1'b1) ? miss_count + 1 : miss_count;
                hit_count         <= ((MemReadM == 1'b1 || WE_en == 1'b1) && miss_delay == 1'b0) ? hit_count + 1 : hit_count;
            end
        end

    wire [31:0] RD_raw;
    reg [3:0] WE_NEW;
    reg [31:0] WD_NEW;
    always @(*)
    begin
        case(A[1:0])
            2'b00:
            begin
                WE_NEW <= WE;
                WD_NEW <= WD;
            end
            2'b01:
            begin
                WE_NEW <= WE << 1;
                WD_NEW <= WD << 8;
            end
            2'b10:
            begin
                WE_NEW <= WE << 2;
                WD_NEW <= WD << 16;
            end
            2'b11:
            begin
                WE_NEW <= WE << 3;
                WD_NEW <= WD << 24;
            end
            default:
            begin
                WE_NEW <= WE;
                WD_NEW <= WD;
            end
        endcase
    end
    /*
    DataRam DataRamInst (
        .clk    ( clk            ),                      //请完善代码
        .wea    ( WE_NEW         ),                      //请完善代码
        .addra  ( A[31:2]        ),                      //请完善代码
        .dina   ( WD_NEW         ),                      //请完善代码
        .douta  ( RD_raw         ),
        .web    ( WE2            ),
        .addrb  ( A2[31:2]       ),
        .dinb   ( WD2            ),
        .doutb  ( RD2            )
    );
    */
    my_cache_LRU #(
        .LINE_ADDR_LEN  ( 2             ),
        .SET_ADDR_LEN   ( 3             ),
        .TAG_ADDR_LEN   ( 5             ),
        .WAY_CNT        ( 4             )
    ) DCacheInst
    (
        .clk(clk),
        .rst(rst),
        .miss(DCacheMiss),
        .addr(A),
        .rd_req(MemReadM),
        .rd_data(RD_raw),
        .wr_req(|WE),
        .wr_data(WD)
    );
    // Add clear and stall support
    // if chip not enabled, output output last read result
    // else if chip clear, output 0
    // else output values from bram
    // 以下部分无需修改
    reg stall_ff= 1'b0;
    reg clear_ff= 1'b0;
    reg [31:0] RD_old=32'b0;
    always @ (posedge clk)
    begin
        stall_ff<=~en;
        clear_ff<=clear;
        RD_old<=RD;
        miss_delay <= DCacheMiss;
    end
    assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );

endmodule