// `resetall
`timescale 1ns / 1ps
// `default_nettype none

module processor (
  input         clk_i,
  input         rst_i,
  output [31:0] mem_addr_o,
  output        mem_rstrb_o,
  input  [31:0] mem_rdata_i,
  output [3:0]  mem_wmask_o,
  output [31:0] mem_wdata_o
);

// define register file
reg [31:0] rf_ra[0:31];  // ra: reg array

// genvar i;
// generate
//   for (i = 0; i < 32; i = i + 1) begin
//     always @(posedge clk_i) begin
//       if (rst_i) begin
//         rf_ra[i] <= 32'b0;
//       end
//       else if ((state_r == WB) & (rd_id_w == i) & (i != 0)) begin
//         rf_ra[i] <= wb_data_w;
//       end
//     end
//   end
// endgenerate

integer i;
initial begin
  for (i = 0; i < 32; i = i + 1) begin
    rf_ra[i] = 0;
  end
end

always @(posedge clk_i) begin
  if (wb_en_w) begin
    rf_ra[rd_id_w] <= wb_data_w;
  end
end


// integer i;
// always @(posedge clk_i) begin
//   if (rst_i) begin
//     for (i = 0; i < 32; ++i) begin
//       rf_ra[i] <= 32'b0;
//     end
//   end
//   else if (wb_en_w) begin
//     rf_ra[rd_id_w] <= wb_data_w;
//   end
// end

// ----------------------------------------------------------------------------
// CPU State Machine
// ----------------------------------------------------------------------------
// define state parameter
localparam IF  = 0;
localparam DEC = 1;
localparam EXE = 2;
localparam MEM = 3;
localparam WB  = 4;

reg [2:0] state_r;
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IF;
    inst_r <= 32'b0;
  end
  else begin
    case (state_r)
      IF: begin
        state_r <= DEC;
        inst_r <= mem_rdata_i;
      end
      DEC: begin
        state_r <= EXE;
      end
      EXE: begin
        if (is_load_w | is_store_w) begin
          state_r <= MEM;
        end
        else begin
          state_r <= WB;
        end
      end
      MEM: begin
        state_r <= WB;
      end
      WB: begin
        state_r <= IF;
      end
      default: begin
        state_r <= IF;
      end 
    endcase
  end
end

// ----------------------------------------------------------------------------
// Instruction Decoder
// ----------------------------------------------------------------------------
reg [31:0] inst_r;

wire is_alu_reg_w = inst_r[6:0] == 7'b011_0011;   // rd <- rs1 OP rs2
wire is_alu_imm_w = inst_r[6:0] == 7'b001_0011;   // rd <- rs1 OP Iimm
wire is_branch_w  = inst_r[6:0] == 7'b110_0011;   // if(rs1 OP rs2) PC <- PC + Bimm
wire is_jalr_w    = inst_r[6:0] == 7'b110_0111;   // rd <- PC + 4; PC <- rs1 + Iimm
wire is_jal_w     = inst_r[6:0] == 7'b110_1111;   // rd <- PC + 4; PC <- PC + Jimm
wire is_auipc_w   = inst_r[6:0] == 7'b001_0111;   // rd <- PC + Uimm
wire is_lui_w     = inst_r[6:0] == 7'b011_0111;   // rd <- Uimm
wire is_load_w    = inst_r[6:0] == 7'b000_0011;   // rd <- MEM[rs1 + Iimm]
wire is_store_w   = inst_r[6:0] == 7'b010_0011;   // MEM[rs1 + Simm] <- rs2
wire is_system_w  = inst_r[6:0] == 7'b111_0011;   // special

wire [4:0] rs1_id_w = inst_r[19:15];
wire [4:0] rs2_id_w = inst_r[24:20];
wire [4:0] rd_id_w  = inst_r[11:7];

reg [31:0] rs1_r;
reg [31:0] rs2_r;
always @(posedge clk_i) begin
  if (rst_i) begin
    rs1_r <= 32'b0;
    rs2_r <= 32'b0;
  end
  else if (state_r == DEC) begin
    rs1_r <= rf_ra[rs1_id_w];
    rs2_r <= rf_ra[rs2_id_w];
  end

end

wire [2:0] funct3_w = inst_r[14:12];
wire [6:0] funct7_w = inst_r[31:25];

