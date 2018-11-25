`timescale 1ns / 1ps

// Brief: Program Counter, sychronized
// Description: Update program counter
// Author: G-H-Y
module SynPC(
    input clk,
    input rst_n,
    input en,
    input load_use,
    input int_nop,
    input jp_success,
    input irq_ret,
    input [31:0] pc_new,
    output [31:0] pc, pc_4
    );

    reg [9:0] pc_simp;
    wire [9:0] pc_4_simp = pc_simp + 1;

    assign pc = {{20{1'b0}}, pc_simp, {2{1'b0}}};
    assign pc_4 = {{20{1'b0}}, pc_4_simp, {2{1'b0}}};

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
   		    pc_simp = 0;
          else if (jp_success || irq_ret)
            pc_simp = pc_new[11:2];   
        else if(load_use || int_nop)
            pc_simp = pc_simp;   	   
        else if(en)
            pc_simp = pc_4_simp;
    end
endmodule
