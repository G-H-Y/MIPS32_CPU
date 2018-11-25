`timescale 1ns / 1ps

`include "Core.vh"
module SynCP0(
	input clk, rst_n, en,
	input [2:0] irq_type,
	input [1:0] op_cp0,
	input w_en_ie, w_en_epc,
	input [31:0] ie_w_data, epc_w_data,
	output reg [2:0] ir,
	output reg [31:0] epc,
	output reg [31:0] ie,
	output int,
	output reg [1:0] int_num
	);
	
	reg [2:0] irs;
	reg [2:0] ret_clr, mask, irq_set;
	wire [2:0] deal_int = ir & mask;
	integer i;

	assign int = (|deal_int) & (ie[0]); //interrupt implict instruction period

	always @(negedge clk, negedge rst_n) begin
		if (!rst_n) begin
			ir <= 3'b0;
			ie <= 32'b1;
			irs <= 3'b0;
			epc <= 32'b0;
		end
		else if (en) begin
			if(w_en_ie)
				ie <= ie_w_data;
			if(w_en_epc)
				epc <= epc_w_data;
			case(op_cp0)
				`CP0_OP_IRQ: begin
					ir <= ir | irq_type;
					irs <= irs | irq_set;
				end
				`CP0_OP_RET: begin
					ir <= ir & ret_clr;
					irs <= irs & ret_clr;
				end
				default:
					ir <= ir | irq_type;
			endcase
		end
	end

	always @(*) begin
		int_num = 0;
		irq_set = 0;
		ret_clr = 3'b111;
		mask = 3'b111;
		for(i=0; i<3; i=i+1)
			if(irs[i]) begin
				ret_clr = ~(3'b1 << i);	
				mask = ~(((3'b1 << i)-1)|(3'b1 << i));		
			end
		for(i=0; i<3; i=i+1)
			if (deal_int[i]) begin
				int_num = i;
				irq_set = 3'b1 << i;
			end
	end
endmodule