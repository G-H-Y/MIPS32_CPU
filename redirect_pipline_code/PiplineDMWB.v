module Pipline_DM_WB(
	input clk,rst_n,en,
	input halt_ex_dm,
	input regfile_w_en_ex_dm,
	input [4:0]regfile_req_w_ex_dm,
	input [31:0]regfile_data_w,

	output reg halt_dm_wb,
	output reg regfile_w_en_dm_wb,
	output reg [4:0] regfile_req_w_dm_wb,
	output reg [31:0] regfile_data_w_dm_wb
	);

	initial begin
		halt_dm_wb <= 0;
	 	regfile_w_en_dm_wb <= 0;
	 	regfile_req_w_dm_wb <= 0;
	 	regfile_data_w_dm_wb <= 0;
	end

	always @(posedge clk or posedge rst_n) begin
		if (!rst_n) begin
			halt_dm_wb <= 0;
	 		regfile_w_en_dm_wb <= 0;
	 		regfile_req_w_dm_wb <= 0;
	 		regfile_data_w_dm_wb <= 0;
		end
		else if (en) begin
			halt_dm_wb <= halt_ex_dm;
	 		regfile_w_en_dm_wb <= regfile_w_en_ex_dm;
	 		regfile_req_w_dm_wb <= regfile_req_w_ex_dm;
	 		regfile_data_w_dm_wb <= regfile_data_w;
		end
		else begin
			halt_dm_wb <= halt_dm_wb;
	 		regfile_w_en_dm_wb <= regfile_w_en_dm_wb;
	 		regfile_req_w_dm_wb <= regfile_req_w_dm_wb;
	 		regfile_data_w_dm_wb <= regfile_data_w_dm_wb;
		end
	end

endmodule