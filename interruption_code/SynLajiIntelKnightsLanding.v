`timescale 1ns / 1ps
`include "Core.vh"

// Brief: CPU Top Module, synchronized
// Author: EAirPeter
module SynLajiIntelKnightsLanding(
    clk, rst_n, en, regfile_req_dbg, datamem_addr_dbg, irq_type,
    pc_dbg, regfile_data_dbg, datamem_data_dbg, display,
    halted, jumped, is_branch, branched, load_use
);
    input [2:0] irq_type;
    parameter ProgPath = "E:/lab/test/interrupt_benchmark.hex";
    input clk, rst_n, en;
    input [4:0] regfile_req_dbg;
    input [11:0] datamem_addr_dbg;
    
    output [31:0] pc_dbg;
    output [31:0] regfile_data_dbg;
    output [31:0] datamem_data_dbg;
    output [31:0] display;
    output halted, jumped, is_branch, branched;
    output load_use;

// IF
    wire [31:0] pc, pc_4;
    assign pc_dbg = {20'd0, pc, 2'd0};
    wire [31:0] inst;
    wire [31:0] pc_new;
    wire jp_success = jumped || branched;
    wire irq_ret = (wtg_op_id_ex == `WTG_OP_RET) || (wtg_op_id_ex == `WTG_OP_IRQ); 
    wire halt; 
    wire int_nop;
    SynPC vPC(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .int_nop(int_nop),
        .load_use(load_use),
        .jp_success(jp_success),
        .irq_ret(irq_ret),
        .pc_new(pc_new),
        .pc(pc),
        .pc_4(pc_4)
    );
    CmbInstMem #(
        .ProgPath(ProgPath)
    ) vIM(
        .addr(pc),
        .inst(inst)
    );

// IF/ID
// pc_4, inst
    wire[31:0] pc_4_if_id;
    wire[31:0] inst_if_id;
    wire inting;

    Pipline_IF_ID pIF_ID(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .jp_success(jp_success),
        .load_use(load_use),
        .int_nop(int_nop),
        .inting(inting),
        .pc_4(pc_4), 
        .inst(inst), 
        .pc_4_if_id(pc_4_if_id), 
        .inst_if_id(inst_if_id)
        );

