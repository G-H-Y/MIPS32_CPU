module Pipline_IF_ID(
	input clk,
	input rst_n,
	input en,
	input predict_fail,
   input load_use,
	input [31:0] pc_4,
	input [31:0] inst,
   input [31:0] pc_predict,
   input [1:0] binary_predict,
	output reg [31:0] pc_4_if_id,
	output reg [31:0] inst_if_id,
   output reg [31:0] pc_predict_if_id,
   output reg [1:0] binary_predict_if_id
	);

   initial begin
   	pc_4_if_id <= 0;
   	inst_if_id <= 0;
      pc_predict_if_id <= 0;
      binary_predict_if_id <= 0;
   end

   always @(posedge clk or negedge rst_n) begin
   	if (!rst_n) begin
   		pc_4_if_id <= 0;
   	   inst_if_id <= 0;
         pc_predict_if_id <= 0;
         binary_predict_if_id <= 0;   		
   	end
      else if (predict_fail)begin
         pc_4_if_id <= 0;
         inst_if_id <= 0;
         pc_predict_if_id <= 0;
         binary_predict_if_id <= 0;     
      end
      else if(load_use) begin
         pc_4_if_id <= pc_4_if_id;
         inst_if_id <= inst_if_id;
         pc_predict_if_id <= pc_predict_if_id;
         binary_predict_if_id <= binary_predict_if_id;
      end
   	else if (en) begin
   		pc_4_if_id <= pc_4;
   		inst_if_id <= inst;
          pc_predict_if_id <= pc_predict;
         binary_predict_if_id <= binary_predict;
   	end
   	else begin
   		pc_4_if_id <= pc_4_if_id;
   	    inst_if_id <= inst_if_id;
           pc_predict_if_id <= pc_predict_if_id;
         binary_predict_if_id <= binary_predict_if_id;
   	end
   end
endmodule