module multiplier (
  input clk,
  input rst,
  input [31:0] mul1_i,
  input [31:0] mul2_i,
  input vld_i,
  output [63:0] res_o,
  output rdy_o
);

// select the smaller multiplicator as op2
wire is_mul1_larger = (mul1_i > mul2_i);
wire [31:0] op1 = is_mul1_larger ? mul1_i : mul2_i;
wire [31:0] op2 = is_mul1_larger ? mul2_i : mul1_i;

wire fire = vld_i & (~busy_r);
wire done = busy_r & (op2_r == 0);

reg busy_r;
always @(posedge clk) begin
  if (rst) begin
    busy_r <= 1'b0;
  end else if (fire) begin
    busy_r <= 1'b1;
  end else if (done) begin
    busy_r <= 1'b0;
  end
end

reg [63:0] res_r;
always @(posedge clk) begin
  if (rst) begin
    res_r <= 64'b0;
  end else if (fire) begin
    res_r <= 64'b0;
  end else if (busy_r) begin
    res_r <= (res_r + op1_sh_r);
  end
end
assign res_o = res_r;

reg [31:0] op2_r;
always @(posedge clk) begin
  if (rst) begin
    op2_r <= 32'b0;
  end else if (fire) begin
    op2_r <= op2;
  end else if (~done) begin
    op2_r <= op2_r & (~op2_one_hot);
  end
end

reg [63:0] op1_sh_r;
always @(posedge clk) begin
  if (rst) begin
    op1_sh_r <= 63'b0;
  end else if (fire) begin
    op1_sh_r <= 63'b0;
  end else if (~done) begin
    op1_sh_r <= (op1 << op2_lsb_one_idx);
  end
end

reg rdy_r;
always @(posedge clk) begin
  if (rst) begin
    rdy_r <= 1'b0;
  end else begin
    rdy_r <= done;
  end
end
assign rdy_o = rdy_r;

wire [31:0] op2_one_hot = op2_r & ((~op2_r) + 1); // find the 1 in lsb
reg [4:0] op2_lsb_one_idx;
always @(*) begin
  (* parallel_case, full_case *)
  case (op2_one_hot)
    // 3 ~ 0
    32'h0000_0001: op2_lsb_one_idx = 0;
    32'h0000_0002: op2_lsb_one_idx = 1;
    32'h0000_0004: op2_lsb_one_idx = 2;
    32'h0000_0008: op2_lsb_one_idx = 3;
    // 7 ~ 4
    32'h0000_0010: op2_lsb_one_idx = 4;
    32'h0000_0020: op2_lsb_one_idx = 5;
    32'h0000_0040: op2_lsb_one_idx = 6;
    32'h0000_0080: op2_lsb_one_idx = 7;
    // 11 ~ 8
    32'h0000_0100: op2_lsb_one_idx = 8;
    32'h0000_0200: op2_lsb_one_idx = 9;
    32'h0000_0400: op2_lsb_one_idx = 10;
    32'h0000_0800: op2_lsb_one_idx = 11;
    // 15 ~ 12
    32'h0000_1000: op2_lsb_one_idx = 12;
    32'h0000_2000: op2_lsb_one_idx = 13;
    32'h0000_4000: op2_lsb_one_idx = 14;
    32'h0000_8000: op2_lsb_one_idx = 15;
    // 19 ~ 16
    32'h0001_0000: op2_lsb_one_idx = 16;
    32'h0002_0000: op2_lsb_one_idx = 17;
    32'h0004_0000: op2_lsb_one_idx = 18;
    32'h0008_0000: op2_lsb_one_idx = 19;
    // 23 ~ 20
    32'h0010_0000: op2_lsb_one_idx = 20;
    32'h0020_0000: op2_lsb_one_idx = 21;
    32'h0040_0000: op2_lsb_one_idx = 22;
    32'h0080_0000: op2_lsb_one_idx = 23;
    // 27 ~ 24
    32'h0100_0000: op2_lsb_one_idx = 24;
    32'h0200_0000: op2_lsb_one_idx = 25;
    32'h0400_0000: op2_lsb_one_idx = 26;
    32'h0800_0000: op2_lsb_one_idx = 27;
    // 31 ~ 28
    32'h1000_0000: op2_lsb_one_idx = 28;
    32'h2000_0000: op2_lsb_one_idx = 29;
    32'h4000_0000: op2_lsb_one_idx = 30;
    32'h8000_0000: op2_lsb_one_idx = 31;
  endcase
end


endmodule
