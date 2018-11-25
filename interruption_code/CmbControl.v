`timescale 1ns / 1ps

`include "Core.vh"

// Brief: Control Module, synchronized
// Author: FluorineDog
module CmbControl(
    input [5:0] opcode,
    input [4:0] rt,
    input [4:0] rs,
    input [4:0] rd,
    input [5:0] funct,
    input [31:0] ie, 
    input int,
    input inting_id_ex, inting_ex_dm,
    input w_en_ie_id_ex,w_en_ie_ex_dm,
    input w_en_epc_id_ex,w_en_epc_ex_dm,

    output reg [`WTG_OP_BIT - 1:0] op_wtg,
    output reg w_en_regfile,
    output reg [`ALU_OP_BIT - 1:0] op_alu,
    output reg [`DM_OP_BIT - 1:0] op_datamem,
    output reg w_en_datamem,
    output reg syscall_en,
    output reg [`MUX_RF_REQA_BIT - 1:0] mux_regfile_req_a,
    output reg [`MUX_RF_REQB_BIT - 1:0] mux_regfile_req_b,
    output reg [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w,
    output reg [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w,
    output reg [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y,
    output reg memtoreg,
    output reg jal,
    output reg cp0toreg,
    output inting,
    output reg w_en_ie, w_en_epc,
    //output reg [31:0] ie_w_data,
    output reg [`CP0_OP_BIT-1:0] op_cp0,
    output int_nop
);
    wire cp0_collision = w_en_ie_id_ex || w_en_ie_ex_dm ||
                        w_en_epc_id_ex || w_en_epc_ex_dm;
    assign int_nop = (int && cp0_collision) || //侦测到int的数据冲突（有写CP0且有INT）
                     ((op_cp0 == `CP0_OP_RET) && (w_en_epc_ex_dm || w_en_epc_id_ex)) || //CTL在侦测到ERET的数据冲突
                     ( cp0toreg && (w_en_epc_ex_dm || w_en_epc_id_ex)); //CTL在侦测到MFC0的数据冲突
    assign inting = int && (!(inting_id_ex || inting_ex_dm)) && (!cp0_collision) &&(ie[0]);
    always@(*) begin
        op_wtg = int ? `WTG_OP_IRQ :`WTG_OP_NOP;
        op_alu = `ALU_OP_AND;
        op_datamem = `DM_OP_WD;
        op_cp0 = int?`CP0_OP_IRQ:`CP0_OP_NOP; 
        w_en_regfile = 1;
        w_en_datamem = 0;
        w_en_epc = int?1:0;
        w_en_ie = int?1:0;
        syscall_en = 0;

        mux_regfile_req_w = `MUX_RF_REQW_RT;
        mux_regfile_data_w = `MUX_RF_DATAW_ALU;
        mux_alu_data_y = `MUX_ALU_DATAY_EXTS;
        mux_regfile_req_a = `MUX_RF_REQA_RS;
        mux_regfile_req_b = `MUX_RF_REQB_RT;  
        memtoreg = 0;
        cp0toreg = 0;
        jal = 0;
        case(opcode)
            6'b000000:  begin 
                mux_regfile_req_w   = `MUX_RF_REQW_RD;
                mux_regfile_data_w  = `MUX_RF_DATAW_ALU;
                mux_alu_data_y      = `MUX_ALU_DATAY_RFB;

                case(funct)
                    6'b000000:  op_alu = `ALU_OP_SLL;       // sll
                    6'b000010:  op_alu = `ALU_OP_SRL;       // srl
                    6'b000011:  op_alu = `ALU_OP_SRA;       // sra
                    6'b000100:  op_alu = `ALU_OP_SLLV;      // sllv
                    6'b000110:  op_alu = `ALU_OP_SRLV;      // srlv
                    6'b000111:  op_alu = `ALU_OP_SRAV;      // srav
                    6'b001000:  begin                       // jr
                        op_wtg = int?`WTG_OP_IRQ:`WTG_OP_J32;
                        w_en_regfile = 0;
                    end
                    6'b001100:  begin                       // syscall
                        syscall_en = 1;
                        w_en_regfile = 0;
                        mux_regfile_req_a = `MUX_RF_REQA_SYS;
                        mux_regfile_req_b = `MUX_RF_REQB_SYS;
                    end
                    6'b100000:  op_alu = `ALU_OP_ADD;       // add
                    6'b100001:  op_alu = `ALU_OP_ADD;       // addu
                    6'b100010:  op_alu = `ALU_OP_SUB;       // sub
                    6'b100011:  op_alu = `ALU_OP_SUB;       // subu
                    6'b100100:  op_alu = `ALU_OP_AND;       // and
                    6'b100101:  op_alu = `ALU_OP_OR;        // or
                    6'b100110:  op_alu = `ALU_OP_XOR;       // xor
                    6'b100111:  op_alu = `ALU_OP_NOR;       // nor
                    6'b101010:  op_alu = `ALU_OP_SLT;       // slt
                    6'b101011:  op_alu = `ALU_OP_SLTU;      // sltu
                endcase
            end

            6'b000001:  begin
                mux_regfile_req_b = `MUX_RF_REQB_ZERO;
                w_en_regfile = 0;
                case(rt[0])
                    1'b0: begin op_wtg = int?`WTG_OP_IRQ:`WTG_OP_BLTZ;  end  // bltz
                    1'b1: begin op_wtg = int?`WTG_OP_IRQ:`WTG_OP_BGEZ;  end  // bgez
                endcase
            end
            6'b000010:  begin   op_wtg = int?`WTG_OP_IRQ:`WTG_OP_J26;   mux_regfile_req_b = `MUX_RF_REQB_ZERO; w_en_regfile = 0; end    // j
            6'b000011:  begin   op_wtg = int?`WTG_OP_IRQ:`WTG_OP_J26;  mux_regfile_req_b = `MUX_RF_REQB_ZERO; jal = 1;                         // jal
                mux_regfile_req_w = `MUX_RF_REQW_31;
                mux_regfile_data_w = `MUX_RF_DATAW_PC4;
            end
            6'b000100:  begin   op_wtg = int?`WTG_OP_IRQ:`WTG_OP_BEQ;  w_en_regfile = 0; end    // beq
            6'b000101:  begin   op_wtg = int?`WTG_OP_IRQ:`WTG_OP_BNE;  w_en_regfile = 0; end    // bne
            6'b000110:  begin   op_wtg = int?`WTG_OP_IRQ:`WTG_OP_BLEZ; w_en_regfile = 0; end    // blez
            6'b000111:  begin   op_wtg = int?`WTG_OP_IRQ:`WTG_OP_BGTZ; w_en_regfile = 0; end    // bgtz

            6'b001000:  begin        op_alu = `ALU_OP_ADD;   mux_regfile_req_b = `MUX_RF_REQB_ZERO; end// addi
            6'b001001:  begin        op_alu = `ALU_OP_ADD;   mux_regfile_req_b = `MUX_RF_REQB_ZERO; end    // addiu
            6'b001010:  begin        op_alu = `ALU_OP_SLT;   mux_regfile_req_b = `MUX_RF_REQB_ZERO; end    // slti
            6'b001011:  begin        op_alu = `ALU_OP_SLTU;  mux_regfile_req_b = `MUX_RF_REQB_ZERO; end    // sltiu

            6'b001100:  begin   op_alu = `ALU_OP_AND; mux_alu_data_y = `MUX_ALU_DATAY_EXTZ; mux_regfile_req_b = `MUX_RF_REQB_ZERO; end     // andi
            6'b001101:  begin   op_alu = `ALU_OP_OR;  mux_alu_data_y = `MUX_ALU_DATAY_EXTZ; mux_regfile_req_b = `MUX_RF_REQB_ZERO; end     // ori
            6'b001110:  begin   op_alu = `ALU_OP_XOR; mux_alu_data_y = `MUX_ALU_DATAY_EXTZ; mux_regfile_req_b = `MUX_RF_REQB_ZERO; end     // xori

            6'b001111:  begin   op_alu = `ALU_OP_LUI; mux_regfile_data_w = `MUX_RF_DATAW_ALU; mux_regfile_req_b = `MUX_RF_REQB_ZERO; end   // lui

            6'b100000:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; 
                                op_datamem = `DM_OP_SB; memtoreg = 1; mux_regfile_req_b = `MUX_RF_REQB_ZERO;
                        end    // lb
            6'b100001:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; 
                                op_datamem = `DM_OP_SH; memtoreg =1; mux_regfile_req_b = `MUX_RF_REQB_ZERO;
                        end    // lh
            6'b100011:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; 
                                op_datamem = `DM_OP_WD; memtoreg = 1; mux_regfile_req_b = `MUX_RF_REQB_ZERO;
                        end    // lw
            6'b100100:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; 
                                op_datamem = `DM_OP_UB; memtoreg = 1; mux_regfile_req_b = `MUX_RF_REQB_ZERO;
                        end    // lbu
            6'b100101:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; 
                                op_datamem = `DM_OP_UH; memtoreg = 1; mux_regfile_req_b = `MUX_RF_REQB_ZERO;
                        end    // lhu

            6'b101000:  begin   op_alu = `ALU_OP_ADD; op_datamem = `DM_OP_SB; w_en_datamem = 1; w_en_regfile = 0; end       // sb
            6'b101001:  begin   op_alu = `ALU_OP_ADD; op_datamem = `DM_OP_SH; w_en_datamem = 1; w_en_regfile = 0; end       // sh
            6'b101011:  begin   op_alu = `ALU_OP_ADD; op_datamem = `DM_OP_WD; w_en_datamem = 1; w_en_regfile = 0; end       // sw
            6'b010000: begin
                if(funct == 6'b011000) begin //eret
                    w_en_regfile = 0;
                    w_en_ie = 1;
                    w_en_epc = 1;
                    op_wtg = `WTG_OP_RET;  
                    //ie_w_data = 32'b1;
                    op_cp0 = `CP0_OP_RET;
                end
                else begin
                    if(rs == 5'b00100) begin //mtc0
                        w_en_regfile = 0;
                        w_en_ie = rd[1];
                        w_en_epc = rd[0];
                    end
                    else if(rs == 5'b00000) begin //mfc0
                        w_en_regfile = 1;
                        cp0toreg = 1;  //epc to reg
                    end
                end
            end
          endcase
          
      end
endmodule

//