// ID
    wire [5:0] opcode, funct;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm16;
    wire [25:0] imm26;

    CmbDecoder vDec(
        .inst(inst_if_id),
        .opcode(opcode),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .shamt(shamt),
        .funct(funct),
        .imm16(imm16),
        .imm26(imm26)
    );

    wire [31:0] ext_out_sign, ext_out_zero;
    CmbExt vExt(
        .imm16(imm16),
        .out_sign(ext_out_sign),
        .out_zero(ext_out_zero)
    );

    wire [`WTG_OP_BIT - 1:0] wtg_op;
    wire [`ALU_OP_BIT - 1:0] alu_op;
    wire [`DM_OP_BIT - 1:0] datamem_op;
    wire datamem_w_en;
    wire syscall_en;
    wire regfile_w_en;
    wire memtoreg;
    wire jal;
    wire [`MUX_RF_REQA_BIT - 1:0] mux_regfile_req_a;
    wire [`MUX_RF_REQB_BIT - 1:0] mux_regfile_req_b;    
    wire [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w;
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;
    wire inting_id_ex, inting_ex_dm;
    wire cp0toreg;
    wire w_en_ie, w_en_epc;
    wire [1:0] op_cp0;
    wire int;
    wire w_en_ie_id_ex,w_en_epc_id_ex;
    wire w_en_ie_ex_dm,w_en_epc_ex_dm;
    wire [31:0] ie;
    
    CmbControl vCtl(
        .opcode(opcode),
        .rt(rt),
        .rs(rs),
        .rd(rd),
        .funct(funct),
        .int(int),
        .ie(ie),
        .inting_id_ex(inting_id_ex),
        .inting_ex_dm(inting_ex_dm),
        .w_en_ie_id_ex(w_en_ie_id_ex),
        .w_en_ie_ex_dm(w_en_ie_ex_dm),
        .w_en_epc_id_ex(w_en_epc_id_ex),
        .w_en_epc_ex_dm(w_en_epc_ex_dm),

        .op_wtg(wtg_op),
        .w_en_regfile(regfile_w_en),
        .op_alu(alu_op),
        .op_datamem(datamem_op),
        .w_en_datamem(datamem_w_en),
        .syscall_en(syscall_en),
        .mux_regfile_req_a(mux_regfile_req_a),
        .mux_regfile_req_b(mux_regfile_req_b),
        .mux_regfile_req_w(mux_regfile_req_w),
        .mux_regfile_data_w(mux_regfile_data_w),
        .mux_alu_data_y(mux_alu_data_y),
        .memtoreg(memtoreg),
        .jal(jal),
        .inting(inting),
        .cp0toreg(cp0toreg),
        .w_en_ie(w_en_ie),
        .w_en_epc(w_en_epc),
        .op_cp0(op_cp0),
        .int_nop(int_nop)
    );

    reg [4:0] regfile_req_a, regfile_req_b, regfile_req_w;    // combinatorial
    always @(*) begin
        case (mux_regfile_req_a)
            `MUX_RF_REQA_RS:
                regfile_req_a = rs;
            `MUX_RF_REQA_SYS:
                regfile_req_a = 5'd2;
            default:
                regfile_req_a = 5'd0;
        endcase
        case (mux_regfile_req_b)
            `MUX_RF_REQB_RT:
                regfile_req_b = rt;
            `MUX_RF_REQB_SYS:
                regfile_req_b = 5'd4;
            default:
                regfile_req_b = 5'd0;
        endcase
        case (mux_regfile_req_w)
            `MUX_RF_REQW_RD:
                regfile_req_w = rd;
            `MUX_RF_REQW_RT:
                regfile_req_w = rt;
            `MUX_RF_REQW_31:
                regfile_req_w = 5'd31;
            default:
                regfile_req_w = 5'd0;
        endcase  
    end
    wire regfile_w_en_wb;
    wire [4:0] regfile_req_w_wb;
    wire [31:0] regfile_data_w_wb;
    wire [31:0] regfile_data_a, regfile_data_b;
    //reg [31:0] regfile_data_w;  // combinatorial
    SynRegFile vRF(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .w_en(regfile_w_en_wb),
        .req_dbg(regfile_req_dbg),
        .req_w(regfile_req_w_wb),
        .req_a(regfile_req_a),
        .req_b(regfile_req_b),
        .data_dbg(regfile_data_dbg),
        .data_w(regfile_data_w_wb),
        .data_a(regfile_data_a),
        .data_b(regfile_data_b)
    );

    wire [1:0] op_cp0_wb;
    wire w_en_ie_wb, w_en_epc_wb;
    reg [31:0] ie_w_data, epc_w_data;
    wire [31:0] regfile_data_b_wb;
    always @(*) begin
        case(op_cp0_wb)
            `CP0_OP_IRQ:begin
                ie_w_data <= 32'b0;   
            end
            `CP0_OP_RET:begin
                ie_w_data <= 32'b1;
            end
            default:begin
                ie_w_data <= regfile_data_b_wb;
            end
        endcase
    end
    //epc mux
    wire [31:0] pc_4_wb;
    always @(*) begin
        if (op_cp0_wb == `CP0_OP_IRQ) 
            epc_w_data <= (pc_4_wb - 4);
        else 
            epc_w_data <= regfile_data_b_wb;
    end
    wire [2:0] ir;
    wire [31:0] epc;
    //wire [31:0] ie;
    wire [1:0] int_num;
    SynCP0 vCP0(
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en),
        .irq_type(irq_type),
        .op_cp0(op_cp0_wb),
        .w_en_ie(w_en_ie_wb), 
        .w_en_epc(w_en_epc_wb),
        .ie_w_data(ie_w_data), 
        .epc_w_data(epc_w_data),
        .ir(ir),
        .epc(epc),
        .ie(ie),
        .int(int),
        .int_num(int_num)
    );

    wire data_conflict_regA_id_ex,data_conflict_regA_ex_dm;
    wire data_conflict_regB_id_ex,data_conflict_regB_ex_dm;
    wire redirect_regA_ex_dm, redirect_regA_dm_wb;
    wire redirect_regB_ex_dm, redirect_regB_dm_wb;

    assign data_conflict_regA_id_ex = (regfile_req_a == regfile_req_w_id_ex) && (regfile_req_a != 0) && regfile_w_en_id_ex;
    assign redirect_regA_ex_dm = data_conflict_regA_id_ex && (memtoreg_id_ex != 1);

    assign data_conflict_regA_ex_dm = (regfile_req_a == regfile_req_w_ex_dm) && (regfile_req_a != 0) && regfile_w_en_ex_dm;
    assign redirect_regA_dm_wb = data_conflict_regA_ex_dm;

    assign data_conflict_regB_id_ex = (regfile_req_b == regfile_req_w_id_ex) && (regfile_req_b != 0) && regfile_w_en_id_ex;
    assign redirect_regB_ex_dm = data_conflict_regB_id_ex && (memtoreg_id_ex != 1) ;

    assign data_conflict_regB_ex_dm = (regfile_req_b == regfile_req_w_ex_dm) && (regfile_req_b != 0) && regfile_w_en_ex_dm;
    assign redirect_regB_dm_wb = data_conflict_regB_ex_dm;

    assign load_use = (data_conflict_regA_id_ex && memtoreg_id_ex) ||
                      (data_conflict_regB_id_ex && memtoreg_id_ex) ;

    

    
// ID/EX
// DEC.shamt
// EXT.Sext, Zext
// CTL.wtg_op, alu_op, mux_alu_data_y, datamem_op, datamem_w_en, syscall_en, mux_regfile_data_w(will be split later)
// (redirect) CTL.mux_ex_regfile_data_a, mux_ex_regfile_data_b
//      for now just treat read DM -> rt & write rt-> DM as load-use
// RF.a, b
// MUX_RF_REQ_W regfile_req_w
    wire jal_id_ex;
    wire memtoreg_id_ex;
    wire [25:0] imm26_id_ex;
    wire [4:0] shamt_id_ex;
    wire [31:0] ext_out_sign_id_ex, ext_out_zero_id_ex;
    wire [`WTG_OP_BIT - 1:0] wtg_op_id_ex;
    wire [`ALU_OP_BIT - 1:0] alu_op_id_ex;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y_id_ex;
    wire [`DM_OP_BIT - 1:0] datamem_op_id_ex;
    wire datamem_w_en_id_ex;
    wire syscall_en_id_ex;
    wire [4:0] regfile_req_w_id_ex;    // combinatorial
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w_id_ex;
//    wire [] mux_ex_regfile_data_a_id_ex, mux_ex_regfile_data_b_id_ex; // for redirect
    wire [31:0] regfile_data_a_id_ex, regfile_data_b_id_ex;
    wire [31:0] pc_4_id_ex;
    wire regfile_w_en_id_ex;
    wire redirect_regA_ex_dm_id_ex, redirect_regA_dm_wb_id_ex;
    wire redirect_regB_ex_dm_id_ex, redirect_regB_dm_wb_id_ex;
    wire [1:0] op_cp0_id_ex;
    wire [31:0] epc_id_ex;
    wire cp0toreg_id_ex;
    wire [1:0] int_num_id_ex;

Pipline_ID_EX pID_EX(
     .clk(clk), 
     .rst_n(rst_n),
     .load_use(load_use),
     .jp_success(jp_success),
     .en(en),
     .int_nop(int_nop),

     .w_en_epc(w_en_epc),
     .w_en_ie(w_en_ie),
     .inting(inting),
     .imm26(imm26),
     .shamt(shamt),
     .ext_out_sign(ext_out_sign), 
     .ext_out_zero(ext_out_zero),
     .wtg_op(wtg_op),
     .alu_op(alu_op),
     .mux_alu_data_y(mux_alu_data_y),
     .datamem_op(datamem_op),
     .datamem_w_en(datamem_w_en),
     .syscall_en(syscall_en),
     .regfile_req_w(regfile_req_w),
     .regfile_w_en(regfile_w_en),
     .mux_regfile_data_w(mux_regfile_data_w),
     .regfile_data_a(regfile_data_a), 
     .regfile_data_b(regfile_data_b),
     .pc_4_if_id(pc_4_if_id),
     .memtoreg(memtoreg),
     .jal(jal),
     .redirect_regA_ex_dm(redirect_regA_ex_dm),
     .redirect_regA_dm_wb(redirect_regA_dm_wb),
     .redirect_regB_ex_dm(redirect_regB_ex_dm),
     .redirect_regB_dm_wb(redirect_regB_dm_wb),
     .op_cp0(op_cp0),
     .epc(epc),
     .cp0toreg(cp0toreg),
     .int_num(int_num),

    .imm26_id_ex(imm26_id_ex),
    .shamt_id_ex(shamt_id_ex),  
    .ext_out_sign_id_ex(ext_out_sign_id_ex),
    .ext_out_zero_id_ex(ext_out_zero_id_ex),  
    .wtg_op_id_ex(wtg_op_id_ex),
    .alu_op_id_ex(alu_op_id_ex),    
    .mux_alu_data_y_id_ex(mux_alu_data_y_id_ex),    
    .datamem_op_id_ex(datamem_op_id_ex),    
    .datamem_w_en_id_ex(datamem_w_en_id_ex),   
    .syscall_en_id_ex(syscall_en_id_ex),    
    .regfile_req_w_id_ex(regfile_req_w_id_ex),
    .regfile_w_en_id_ex(regfile_w_en_id_ex),   
    .mux_regfile_data_w_id_ex(mux_regfile_data_w_id_ex),    
    .regfile_data_a_id_ex(regfile_data_a_id_ex),
    .regfile_data_b_id_ex(regfile_data_b_id_ex),
    .pc_4_id_ex(pc_4_id_ex),
    .memtoreg_id_ex(memtoreg_id_ex),
    .jal_id_ex(jal_id_ex),
    .redirect_regA_ex_dm_id_ex(redirect_regA_ex_dm_id_ex),
    .redirect_regA_dm_wb_id_ex(redirect_regA_dm_wb_id_ex),
    .redirect_regB_ex_dm_id_ex(redirect_regB_ex_dm_id_ex),
    .redirect_regB_dm_wb_id_ex(redirect_regB_dm_wb_id_ex),
    .w_en_ie_id_ex(w_en_ie_id_ex),
    .w_en_epc_id_ex(w_en_epc_id_ex),
    .inting_id_ex(inting_id_ex),
    .op_cp0_id_ex(op_cp0_id_ex),
    .epc_id_ex(epc_id_ex),
    .cp0toreg_id_ex(cp0toreg_id_ex),
    .int_num_id_ex(int_num_id_ex)
);

// EX   
    reg [31:0] regfile_data_b_redirect;
    always @(*) begin
        if (redirect_regB_ex_dm_id_ex) begin
            regfile_data_b_redirect = regfile_pre_data_w_ex_dm;            
        end
        else if (redirect_regB_dm_wb_id_ex) begin
            regfile_data_b_redirect = regfile_data_w_dm_wb;
        end
        else begin
            regfile_data_b_redirect = regfile_data_b_id_ex;
        end
    end

    reg [31:0] regfile_data_a_redirect;
    always @(*) begin
        if (redirect_regA_ex_dm_id_ex) begin
           regfile_data_a_redirect = regfile_pre_data_w_ex_dm;
        end
        else if (redirect_regA_dm_wb_id_ex) begin
            regfile_data_a_redirect = regfile_data_w_dm_wb;
        end
        else begin
            regfile_data_a_redirect = regfile_data_a_id_ex;
        end
    end

  reg [31:0] alu_data_y;      // combinatorial
    always @(*) begin
        case (mux_alu_data_y_id_ex)
            `MUX_ALU_DATAY_RFB: 
                alu_data_y = regfile_data_b_redirect;
            `MUX_ALU_DATAY_EXTS:
                alu_data_y = ext_out_sign_id_ex;
            `MUX_ALU_DATAY_EXTZ:
                alu_data_y = ext_out_zero_id_ex;
            default:
                alu_data_y = 32'd0;
        endcase
    end
    wire [31:0] alu_data_res;
    CmbALU vALU(
        .op(alu_op_id_ex),
        .data_x(regfile_data_a_redirect),
        .data_y(alu_data_y),
        .shamt(shamt_id_ex),
        .data_res(alu_data_res)
    );

     CmbWTG vWTG(
        .op(wtg_op_id_ex),
        .off32(ext_out_sign_id_ex),
        .imm26(imm26_id_ex),
        .data_x(regfile_data_a_redirect),
        .data_y(regfile_data_b_redirect),
        .pc_4(pc_4_id_ex),
        .int_num(int_num_id_ex),
        .epc(epc),
        .pc_new(pc_new),
        .branched(branched),
        .jumped(jumped),
        .is_branch(is_branch)       
    );

    //wire halt;
    SynSyscall vSys(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .syscall_en(syscall_en_id_ex),
        .data_v0(regfile_data_a_redirect),
        .data_a0(regfile_data_b_redirect),
        .display(display),
        .halt(halt)
    );
    
    reg [31:0] regfile_pre_data_w;
    always @(*) begin
       if (jal_id_ex) begin
           regfile_pre_data_w <= pc_4_id_ex;
       end
       else if (cp0toreg_id_ex) begin
           regfile_pre_data_w <= epc_id_ex;
       end
       else begin
           regfile_pre_data_w <= alu_data_res;
       end
    end
// EX/DM
// ALU.alu_data_res
// RF.regfile_data_b
// SYS.halt
// MUX.regfile_pre_data_w
// regfile_req_w
    wire memtoreg_ex_dm;
    wire [31:0] alu_data_res_ex_dm;
    wire [31:0] regfile_pre_data_w_ex_dm;
    wire [31:0] regfile_data_b_ex_dm;
    wire halt_ex_dm;
    wire [4:0] regfile_req_w_ex_dm;
    wire [`DM_OP_BIT - 1:0] datamem_op_ex_dm;
    wire datamem_w_en_ex_dm;
    wire [31:0] pc_4_ex_dm;
    wire [1:0] op_cp0_ex_dm;

    Pipline_EX_DM pEX_DM(
     .clk(clk),
     .rst_n(rst_n),
     .en(en),
     .alu_data_res(alu_data_res),
     .regfile_pre_data_w(regfile_pre_data_w),
     .regfile_data_b_id_ex(regfile_data_b_redirect),
     .halt(halt),
     .regfile_req_w_id_ex(regfile_req_w_id_ex),
     .regfile_w_en_id_ex(regfile_w_en_id_ex),
     .datamem_op_id_ex(datamem_op_id_ex),
     .datamem_w_en_id_ex(datamem_w_en_id_ex),
     .memtoreg_id_ex(memtoreg_id_ex),
     .pc_4_id_ex(pc_4_id_ex),
     .w_en_ie_id_ex(w_en_ie_id_ex),
     .w_en_epc_id_ex(w_en_epc_id_ex),
     .inting_id_ex(inting_id_ex),
     .op_cp0_id_ex(op_cp0_id_ex),

     .alu_data_res_ex_dm(alu_data_res_ex_dm),
     .regfile_pre_data_w_ex_dm(regfile_pre_data_w_ex_dm),
     .regfile_data_b_ex_dm(regfile_data_b_ex_dm),
     .halt_ex_dm(halt_ex_dm),
     .regfile_req_w_ex_dm(regfile_req_w_ex_dm),
     .regfile_w_en_ex_dm(regfile_w_en_ex_dm),
     .datamem_op_ex_dm(datamem_op_ex_dm),
     .datamem_w_en_ex_dm(datamem_w_en_ex_dm),
     .memtoreg_ex_dm(memtoreg_ex_dm),
     .pc_4_ex_dm(pc_4_ex_dm),
     .w_en_ie_ex_dm(w_en_ie_ex_dm),
     .w_en_epc_ex_dm(w_en_epc_ex_dm),
     .inting_ex_dm(inting_ex_dm),
     .op_cp0_ex_dm(op_cp0_ex_dm)
    );

