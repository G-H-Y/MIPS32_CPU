`include "Core.vh"
module Pipline_EX_DM(
	input clk,rst_n,
	input en,
    input [31:0] alu_data_res,
    input [31:0] regfile_pre_data_w,
    input [31:0] regfile_data_b_id_ex,
    input halt,
    input [4:0]regfile_req_w_id_ex,
    input regfile_w_en_id_ex,
    input [`DM_OP_BIT - 1:0] datamem_op_id_ex,
    input datamem_w_en_id_ex,
    input memtoreg_id_ex,

    output reg [31:0] alu_data_res_ex_dm,
    output reg [31:0] regfile_pre_data_w_ex_dm,
    output reg [31:0] regfile_data_b_ex_dm,
    output reg halt_ex_dm,
    output reg [4:0] regfile_req_w_ex_dm,
    output reg regfile_w_en_ex_dm,
    output reg [`DM_OP_BIT - 1:0] datamem_op_ex_dm,
    output reg datamem_w_en_ex_dm,
    output reg memtoreg_ex_dm
	);

    initial begin
    	alu_data_res_ex_dm <= 0;
     	regfile_pre_data_w_ex_dm <= 0;
     	regfile_data_b_ex_dm <= 0;
     	halt_ex_dm <= 0;
      	regfile_req_w_ex_dm <=0;
        regfile_w_en_ex_dm <= 0;
      	datamem_op_ex_dm <= 0;
      	datamem_w_en_ex_dm <= 0;
      	memtoreg_ex_dm <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
    	if (!rst_n) begin
    		alu_data_res_ex_dm <= 0;
     		regfile_pre_data_w_ex_dm <= 0;
     		regfile_data_b_ex_dm <= 0;
     		halt_ex_dm <= 0;
      		regfile_req_w_ex_dm <=0;
           regfile_w_en_ex_dm <= 0;
      		datamem_op_ex_dm <= 0; 
      		datamem_w_en_ex_dm <= 0;
      		memtoreg_ex_dm <= 0;   		
    	end
    	else if (en) begin
    		alu_data_res_ex_dm <= alu_data_res;
     		regfile_pre_data_w_ex_dm <= regfile_pre_data_w;
     		regfile_data_b_ex_dm <= regfile_data_b_id_ex;
     		halt_ex_dm <= halt;
      		regfile_req_w_ex_dm <= regfile_req_w_id_ex;
           regfile_w_en_ex_dm <= regfile_w_en_id_ex;
      		datamem_op_ex_dm <= datamem_op_id_ex;
      		datamem_w_en_ex_dm <= datamem_w_en_id_ex;
      		memtoreg_ex_dm <= memtoreg_id_ex;    
    	end
    	else begin
    		alu_data_res_ex_dm <= alu_data_res_ex_dm;
     		regfile_pre_data_w_ex_dm <= regfile_pre_data_w_ex_dm;
     		regfile_data_b_ex_dm <= regfile_data_b_ex_dm;
     		halt_ex_dm <= halt_ex_dm;
      		regfile_req_w_ex_dm <= regfile_req_w_ex_dm;
           regfile_w_en_ex_dm <= regfile_w_en_ex_dm;
      		datamem_op_ex_dm <= datamem_op_ex_dm;
      		datamem_w_en_ex_dm <= datamem_w_en_ex_dm;
      		memtoreg_ex_dm <= memtoreg_ex_dm;
    	end
    end
endmodule