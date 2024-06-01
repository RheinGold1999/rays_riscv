`include "define.v"

`resetall
`timescale 1ns / 1ps
// `default_nettype none

module processor #(
  parameter [31:0] PC_BASE_ADDR = `CPU_PC_BASE_ADDR,
  parameter [31:0] SP_BASE_ADDR = `CPU_SP_BASE_ADDR
)(
  input         clk,
  input         rst,
  output [31:0] mem_addr_o,
  output        mem_rstrb_o,
  input  [31:0] mem_rdata_i,
  output [3:0]  mem_wmask_o,
  output [31:0] mem_wdata_o
);

// define register file
reg [31:0] regfile_ra[0:31];  // ra: reg array

// ----------------------------------------------------------------------------
// with reset the regfile is synthesized to SB_DFFESR and SB_LUT4
// ----------------------------------------------------------------------------
// genvar i;
// generate
//   for (i = 0; i < 31; i = i + 1) begin
//     always @(posedge clk) begin
//       if (rst) begin
//         regfile_ra[i] <= 32'b0;
//       end else if ((wb_en) & (rd_id == (i))) begin
//         regfile_ra[i] <= wb_data;
//       end
//     end
//   end
// endgenerate

// ----------------------------------------------------------------------------
// with reset the regfile is synthesized to SB_DFFESR and SB_LUT4
// ----------------------------------------------------------------------------
// integer i;
// always @(posedge clk) begin
//   if (rst) begin
//     for (i = 0; i < 31; ++i) begin
//       regfile_ra[i] <= 32'b0;
//     end
//   end else if (wb_en) begin
//     regfile_ra[rd_id] <= wb_data;
//   end
// end

