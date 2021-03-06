`timescale 1ns / 1ps

`include "Auxiliary.vh"

// Brief: Top Module, I/O included
// Author: EAirPeter
module TopLajiIntelKnightsLanding(clk, rst_n, resume, swt, seg_n, an_n);
    parameter ProgPath = "E:/lab/test/benchmark_ccmb.hex";
    parameter CoreClk0Cnt = `CNT_HZ(2);
    parameter CoreClk1Cnt = `CNT_HZ(20);
    parameter CoreClk2Cnt = `CNT_HZ(200);
    parameter CoreClk3Cnt = `CNT_MHZ(50);
    parameter DispClkCnt = `CNT_KHZ(2);
    input clk;
    input rst_n;
    input resume;
    input [15:0] swt;
    output [7:0] seg_n;
    output [7:0] an_n;

    wire [1:0] mux_core_clk = swt[1:0];
    wire [3:0] mux_disp_data = swt[5:2];
    reg [31:0] disp_data;   // combinatorial
    wire clk_core_0, clk_core_1, clk_core_2, clk_core_3;
    reg core_clk;           // combinatorial
    wire core_en;
    wire [31:0] core_pc_dbg;
    wire [4:0] regfile_req_dbg = swt[15:11];
    wire [31:0] datamem_addr_dbg = {24'd0, swt[15:6], 2'd0};
    wire [31:0] regfile_data_dbg;
    wire [31:0] datamem_data_dbg;
    wire [31:0] core_display;
    wire core_halt, core_is_jump, core_is_branch, core_branched;
    wire core_nop, core_predict,core_predict_success;
    wire [31:0] cnt_cycle, cnt_jump, cnt_branch, cnt_branched, cnt_nop, cnt_predict, cnt_predict_success;

    always @(*) begin
        case (mux_core_clk)
            2'b00:  core_clk <= clk_core_0;
            2'b01:  core_clk <= clk_core_1;
            2'b10:  core_clk <= clk_core_2;
            2'b11:  core_clk <= clk_core_3;
        endcase
        case (mux_disp_data)
            `MUX_DISP_DATA_CORE:    disp_data <= core_display;
            `MUX_DISP_DATA_CNT_CYC: disp_data <= cnt_cycle;
            `MUX_DISP_DATA_CNT_JMP: disp_data <= cnt_jump;
            `MUX_DISP_DATA_CNT_BCH: disp_data <= cnt_branch;
            `MUX_DISP_DATA_CNT_BED: disp_data <= cnt_branched;
            `MUX_DISP_DATA_PC_DBG:  disp_data <= core_pc_dbg;
            `MUX_DISP_DATA_RF_DBG:  disp_data <= regfile_data_dbg;
            `MUX_DISP_DATA_DM_DBG:  disp_data <= datamem_data_dbg;
            `MUX_DISP_DATA_CNT_NOP: disp_data <= cnt_nop;
            default:                disp_data <= core_display;
        endcase
    end

    AuxDivider #(
        .CntMax(CoreClk0Cnt)
    ) vDivCoreClk0(
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(clk_core_0)
    );
    AuxDivider #(
        .CntMax(CoreClk1Cnt)
    ) vDivCoreClk1(
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(clk_core_1)
    );
    AuxDivider #(
        .CntMax(CoreClk2Cnt)
    ) vDivCoreClk2(
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(clk_core_2)
    );
    AuxDivider #(
        .CntMax(CoreClk3Cnt)
    ) vDivCoreClk3(
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(clk_core_3)
    );
    AuxDisplay #(
        .ScanCntMax(DispClkCnt)
    ) vDisp(
        .clk(clk),
        .data(disp_data),
        .seg_n(seg_n),
        .an_n(an_n)
    );
    AuxCounter #(
        .CntBit(32)
    ) vCtrCycle(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_cycle)
    );
    AuxCounter #(
        .CntBit(32)
    ) vCtrJump(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en && core_is_jump),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_jump)
    );
    AuxCounter #(
        .CntBit(32)
    ) vCtrBranch(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en && core_is_branch),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_branch)
    );
    AuxCounter #(
        .CntBit(32)
    ) vCtrBranched(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en && core_branched),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_branched)
    );
    AuxCounter #(
        .CntBit(32)
    ) vCtrNop(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en && core_nop),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_nop)
    );
     AuxCounter #(
        .CntBit(32)
    ) vCtrPredict(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en && core_predict),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_predict)
    );
     AuxCounter #(
        .CntBit(32)
    ) vCtrPredictSuccess(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en && core_predict_success),
        .ld(1'b0),
        .val(32'd0),
        .cnt(cnt_predict_success)
    );
    AuxWTCIE vWTCIE(
        .clk(core_clk),
        .rst_n(rst_n),
        .resume(resume),
        .halt(core_halt),
        .en(core_en)
    );
    SynLajiIntelKnightsLanding #(
        .ProgPath(ProgPath)
    ) vCore(
        .clk(core_clk),
        .rst_n(rst_n),
        .en(core_en),
        .regfile_req_dbg(regfile_req_dbg),
        .datamem_addr_dbg(datamem_addr_dbg[11:0]),
        .pc_dbg(core_pc_dbg),
        .regfile_data_dbg(regfile_data_dbg),
        .datamem_data_dbg(datamem_data_dbg),
        .display(core_display),
        .halted(core_halt),
        .jumped(core_is_jump),
        .is_branch(core_is_branch),
        .branched(core_branched),
        .load_use(core_nop),
        .predict(core_predict),
        .predict_success(core_predict_success)
    );
endmodule