wire [31:0] Iimm_w = {{21{inst_r[31]}}, inst_r[30:20]};
wire [31:0] Uimm_w = {    inst_r[31],   inst_r[30:12], {12{1'b0}}};
wire [31:0] Simm_w = {{21{inst_r[31]}}, inst_r[30:25], inst_r[11:7]};
wire [31:0] Bimm_w = {{20{inst_r[31]}}, inst_r[7], inst_r[30:25], inst_r[11:8], 1'b0};
wire [31:0] Jimm_w = {{12{inst_r[31]}}, inst_r[19:12], inst_r[20], inst_r[30:21], 1'b0};

// debug only
always @(posedge clk_i) begin
  if (state_r == DEC) begin
    case (1'b1)
      is_alu_reg_w: $display("[%t ps]: rd[%d] <- rs1[%d] OP rs2[%d]", $realtime, rd_id_w, rs1_id_w, rs2_id_w);
      is_alu_imm_w: $display("[%t ps]: rd[%d] <- rs1[%d] OP Iimm(%h)", $realtime, rd_id_w, rs1_id_w, Iimm_w);
      is_branch_w:  $display("[%t ps]: if(rs1[%d] OP rs2[%d]) PC <- PC(%d) + Bimm(%h)", $realtime, rs1_id_w, rs2_id_w, pc_r, Bimm_w);
      is_jalr_w:    $display("[%t ps]: rd[%d] <- PC(%d) + 4; PC <- rs1[%d] + Iimm(%h)", $realtime, rd_id_w, pc_r, rs1_id_w, Iimm_w);
      is_jal_w:     $display("[%t ps]: rd[%d] <- PC(%d) + 4; PC <- PC + Jimm(%h)", $realtime, rd_id_w, pc_r, Jimm_w);
      is_auipc_w:   $display("[%t ps]: rd[%d] <- PC(%d) + Uimm(%h)", $realtime, rd_id_w, pc_r, Uimm_w);
      is_lui_w:     $display("[%t ps]: rd[%d] <- Uimm(%h)", $realtime, rd_id_w, Uimm_w);
      is_load_w:    $display("[%t ps]: rd[%d] <- MEM[rs1[%d] + Iimm(%h)]", $realtime, rd_id_w, rs1_id_w, Iimm_w);
      is_store_w:   $display("[%t ps]: MEM[rs1[%d] + Simm(%h)] <- rs2", $realtime, rs1_id_w, Simm_w);
      is_system_w:  $display("[%t ps]: special", $realtime);
      default:      $display("[%t ps]: wrong instruction(%h)", $realtime, inst_r);
    endcase
  end
end

// ----------------------------------------------------------------------------
// ALU
// ----------------------------------------------------------------------------
// two types:
//     - Rtype: rd <- rs1 OP rs2 (is_alu_reg_w)
//     - Itype: rd <- rs1 OP Iimm (is_alu_imm_w)
wire [31:0] alu_in1_w = (
  (is_jal_w | is_jalr_w | is_auipc_w) ? pc_r : 
  (is_lui_w) ? 32'h0 : 
  rs1_r
);
wire [31:0] alu_in2_w = (
  (is_alu_reg_w | is_branch_w) ? rs2_r : 
  (is_auipc_w | is_lui_w) ? Uimm_w :
  (is_jal_w | is_jalr_w) ? 32'h4 :
  Iimm_w
);

wire [4:0] sh_amt_w = is_alu_reg_w ? rs2_r[4:0] : Iimm_w[4:0];

wire is_alu_calc_sub_w = (
  (funct3_w == 3'b000 & funct7_w[5] & inst_r[5]) |
  (funct3_w == 3'b010) |
  (funct3_w == 3'b011) |
  (is_branch_w)
);
wire [32:0] add2_w = is_alu_calc_sub_w ? {1'b1, ~alu_in2_w} : {1'b0, alu_in2_w};
wire carry_w = is_alu_calc_sub_w ? 1'b1 : 1'b0;

wire [32:0] alu_addsub_w = {1'b0, alu_in1_w} + add2_w + carry_w;
wire [31:0] alu_ltu_w = {31'b0, alu_addsub_w[32]};
wire [31:0] alu_lt_w = (alu_in1_w[31] ^ alu_in2_w[31]) ? {31'b0, alu_in1_w[31]} : alu_ltu_w;
wire [31:0] alu_xor_w = alu_in1_w ^ alu_in2_w;
wire [31:0] alu_or_w = alu_in1_w | alu_in2_w;
wire [31:0] alu_and_w = alu_in1_w & alu_in2_w;

// wire [31:0] signed_shift_right_w = $signed(alu_in1_w) >>> sh_amt_w; // SRA
// wire [31:0] unsigned_shift_right_w = alu_in1_w >> sh_amt_w;         // SRL
wire [32:0] alu_sra_w = $signed({(funct7_w[5] & alu_in1_w[31]), alu_in1_w}) >>> sh_amt_w;

reg [31:0] alu_out_w;
always @(*) begin
  case (funct3_w)
    // ADD or SUB
    // 3'b000: alu_out_w = (funct7_w[5] & inst_r[5]) ? (alu_in1_w - alu_in2_w) : (alu_in1_w + alu_in2_w);
    3'b000: alu_out_w = alu_addsub_w[31:0];
    // left shift
    3'b001: alu_out_w = (alu_in1_w << sh_amt_w);
    // signed comparison (<)
    // 3'b010: alu_out_w = ($signed(alu_in1_w) < $signed(alu_in2_w));
    3'b010: alu_out_w = alu_lt_w;
    // unsigned comparison (<)
    // 3'b011: alu_out_w = (alu_in1_w < alu_in2_w);
    3'b011: alu_out_w = alu_ltu_w;
    // XOR
    3'b100: alu_out_w = alu_xor_w;
    // logical/arithmetic right shift
    3'b101: alu_out_w = alu_sra_w[31:0];
    // OR
    3'b110: alu_out_w = alu_or_w;
    // AND
    3'b111: alu_out_w = alu_and_w;
  endcase
end

// ----------------------------------------------------------------------------
// Branch
// ----------------------------------------------------------------------------
wire is_branch_ne_w = |alu_xor_w;
wire is_branch_eq_w = ~is_branch_ne_w;
wire is_branch_lt_w = alu_lt_w;
wire is_branch_ge_w = ~alu_lt_w;
wire is_branch_ltu_w = alu_ltu_w;
wire is_branch_geu_w = ~alu_ltu_w;

reg is_branch_taken_w;
always @(*) begin
  case (funct3_w)
    // BEQ rs1, rs2, imm: if(rs1 == rs2) PC <- PC + Bimm
    // 3'b000: is_branch_taken_w = (rs1_r == rs2_r);
    3'b000: is_branch_taken_w = is_branch_eq_w;
    // BNE rs1, rs2, imm: if(rs1 != rs2) PC <- PC + Bimm
    // 3'b001: is_branch_taken_w = (rs1_r != rs2_r);
    3'b001: is_branch_taken_w = is_branch_ne_w;
    // BLT rs1, rs2, imm: if(rs1 < rs2) PC <- PC + Bimm (signed comparison)
    // 3'b100: is_branch_taken_w = ($signed(rs1_r) < $signed(rs2_r));
    3'b100: is_branch_taken_w = is_branch_lt_w;
    // BGE rs1, rs2, imm: if(rs1 >= rs2) PC <- PC + Bimm (signed comparison)
    // 3'b101: is_branch_taken_w = ($signed(rs1_r) >= $signed(rs2_r));
    3'b101: is_branch_taken_w = is_branch_ge_w;
    // BLTU rs1, rs2, imm: if(rs1 < rs2) PC <- PC + Bimm (unsigned comparison)
    // 3'b110: is_branch_taken_w = (rs1_r < rs2_r);
    3'b110: is_branch_taken_w = is_branch_ltu_w;
    // BGEU rs1, rs2, imm: if(rs1 >= rs2) PC <- PC + Bimm (unsigned comparison)
    // 3'b111: is_branch_taken_w = (rs1_r >= rs2_r);
    3'b111: is_branch_taken_w = is_branch_geu_w;
    // otherwise branch is not taken, `default` statement is necessary to avoid latch
    default: is_branch_taken_w = 1'b0;
  endcase
end

// wire [31:0] pc_plus_Bimm = pc_r + Bimm_w;

// ----------------------------------------------------------------------------
// Jump
// ----------------------------------------------------------------------------
// JAL rd, imm: rd <- PC + 4; PC <- PC + Jimm
// JALR rd, rs1, imm: rd <- PC + 4; PC <- rs1 + Iimm

// wire [31:0] pc_plus_4 = pc_r + 4;
// wire [31:0] pc_plus_4 = alu_out_w;
// wire [31:0] pc_plus_Jimm = pc_r + Jimm_w;
// wire [31:0] pc_plus_Uimm = pc_r + Uimm_w;
// wire [31:0] rs1_plus_Iimm = rs1_r + Iimm_w;

wire [31:0] next_pc_add1_w = is_jalr_w ? rs1_r : pc_r;
wire [31:0] next_pc_add2_w = (
  (is_branch_w & is_branch_taken_w) ? Bimm_w :
  (is_jal_w) ? Jimm_w :
  (is_jalr_w) ? Iimm_w :
  32'h4
);

// ----------------------------------------------------------------------------
// Generate Next PC
// ----------------------------------------------------------------------------
// wire [31:0] next_pc_w = (
//   (is_branch_w & is_branch_taken_w) ? pc_plus_Bimm :
//   (is_jal_w) ? pc_plus_Jimm :
//   (is_jalr_w) ? rs1_plus_Iimm :
//   pc_plus_4
// );
wire [31:0] next_pc_w = next_pc_add1_w + next_pc_add2_w;

reg [31:0] pc_r;
always @(posedge clk_i) begin
  if (rst_i) begin
    pc_r <= 32'b0;
  end
  else if (state_r == WB) begin
    pc_r <= next_pc_w;
  end
end

// ----------------------------------------------------------------------------
// Load
// ----------------------------------------------------------------------------
wire [31:0] load_ori_addr_w = rs1_r + Iimm_w;
wire [31:0] load_word_addr_w = {load_ori_addr_w[31:2], 2'b0};

reg [31:0] load_ori_data_r;
always @(posedge clk_i) begin
  if (rst_i) begin
    load_ori_data_r <= 32'b0;
  end
  else if (state_r == MEM & is_load_w) begin
    load_ori_data_r <= mem_rdata_i;
  end
end

// convert mem_load_word to wb_load_word
wire is_load_store_byte_w = funct3_w[1:0] == 2'b00;
wire is_load_store_half_w = funct3_w[1:0] == 2'b01;
wire is_load_unsigned_w = funct3_w[2] == 1'b1;

wire [15:0] load_half_w = (
  load_ori_addr_w[1] ? load_ori_data_r[31:16] :
  load_ori_data_r[15:0]
);

wire [7:0] load_byte_w = (
  load_ori_addr_w[0] ? load_half_w[15:8] :
  load_half_w[7:0]
);

wire load_sign_w = (
  (~is_load_unsigned_w) & 
  (is_load_store_half_w ? load_half_w[15] : load_byte_w[7])
); 

wire [31:0] load_data_w = (
  is_load_store_half_w ? {{16{load_sign_w}}, load_half_w} :
  is_load_store_byte_w ? {{24{load_sign_w}}, load_byte_w} :
  load_ori_data_r
);

// ----------------------------------------------------------------------------
// Store
// ----------------------------------------------------------------------------
wire [31:0] store_ori_addr_w = rs1_r + Simm_w;
wire [31:0] store_word_addr_w = {store_ori_addr_w[31:2], 2'b0};

wire [31:0] store_byte_w = {4{rs2_r[7:0]}};
wire [31:0] store_half_w = {2{rs2_r[15:0]}};

wire [31:0] store_data_w = (
  is_load_store_byte_w ? store_byte_w :
  is_load_store_half_w ? store_half_w :
  rs2_r
);

wire [3:0] store_mask_w = (
  is_load_store_byte_w ? (
    store_ori_addr_w[0] ? (
      store_ori_addr_w[1] ? 4'b1000 : 4'b0010
    ) : (
      store_ori_addr_w[1] ? 4'b0100 : 4'b0001
    )
  ) :
  is_load_store_half_w ? (
    store_ori_addr_w[1] ? 4'b1100 : 4'b0011
  ) :
  4'b1111
);

// ----------------------------------------------------------------------------
// Write Back to rd
// ----------------------------------------------------------------------------
wire wb_en_w = (
  (state_r == WB) &
  (rd_id_w != 0) &
  (   
    is_alu_reg_w |
    is_alu_imm_w | 
    is_jal_w |
    is_jalr_w |
    is_auipc_w |
    is_lui_w |
    is_load_w
  )
);

wire [31:0] wb_data_w = is_load_w ? load_data_w : alu_out_w;

// ----------------------------------------------------------------------------
// Output Interface
// ----------------------------------------------------------------------------
assign mem_addr_o = (
  (state_r == IF) ? pc_r :
  (state_r == MEM) ? (is_load_w ? load_word_addr_w : store_word_addr_w) :
  pc_r
);

assign mem_rstrb_o = (
  (state_r == IF) |
  (state_r == MEM & is_load_w)
);

assign mem_wmask_o = (
  ((state_r == MEM) & (is_store_w)) ? store_mask_w :
  4'b0000
);

assign mem_wdata_o = store_data_w;

endmodule