// ----------------------------------------------------------------------------
// without reset the regfile is synthesized to SB_RAM40_4K
// ----------------------------------------------------------------------------
integer i;
initial begin
  for (i = 0; i < 32; i = i + 1) begin
    regfile_ra[i] = 0;
  end
  regfile_ra[`sp] = SP_BASE_ADDR;
end

always @(posedge clk) begin
  if (wb_en) begin
    regfile_ra[rd_id] <= wb_data;
  end
end

// ----------------------------------------------------------------------------
// CPU State Machine
// ----------------------------------------------------------------------------
// define state parameter
localparam IF  = 0;
localparam ID  = 1;
localparam EXE = 2;
localparam MEM = 3;
localparam WB  = 4;

wire state_IF = state_r == IF;
wire state_ID = state_r == ID;
wire state_EXE = state_r == EXE;
wire state_MEM = state_r == MEM;
wire state_WB = state_r == WB;

reg [2:0] state_r;
always @(posedge clk) begin
  if (rst) begin
    state_r <= WB;
  end else begin
    case (state_r)
      IF: begin
        state_r <= ID;
      end
      ID: begin
        state_r <= EXE;
      end
      EXE: begin
        if (is_load | is_store) begin
          state_r <= MEM;
        end else begin
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
        state_r <= WB;
      end 
    endcase
  end
end

// ----------------------------------------------------------------------------
// Instruction Decoder
// ----------------------------------------------------------------------------
reg [31:0] inst_r;
always @(posedge clk) begin
  if (rst) begin
    inst_r <= 32'b0;
  end else if (state_IF) begin
    inst_r <= mem_rdata_i;
  end
end

wire is_alu_reg = inst_r[6:0] == 7'b011_0011;   // rd <- rs1 OP rs2
wire is_alu_imm = inst_r[6:0] == 7'b001_0011;   // rd <- rs1 OP Iimm
wire is_branch  = inst_r[6:0] == 7'b110_0011;   // if(rs1 OP rs2) PC <- PC + Bimm
wire is_jalr    = inst_r[6:0] == 7'b110_0111;   // rd <- PC + 4; PC <- rs1 + Iimm
wire is_jal     = inst_r[6:0] == 7'b110_1111;   // rd <- PC + 4; PC <- PC + Jimm
wire is_auipc   = inst_r[6:0] == 7'b001_0111;   // rd <- PC + Uimm
wire is_lui     = inst_r[6:0] == 7'b011_0111;   // rd <- Uimm
wire is_load    = inst_r[6:0] == 7'b000_0011;   // rd <- MEM[rs1 + Iimm]
wire is_store   = inst_r[6:0] == 7'b010_0011;   // MEM[rs1 + Simm] <- rs2
wire is_system  = inst_r[6:0] == 7'b111_0011;   // special

wire [4:0] rs1_id = inst_r[19:15];
wire [4:0] rs2_id = inst_r[24:20];
wire [4:0] rd_id  = inst_r[11:7];

reg [31:0] rs1_r;
reg [31:0] rs2_r;
always @(posedge clk) begin
  if (rst) begin
    rs1_r <= 32'b0;
    rs2_r <= 32'b0;
  end else if (state_ID) begin
    rs1_r <= regfile_ra[rs1_id];
    rs2_r <= regfile_ra[rs2_id];
  end
end

wire [2:0] funct3 = inst_r[14:12];
wire [6:0] funct7 = inst_r[31:25];

wire [31:0] Iimm = {{21{inst_r[31]}}, inst_r[30:20]};
wire [31:0] Uimm = {    inst_r[31],   inst_r[30:12], {12{1'b0}}};
wire [31:0] Simm = {{21{inst_r[31]}}, inst_r[30:25], inst_r[11:7]};
wire [31:0] Bimm = {{20{inst_r[31]}}, inst_r[7], inst_r[30:25], inst_r[11:8], 1'b0};
wire [31:0] Jimm = {{12{inst_r[31]}}, inst_r[19:12], inst_r[20], inst_r[30:21], 1'b0};

// ----------------------------------------------------------------------------
// Instruction Monitor (debug only)
// ----------------------------------------------------------------------------
always @(posedge clk) begin
  if (state_EXE) begin
    case (1'b1)
      is_alu_reg: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- rs1[%d] OP rs2[%d]", $realtime, rd_id, rs1_id, rs2_id);
        case (funct3)
          3'b000: begin
            if (funct7[5]) begin
              $display("[%0t ps][CPU ]: SUB rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
            end else begin
              $display("[%0t ps][CPU ]: ADD rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
            end
          end
          3'b001: $display("[%0t ps][CPU ]: SLL rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
          3'b010: $display("[%0t ps][CPU ]: SLT rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
          3'b011: $display("[%0t ps][CPU ]: SLTU rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
          3'b100: $display("[%0t ps][CPU ]: XOR rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
          3'b101: begin
            if (funct7[5]) begin
              $display("[%0t ps][CPU ]: SRA rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
            end else begin
              $display("[%0t ps][CPU ]: SRL rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
            end
          end
          3'b110: $display("[%0t ps][CPU ]: OR rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
          3'b111: $display("[%0t ps][CPU ]: AND rd[%d], rs1[%d](%h), rs2[%d](%h)", $realtime, rd_id, rs1_id, rs1_r, rs2_id, rs2_r);
        endcase
      end
      is_alu_imm: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- rs1[%d] OP Iimm(%0d)", $realtime, rd_id, rs1_id, Iimm);
        case (funct3)
          3'b000: $display("[%0t ps][CPU ]: ADDI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b001: $display("[%0t ps][CPU ]: SLLI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b010: $display("[%0t ps][CPU ]: SLTI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b011: $display("[%0t ps][CPU ]: SLTUI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b100: $display("[%0t ps][CPU ]: XORI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b101: begin
            if (funct7[5]) begin
              $display("[%0t ps][CPU ]: SRAI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
            end else begin
              $display("[%0t ps][CPU ]: SRLI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
            end
          end
          3'b110: $display("[%0t ps][CPU ]: ORI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b111: $display("[%0t ps][CPU ]: ANDI rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
        endcase
      end
      is_branch: begin
        // $display("[%0t ps][CPU ]: if(rs1[%d] OP rs2[%d]) PC <- PC(%d) + Bimm(%0d)", $realtime, rs1_id, rs2_id, pc_r, Bimm);
        case (funct3)
          3'b000: $display("[%0t ps][CPU ]: BEQ rs1[%d](%h), rs2[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
          3'b001: $display("[%0t ps][CPU ]: BNE rs1[%d](%h), rs2[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
          3'b100: $display("[%0t ps][CPU ]: BLT rs1[%d](%h), rs2[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
          3'b101: $display("[%0t ps][CPU ]: BGE rs1[%d](%h), rs2[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
          3'b110: $display("[%0t ps][CPU ]: BLTU rs1[%d](%h), rs2[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
          3'b111: $display("[%0t ps][CPU ]: BGEU rs1[%d](%h), rs2[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
          default: $display("[%0t ps][CPU ]: Wrong Branch, check funct3: x[%d](%h), x[%d](%h), Bimm(%0d)", $realtime, rs1_id, rs1_r, rs2_id, rs2_r, $signed(Bimm));
        endcase
      end
      is_jalr: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- PC(%d) + 4; PC <- rs1[%d] + Iimm(%0d)", $realtime, rd_id, pc_r, rs1_id, $signed(Iimm));
        $display("[%0t ps][CPU ]: JALR rd[%d](%h), rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, (pc_r + 4), rs1_id, rs1_r, $signed(Iimm));
      end
      is_jal: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- PC(%d) + 4; PC <- PC + Jimm(%0d)", $realtime, rd_id, pc_r, $signed(Jimm));
        $display("[%0t ps][CPU ]: JAL rd[%d](%h), Jimm(%0d)", $realtime, rd_id, (pc_r + 4), $signed(Jimm));
      end
      is_auipc: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- PC(%d) + Uimm(%0d)", $realtime, rd_id, pc_r, $signed(Uimm));
        $display("[%0t ps][CPU ]: AUIPC rd[%d], Uimm(%0d)", $realtime, rd_id, $signed(Uimm));
      end
      is_lui: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- Uimm(%0d)", $realtime, rd_id, $signed(Uimm));
        $display("[%0t ps][CPU ]: LUI rd[%d], Uimm(%0d)", $realtime, rd_id, $signed(Uimm));
      end
      is_load: begin
        // $display("[%0t ps][CPU ]: rd[%d] <- MEM[rs1[%d] + Iimm(%0d)]", $realtime, rd_id, rs1_id, $signed(Iimm));
        case (funct3)
          3'b000: $display("[%0t ps][CPU ]: LB rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b001: $display("[%0t ps][CPU ]: LH rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b010: $display("[%0t ps][CPU ]: LW rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b100: $display("[%0t ps][CPU ]: LBU rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          3'b101: $display("[%0t ps][CPU ]: LHU rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
          default: $display("[%0t ps][CPU ]: Wrong Load, check funct3: rd[%d], rs1[%d](%h), Iimm(%0d)", $realtime, rd_id, rs1_id, rs1_r, $signed(Iimm));
        endcase
      end
      is_store: begin
        // $display("[%0t ps][CPU ]: MEM[rs1[%d] + Simm(%0d)] <- rs2[%d]", $realtime, rs1_id, Simm, rs2_id);
        case (funct3)
          3'b000: $display("[%0t ps][CPU ]: SB rs2[%d](%h), rs1[%d](%h), Simm(%0d)", $realtime, rs2_id, rs2_r, rs1_id, rs1_r, $signed(Simm));
          3'b001: $display("[%0t ps][CPU ]: SH rs2[%d](%h), rs1[%d](%h), Simm(%0d)", $realtime, rs2_id, rs2_r, rs1_id, rs1_r, $signed(Simm));
          3'b010: $display("[%0t ps][CPU ]: SW rs2[%d](%h), rs1[%d](%h), Simm(%0d)", $realtime, rs2_id, rs2_r, rs1_id, rs1_r, $signed(Simm));
          default: $display("[%0t ps][CPU ]: Wrong Store, check funct3: rs2[%d](%h), rs1[%d](%h), Iimm(%0d)", $realtime, rs2_id, rs2_r, rs1_id, rs1_r, $signed(Simm));
        endcase
      end
      is_system: begin
        case (inst_r[20])
          1'b0: $display("[%0t ps][CPU ]: ECALL(%h)", $realtime, inst_r);
          1'b1: begin
            $display("[%0t ps][CPU ]: EBREAK(%h)", $realtime, inst_r);
            // $finish();
          end
          default: $display("[%0t ps][CPU ]: System Instruction(%h)", $realtime, inst_r);
        endcase
      end
      default: $display("[%0t ps][CPU ]: other instruction(%h)", $realtime, inst_r);
    endcase
  end
end

// ----------------------------------------------------------------------------
// Performance
// ----------------------------------------------------------------------------
reg [63:0] cycle_r;
always @(posedge clk) begin
  if (rst) begin
    cycle_r <= 64'b0;
  end else begin
    cycle_r <= cycle_r + 1;
  end
end

reg [63:0] instret_r;
always @(posedge clk) begin
  if (rst) begin
    instret_r <= 64'b0;
  end else if (state_IF) begin
    instret_r <= instret_r + 1;
  end
end

wire is_csrrs = is_system & (funct3 == 3'b010);

wire [31:0] csrrs_data = (
  (inst_r[21]) ? (
    inst_r[27] ? instret_r[63:32] : instret_r[31:0]
  ) : (
    inst_r[27] ? cycle_r[63:32] : cycle_r[31:0]
  )
);

// ----------------------------------------------------------------------------
// ALU
// ----------------------------------------------------------------------------
// two types:
//     - Rtype: rd <- rs1 OP rs2 (is_alu_reg)
//     - Itype: rd <- rs1 OP Iimm (is_alu_imm)
wire [31:0] alu_in1 = (
  (is_jal | is_jalr | is_auipc) ? pc_r : 
  (is_lui) ? 32'h0 : 
  rs1_r
);
wire [31:0] alu_in2 = (
  (is_alu_reg | is_branch) ? rs2_r : 
  (is_auipc | is_lui) ? Uimm :
  (is_store) ? Simm :
  (is_jal | is_jalr) ? 32'h4 :
  Iimm
);

wire [4:0] sh_amt = is_alu_reg ? rs2_r[4:0] : Iimm[4:0];

wire [31:0] alu_add = alu_in1 + alu_in2;
wire [32:0] alu_sub = {1'b0, alu_in1} + {1'b1, ~alu_in2} + 33'b1;
wire [31:0] alu_ltu = {31'b0, alu_sub[32]};
wire [31:0] alu_lt = (alu_in1[31] ^ alu_in2[31]) ? {31'b0, alu_in1[31]} : alu_ltu;
wire [31:0] alu_xor = alu_in1 ^ alu_in2;
wire [31:0] alu_or = alu_in1 | alu_in2;
wire [31:0] alu_and = alu_in1 & alu_in2;

// wire [31:0] signed_shift_right = $signed(alu_in1) >>> sh_amt; // SRA
// wire [31:0] unsigned_shift_right = alu_in1 >> sh_amt;         // SRL
wire [32:0] alu_sra = $signed({(funct7[5] & alu_in1[31]), alu_in1}) >>> sh_amt;

reg [31:0] alu_out;
always @(*) begin
  case (funct3)
    // ADD or SUB
    // 3'b000: alu_out = (funct7[5] & inst_r[5]) ? (alu_in1 - alu_in2) : (alu_in1 + alu_in2);
    3'b000: alu_out = (funct7[5] & inst_r[5]) ? alu_sub[31:0] : alu_add;
    // left shift
    3'b001: alu_out = (alu_in1 << sh_amt);
    // signed comparison (<)
    // 3'b010: alu_out = ($signed(alu_in1) < $signed(alu_in2));
    3'b010: alu_out = alu_lt;
    // unsigned comparison (<)
    // 3'b011: alu_out = (alu_in1 < alu_in2);
    3'b011: alu_out = alu_ltu;
    // XOR
    3'b100: alu_out = alu_xor;
    // logical/arithmetic right shift
    3'b101: alu_out = alu_sra[31:0];
    // OR
    3'b110: alu_out = alu_or;
    // AND
    3'b111: alu_out = alu_and;
  endcase
end

reg [31:0] alu_out_r;
always @(posedge clk) begin
  if (rst) begin
    alu_out_r <= 32'b0;
  end else if (state_EXE) begin
    if (is_alu_reg | is_alu_imm) begin
      alu_out_r <= alu_out;
    end else begin
      alu_out_r <= alu_add;
    end
  end
end

// ----------------------------------------------------------------------------
// Branch
// ----------------------------------------------------------------------------
wire is_branch_ne = (|alu_xor);
wire is_branch_eq = (~is_branch_ne);
wire is_branch_lt = alu_lt;
wire is_branch_ge = (~alu_lt);
wire is_branch_ltu = alu_ltu;
wire is_branch_geu = (~alu_ltu);

reg is_branch_taken;
always @(*) begin
  case (funct3)
    // BEQ rs1, rs2, imm: if(rs1 == rs2) PC <- PC + Bimm
    // 3'b000: is_branch_taken = (rs1_r == rs2_r);
    3'b000: is_branch_taken = is_branch_eq;
    // BNE rs1, rs2, imm: if(rs1 != rs2) PC <- PC + Bimm
    // 3'b001: is_branch_taken = (rs1_r != rs2_r);
    3'b001: is_branch_taken = is_branch_ne;
    // BLT rs1, rs2, imm: if(rs1 < rs2) PC <- PC + Bimm (signed comparison)
    // 3'b100: is_branch_taken = ($signed(rs1_r) < $signed(rs2_r));
    3'b100: is_branch_taken = is_branch_lt;
    // BGE rs1, rs2, imm: if(rs1 >= rs2) PC <- PC + Bimm (signed comparison)
    // 3'b101: is_branch_taken = ($signed(rs1_r) >= $signed(rs2_r));
    3'b101: is_branch_taken = is_branch_ge;
    // BLTU rs1, rs2, imm: if(rs1 < rs2) PC <- PC + Bimm (unsigned comparison)
    // 3'b110: is_branch_taken = (rs1_r < rs2_r);
    3'b110: is_branch_taken = is_branch_ltu;
    // BGEU rs1, rs2, imm: if(rs1 >= rs2) PC <- PC + Bimm (unsigned comparison)
    // 3'b111: is_branch_taken = (rs1_r >= rs2_r);
    3'b111: is_branch_taken = is_branch_geu;
    // otherwise branch is not taken, `default` statement is necessary to avoid latch
    default: is_branch_taken = 1'b0;
  endcase
end

// wire [31:0] pc_plus_Bimm = pc_r + Bimm;

// ----------------------------------------------------------------------------
// Jump
// ----------------------------------------------------------------------------
// JAL rd, imm: rd <- PC + 4; PC <- PC + Jimm
// JALR rd, rs1, imm: rd <- PC + 4; PC <- rs1 + Iimm

wire [31:0] next_pc_add1 = is_jalr ? rs1_r : pc_r;
wire [31:0] next_pc_add2 = (
  (is_branch & is_branch_taken) ? Bimm :
  (is_jal) ? Jimm :
  (is_jalr) ? Iimm :
  32'h4
);

// ----------------------------------------------------------------------------
// Generate Next PC
// ----------------------------------------------------------------------------
wire [31:0] next_pc = next_pc_add1 + next_pc_add2;

reg [31:0] pc_r;
always @(posedge clk) begin
  if (rst) begin
    pc_r <= PC_BASE_ADDR;
  end else if (state_EXE) begin
    pc_r <= next_pc;
  end
end

// ----------------------------------------------------------------------------
// Load
// ----------------------------------------------------------------------------
wire [31:0] load_ori_addr = alu_add;
wire [31:0] load_word_addr = {load_ori_addr[31:2], 2'b0};

reg [31:0] load_ori_data_r;
always @(posedge clk) begin
  if (rst) begin
    load_ori_data_r <= 32'b0;
  end else if (state_MEM & is_load) begin
    load_ori_data_r <= mem_rdata_i;
  end
end

// convert mem_load_word to wb_load_word
wire is_load_store_byte = funct3[1:0] == 2'b00;
wire is_load_store_half = funct3[1:0] == 2'b01;
wire is_load_unsigned = funct3[2] == 1'b1;

wire [15:0] load_half = (
  load_ori_addr[1] ? load_ori_data_r[31:16] :
  load_ori_data_r[15:0]
);

wire [7:0] load_byte = (
  load_ori_addr[0] ? load_half[15:8] :
  load_half[7:0]
);

wire load_sign = (
  (~is_load_unsigned) & 
  (is_load_store_half ? load_half[15] : load_byte[7])
); 

wire [31:0] load_data = (
  is_load_store_half ? {{16{load_sign}}, load_half} :
  is_load_store_byte ? {{24{load_sign}}, load_byte} :
  load_ori_data_r
);

// ----------------------------------------------------------------------------
// Store
// ----------------------------------------------------------------------------
wire [31:0] store_ori_addr = alu_add;
wire [31:0] store_word_addr = {store_ori_addr[31:2], 2'b0};

wire [31:0] store_byte = {4{rs2_r[7:0]}};
wire [31:0] store_half = {2{rs2_r[15:0]}};

wire [31:0] store_data = (
  is_load_store_byte ? store_byte :
  is_load_store_half ? store_half :
  rs2_r
);

wire [3:0] store_mask = (
  is_load_store_byte ? (
    store_ori_addr[0] ? (
      store_ori_addr[1] ? 4'b1000 : 4'b0010
    ) : (
      store_ori_addr[1] ? 4'b0100 : 4'b0001
    )
  ) :
  is_load_store_half ? (
    store_ori_addr[1] ? 4'b1100 : 4'b0011
  ) :
  4'b1111
);

// ----------------------------------------------------------------------------
// Write Back to rd
// ----------------------------------------------------------------------------
wire wb_en = (
  (state_WB) &
  (rd_id != 0) &
  (is_alu_reg | is_alu_imm | is_jal | is_jalr | is_auipc | is_lui | is_load)
);

wire [31:0] wb_data = (
  is_load ? load_data : 
  is_csrrs ? csrrs_data : 
  alu_out_r
);

// ----------------------------------------------------------------------------
// Output Interface
// ----------------------------------------------------------------------------
assign mem_addr_o = (
  (state_EXE) ? (
    is_load ? load_word_addr :
    is_store ? store_word_addr :
    pc_r
  ) :
  pc_r
);

// assign mem_addr_o = (
//   (state_EXE & is_load) ? load_word_addr :
//   (state_EXE & is_store) ? store_word_addr :
//   pc_r
// );

// reg [31:0] mem_addr_r;
// always @(*) begin
//   // mem_addr_r = pc_r;
//   (* parallel_case, full_case *)
//   case (1'b1)
//     (state_EXE & is_load): mem_addr_r = load_word_addr;
//     (state_EXE & is_store): mem_addr_r = store_word_addr;
//     default: mem_addr_r = pc_r;
//   endcase
// end
// assign mem_addr_o = mem_addr_r;

// reg [31:0] mem_addr_r;
// always @(*) begin
//   if (state_EXE) begin
//     if (is_load) begin
//       mem_addr_r = load_word_addr;
//     end else if (is_store) begin
//       mem_addr_r = store_word_addr;
//     end else begin
//       mem_addr_r = pc_r;
//     end
//   end else begin
//     mem_addr_r = pc_r;
//   end
// end
// assign mem_addr_o = mem_addr_r;

assign mem_rstrb_o = (
  (state_WB) |
  (state_EXE & is_load)
);

assign mem_wmask_o = (
  (state_EXE & is_store) ? store_mask :
  4'b0000
);

assign mem_wdata_o = store_data;

endmodule
