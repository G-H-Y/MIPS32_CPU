module Pipline_IF_ID(
	input clk,
	input rst_n,
	input en,
	input jp_success,
   input load_use,
   input int_nop,
   input inting,
	input [31:0] pc_4,
	input [31:0] inst,
	output reg [31:0] pc_4_if_id,
	output reg [31:0] inst_if_id
	);

   initial begin
   	pc_4_if_id <= 0;
   	inst_if_id <= 0;
   end

   always @(posedge clk or negedge rst_n) begin
   	if (!rst_n) begin
   		pc_4_if_id <= 0;
   	    inst_if_id <= 0;   		
   	end
      else if (jp_success || inting)begin
         pc_4_if_id <= 0;
          inst_if_id <= 0;    
      end
      else if(load_use || int_nop) begin
         pc_4_if_id <= pc_4_if_id;
          inst_if_id <= inst_if_id;
      end
   	else if (en) begin
   		pc_4_if_id <= pc_4;
   		inst_if_id <= inst;
   	end
   	else begin
   		pc_4_if_id <= pc_4_if_id;
   	    inst_if_id <= inst_if_id;
   	end
   end
endmodule