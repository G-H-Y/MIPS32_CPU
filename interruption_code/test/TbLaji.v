`timescale 1ns / 1ps

`include "Test.vh"

module TbLaji();
    reg clk = 1'b1;
    always #5 clk <= !clk;
    reg rst_n = 1'b0;
    reg resume = 1'b0;
    reg [15:0] swt = 16'h3;
    reg [2:0] irq_type = 3'b000;
    wire [7:0] seg_n;
    wire [7:0] an_n;
    initial begin
        `cp(1) rst_n = 1'b1;
        `cp(5) irq_type = 3'b001;
        `cp(5) irq_type = 3'b000;
        `cp(5) irq_type = 3'b010;
        `cp(5) irq_type = 3'b000;
        `cp(5) irq_type = 3'b100;
        `cp(5) irq_type = 3'b000;
    end
    TopLajiIntelKnightsLanding vDUT(
        .clk(clk),
        .rst_n(rst_n),
        .resume(resume),
        .swt(swt),
        .seg_n(seg_n),
        .an_n(an_n),
        .irq_type(irq_type)
    );
endmodule