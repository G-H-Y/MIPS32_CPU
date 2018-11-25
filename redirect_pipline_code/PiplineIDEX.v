`include "Core.vh"
module Pipline_ID_EX(
    input clk, rst_n,
    input load_use,
    input jp_success,
    input en,
    //input halt,
    
    input [25:0] imm26,
	input [4:0] shamt,
    input [31:0] ext_out_sign, ext_out_zero,
    input [`WTG_OP_BIT - 1:0] wtg_op,
    input [`ALU_OP_BIT - 1:0] alu_op,
    input [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y,
    input [`DM_OP_BIT - 1:0] datamem_op,
	input datamem_w_en,
    input syscall_en,
    input [4:0] regfile_req_w,
    input regfile_w_en,
    input [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w,
    input [31:0] regfile_data_a, regfile_data_b,
    input [31:0] pc_4_if_id,
    input memtoreg,
    input jal,
    input redirect_regA_ex_dm, redirect_regA_dm_wb,
    input redirect_regB_ex_dm, redirect_regB_dm_wb,
    
    output reg [25:0] imm26_id_ex,
	output reg [4:0] shamt_id_ex,	
	output reg [31:0] ext_out_sign_id_ex,ext_out_zero_id_ex,	
	output reg [`WTG_OP_BIT - 1:0] wtg_op_id_ex,       
    output reg [`ALU_OP_BIT - 1:0] alu_op_id_ex,    
    output reg [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y_id_ex,    
    output reg [`DM_OP_BIT - 1:0] datamem_op_id_ex,    
    output reg datamem_w_en_id_ex,    
    output reg syscall_en_id_ex,    
    output reg [4:0] regfile_req_w_id_ex,
    output reg regfile_w_en_id_ex,   
    output reg [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w_id_ex,    
    output reg [31:0] regfile_data_a_id_ex, regfile_data_b_id_ex,
    output reg [31:0] pc_4_id_ex,
    output reg memtoreg_id_ex,
    output reg jal_id_ex,
    output reg redirect_regA_ex_dm_id_ex, redirect_regA_dm_wb_id_ex,
    output reg redirect_regB_ex_dm_id_ex, redirect_regB_dm_wb_id_ex
	);

    initial begin
        imm26_id_ex <= 0;
    	shamt_id_ex <= 0;	
	    ext_out_sign_id_ex<=0;
	    ext_out_zero_id_ex<=0;	
	    wtg_op_id_ex<=0;     
        alu_op_id_ex<=0;    
        mux_alu_data_y_id_ex<=0;    
        datamem_op_id_ex<=0;    
        datamem_w_en_id_ex<=0;   
        syscall_en_id_ex<=0;    
        regfile_req_w_id_ex<=0; 
        regfile_w_en_id_ex <= 0;  
        mux_regfile_data_w_id_ex<=0;    
        regfile_data_a_id_ex<=0;
        regfile_data_b_id_ex<=0;
        memtoreg_id_ex <= 0;
        pc_4_id_ex <= 0;
        jal_id_ex <= 0;
        redirect_regA_ex_dm_id_ex <= 0; 
        redirect_regA_dm_wb_id_ex <= 0;
        redirect_regB_ex_dm_id_ex <= 0;
        redirect_regB_dm_wb_id_ex <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
    	if (!rst_n ) begin
    		imm26_id_ex <= 0;
    		shamt_id_ex <= 0;	
	    	ext_out_sign_id_ex<=0;
	    	ext_out_zero_id_ex<=0;	
	    	wtg_op_id_ex<=0;     
        	alu_op_id_ex<=0;    
        	mux_alu_data_y_id_ex<=0;    
        	datamem_op_id_ex<=0;    
        	datamem_w_en_id_ex<=0;   
        	syscall_en_id_ex<=0;    
        	regfile_req_w_id_ex<=0;
            regfile_w_en_id_ex <= 0;   
        	mux_regfile_data_w_id_ex<=0;    
        	regfile_data_a_id_ex<=0;
        	regfile_data_b_id_ex<=0;
            memtoreg_id_ex <= 0;
            pc_4_id_ex <= 0;
            jal_id_ex <= 0;
            redirect_regA_ex_dm_id_ex <= 0; 
            redirect_regA_dm_wb_id_ex <= 0;
            redirect_regB_ex_dm_id_ex <= 0;
            redirect_regB_dm_wb_id_ex <= 0;    		
    	end
        else if(jp_success || load_use) begin
            imm26_id_ex <= 0;
            shamt_id_ex <= 0;   
            ext_out_sign_id_ex<=0;
            ext_out_zero_id_ex<=0;  
            wtg_op_id_ex<=0;     
            alu_op_id_ex<=0;    
            mux_alu_data_y_id_ex<=0;    
            datamem_op_id_ex<=0;    
            datamem_w_en_id_ex<=0;   
            syscall_en_id_ex<=0;    
            regfile_req_w_id_ex<=0;
            regfile_w_en_id_ex <= 0;   
            mux_regfile_data_w_id_ex<=0;    
            regfile_data_a_id_ex<=0;
            regfile_data_b_id_ex<=0;
            memtoreg_id_ex <= 0;
            pc_4_id_ex <= 0;
            jal_id_ex <= 0;
            redirect_regA_ex_dm_id_ex <= 0; 
            redirect_regA_dm_wb_id_ex <= 0;
            redirect_regB_ex_dm_id_ex <= 0;
            redirect_regB_dm_wb_id_ex <= 0;     
        end
    	else if (en)begin
    	    imm26_id_ex <= imm26;
    		shamt_id_ex <= shamt;	
	    	ext_out_sign_id_ex <= ext_out_sign;
	    	ext_out_zero_id_ex<= ext_out_zero;	
	    	wtg_op_id_ex<=wtg_op;     
        	alu_op_id_ex<=alu_op;    
        	mux_alu_data_y_id_ex<= mux_alu_data_y;    
        	datamem_op_id_ex<=datamem_op;    
        	datamem_w_en_id_ex<=datamem_w_en;   
        	syscall_en_id_ex<=syscall_en;    
        	regfile_req_w_id_ex<=regfile_req_w;
            regfile_w_en_id_ex <= regfile_w_en;   
        	mux_regfile_data_w_id_ex<=mux_regfile_data_w;    
        	regfile_data_a_id_ex<=regfile_data_a;
        	regfile_data_b_id_ex<=regfile_data_b;
            memtoreg_id_ex <= memtoreg;
            pc_4_id_ex <= pc_4_if_id;
            jal_id_ex <= jal;
            redirect_regA_ex_dm_id_ex <= redirect_regA_ex_dm; 
            redirect_regA_dm_wb_id_ex <= redirect_regA_dm_wb;
            redirect_regB_ex_dm_id_ex <= redirect_regB_ex_dm;
            redirect_regB_dm_wb_id_ex <= redirect_regB_dm_wb;
    	end

        else begin
            imm26_id_ex <= imm26_id_ex;
            shamt_id_ex <= shamt_id_ex;   
            ext_out_sign_id_ex <= ext_out_sign_id_ex;
            ext_out_zero_id_ex<= ext_out_zero_id_ex;  
            wtg_op_id_ex<=wtg_op_id_ex;     
            alu_op_id_ex<=alu_op_id_ex;    
            mux_alu_data_y_id_ex<= mux_alu_data_y_id_ex;    
            datamem_op_id_ex<=datamem_op_id_ex;    
            datamem_w_en_id_ex<=datamem_w_en_id_ex;   
            syscall_en_id_ex<=syscall_en_id_ex;    
            regfile_req_w_id_ex<=regfile_req_w_id_ex;
            regfile_w_en_id_ex <= regfile_w_en_id_ex;   
            mux_regfile_data_w_id_ex<=mux_regfile_data_w_id_ex;    
            regfile_data_a_id_ex<=regfile_data_a_id_ex;
            regfile_data_b_id_ex<=regfile_data_b_id_ex;
            memtoreg_id_ex <= memtoreg_id_ex;
            pc_4_id_ex <= pc_4_id_ex;
            jal_id_ex <= jal_id_ex;
            redirect_regA_ex_dm_id_ex <= redirect_regA_ex_dm_id_ex; 
            redirect_regA_dm_wb_id_ex <= redirect_regA_dm_wb_id_ex;
            redirect_regB_ex_dm_id_ex <= redirect_regB_ex_dm_id_ex;
            redirect_regB_dm_wb_id_ex <= redirect_regB_dm_wb_id_ex;
        end
    end

endmodule