module SynBHT(
	input clk,
	input rst_n,
	input en,
	input update_en,  //只要是分支指令就应该更新BHT
	input [31:0] pc_4,  //当前pc+4
	input [31:0] pc_4_id_ex, //从ex段传来的上上个指令的地址
	input [31:0] branch_jump_addr,  //从ex段传来的上上个指令的跳转地址
	input [1:0] binary_predict_id_ex,
	input jp_success,
	output [31:0] pc_predict,
	output [1:0] binary_predict
	);

	//reg [7:0] valid;
	reg [31:0] BHT_pc_4_index [7:0];
	reg [31:0] BHT_jp_brh_addr[7:0];
	reg [1:0] BHT_binary_predict [7:0];
	reg [11:0] BHT_lru_cnt [7:0];
	integer i,k,j,h;	
	wire [7:0] hit_search;
	reg hit;
	reg [2:0] hit_pos;
	reg [2:0] inBHT_pos;
	reg [2:0] available_pos;
	wire [2:0] update_pos;
	wire isfull;
	wire [7:0] update_search;
	reg [2:0] eviction_pos;
	reg [2:0] tmp_eviction_pos;
	reg [11:0] max_lru_cnt;
	reg isInBHT;	


	initial begin
		for(i=0; i<8; i=i+1) begin
			BHT_pc_4_index[i] = 32'b0;
			BHT_jp_brh_addr[i] = 32'b0;
			BHT_binary_predict[i] = 2'b01;
			BHT_lru_cnt[i] = 12'b0;
		end			
	end

	//查找
	
	assign hit_search[0] = (pc_4 == BHT_pc_4_index[0]);
	assign hit_search[1] = (pc_4 == BHT_pc_4_index[1]);
	assign hit_search[2] = (pc_4 == BHT_pc_4_index[2]);
	assign hit_search[3] = (pc_4 == BHT_pc_4_index[3]);
	assign hit_search[4] = (pc_4 == BHT_pc_4_index[4]);
	assign hit_search[5] = (pc_4 == BHT_pc_4_index[5]);
	assign hit_search[6] = (pc_4 == BHT_pc_4_index[6]);
	assign hit_search[7] = (pc_4 == BHT_pc_4_index[7]);
	always @(hit_search) begin
		hit = 1;
		case(hit_search)
			8'b00000001: begin hit_pos = 0; end
			8'b00000010: begin hit_pos = 1; end
			8'b00000100: begin hit_pos = 2; end
			8'b00001000: begin hit_pos = 3; end
			8'b00010000: begin hit_pos = 4; end
			8'b00100000: begin hit_pos = 5; end
			8'b01000000: begin hit_pos = 6; end
			8'b10000000: begin hit_pos = 7; end
			default: begin hit_pos = 0; hit = 0; end
		endcase
	end
    
    assign pc_predict = (hit&&(BHT_binary_predict[hit_pos] == 2'b10 || BHT_binary_predict[hit_pos] == 2'b11))? 
    					BHT_jp_brh_addr[hit_pos] : pc_4;
    assign binary_predict = hit? BHT_binary_predict[hit_pos] : 2'b01;

//update BHT
	assign update_search[0] = (pc_4_id_ex == BHT_pc_4_index[0]) && (BHT_pc_4_index[0] != 32'b0);
	assign update_search[1] = (pc_4_id_ex == BHT_pc_4_index[1]) && (BHT_pc_4_index[1] != 32'b0);
	assign update_search[2] = (pc_4_id_ex == BHT_pc_4_index[2]) && (BHT_pc_4_index[2] != 32'b0);
	assign update_search[3] = (pc_4_id_ex == BHT_pc_4_index[3]) && (BHT_pc_4_index[3] != 32'b0);
	assign update_search[4] = (pc_4_id_ex == BHT_pc_4_index[4]) && (BHT_pc_4_index[4] != 32'b0);
	assign update_search[5] = (pc_4_id_ex == BHT_pc_4_index[5]) && (BHT_pc_4_index[5] != 32'b0);
	assign update_search[6] = (pc_4_id_ex == BHT_pc_4_index[6]) && (BHT_pc_4_index[6] != 32'b0);
	assign update_search[7] = (pc_4_id_ex == BHT_pc_4_index[7]) && (BHT_pc_4_index[7] != 32'b0);
	assign isfull = (BHT_pc_4_index[0] != 32'b0) && (BHT_pc_4_index[1] != 32'b0) && 
				 	(BHT_pc_4_index[2] != 32'b0) && (BHT_pc_4_index[3] != 32'b0) &&
				 	(BHT_pc_4_index[4] != 32'b0) && (BHT_pc_4_index[5] != 32'b0) &&
				 	(BHT_pc_4_index[6] != 32'b0) && (BHT_pc_4_index[7] != 32'b0);

	always @(update_search or BHT_pc_4_index) begin
		isInBHT = 1;
		case(update_search)
			8'b00000001: begin inBHT_pos = 0; end
			8'b00000010: begin inBHT_pos = 1; end
			8'b00000100: begin inBHT_pos = 2; end
			8'b00001000: begin inBHT_pos = 3; end
			8'b00010000: begin inBHT_pos = 4; end
			8'b00100000: begin inBHT_pos = 5; end
			8'b01000000: begin inBHT_pos = 6; end
			8'b10000000: begin inBHT_pos = 7; end
			default: begin inBHT_pos = 0; isInBHT = 0; end
		endcase
		for(h=0; h<8; h=h+1) begin
			if(BHT_pc_4_index[h] == 0) available_pos = h;
		end
	end

	always @(BHT_lru_cnt) begin
		max_lru_cnt = 12'b0;
		for(k=0; k<8; k=k+1) begin
			if(BHT_lru_cnt[k] >= max_lru_cnt) begin
				max_lru_cnt = BHT_lru_cnt[k];
				tmp_eviction_pos = k;
			end
		end
		eviction_pos = tmp_eviction_pos;
	end

	assign update_pos = isInBHT? inBHT_pos :(isfull? eviction_pos : available_pos);
	//assign update_pos = isfull? eviction_pos : (isInBHT ? inBHT_pos : available_pos);

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			for(i=0; i<8; i=i+1) begin
			BHT_pc_4_index[i] = 32'b0;
			BHT_jp_brh_addr[i] = 32'b0;
			BHT_binary_predict[i] = 2'b01;
			BHT_lru_cnt[i] = 12'b0;
			end
		end
		else if (en) begin
			for(j=0; j<8; j=j+1) begin
				BHT_lru_cnt[j] = (BHT_pc_4_index[j] == 0) ? BHT_lru_cnt[j]
								:BHT_lru_cnt[j] + 1;
			end
			if (update_en) begin
				BHT_pc_4_index[update_pos] = pc_4_id_ex;
				BHT_jp_brh_addr[update_pos] = branch_jump_addr;
				BHT_lru_cnt[update_pos] = 0;
				if (binary_predict_id_ex == 2'b01) begin
					BHT_binary_predict[update_pos] = binary_predict_id_ex + 1;
				end
				else if(jp_success) begin
					BHT_binary_predict[update_pos] = (binary_predict_id_ex == 2'b11) ? 2'b11 
													: (binary_predict_id_ex + 1);
				end
				else begin
					BHT_binary_predict[update_pos] = (binary_predict_id_ex == 2'b01) ? 2'b01
													 :(binary_predict_id_ex - 1);
				end
			end
		end
	end
endmodule