// DM
    wire [31:0] datamem_data;
    SynDataMem vDM(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .op(datamem_op_ex_dm),
        .w_en(datamem_w_en_ex_dm),
        .addr_dbg(datamem_addr_dbg),
        .addr(alu_data_res_ex_dm[11:0]),
        .data_in(regfile_data_b_ex_dm),
        .data_dbg(datamem_data_dbg),
        .data(datamem_data)
    );

  reg [31:0] regfile_data_w;
    always @(*) begin
        if (memtoreg_ex_dm) begin
            regfile_data_w <= datamem_data;
        end
        else begin
            regfile_data_w <= regfile_pre_data_w_ex_dm;
        end
    end

// DM/WB
// MUX.regfile_data_w
// regfile_req_w
    // always @(*) begin
        // get regfile_data_w
    // end
    wire halt_dm_wb;
    wire regfile_w_en_dm_wb;
    wire [4:0] regfile_req_w_dm_wb;
    wire [31:0] regfile_data_w_dm_wb;
    wire [31:0] pc_4_dm_wb;
    wire w_en_ie_dm_wb, w_en_epc_dm_wb;
    wire [31:0] regfile_data_b_dm_wb;
    wire [1:0] op_cp0_dm_wb;

   Pipline_DM_WB pDM_WB(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .halt_ex_dm(halt_ex_dm),
        .regfile_w_en_ex_dm(regfile_w_en_ex_dm),
        .regfile_req_w_ex_dm(regfile_req_w_ex_dm),
        .regfile_data_w(regfile_data_w),
        .regfile_data_b_ex_dm(regfile_data_b_ex_dm),
        .pc_4_ex_dm(pc_4_ex_dm),
        .w_en_ie_ex_dm(w_en_ie_ex_dm),
        .w_en_epc_ex_dm(w_en_epc_ex_dm),
        .op_cp0_ex_dm(op_cp0_ex_dm),

        .halt_dm_wb(halt_dm_wb),
        .regfile_w_en_dm_wb(regfile_w_en_dm_wb),
        .regfile_req_w_dm_wb(regfile_req_w_dm_wb),
        .regfile_data_w_dm_wb(regfile_data_w_dm_wb),
        .regfile_data_b_dm_wb(regfile_data_b_dm_wb),
        .pc_4_dm_wb(pc_4_dm_wb),
        .w_en_ie_dm_wb(w_en_ie_dm_wb),
        .w_en_epc_dm_wb(w_en_epc_dm_wb),
        .op_cp0_dm_wb(op_cp0_dm_wb)
    );

// WB
    assign regfile_w_en_wb = regfile_w_en_dm_wb;
    assign halted = halt_dm_wb;
    assign regfile_req_w_wb = regfile_req_w_dm_wb;
    assign regfile_data_w_wb = regfile_data_w_dm_wb;
    assign regfile_data_b_wb = regfile_data_b_dm_wb;
    assign pc_4_wb = pc_4_dm_wb;
    assign w_en_ie_wb = w_en_ie_dm_wb;
    assign w_en_epc_wb = w_en_epc_dm_wb;
    assign op_cp0_wb = op_cp0_dm_wb;
endmodule