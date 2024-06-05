module divider (
  input clk,
  input rst,
  input [31:0] div1_i,
  input [31:0] div2_i,
  input vld_i,
  output [31:0] res_q_o,
  output [31:0] res_r_o,
  output rdy_o
);

wire fire = vld_i & (~busy_r);
wire done = busy_r & div1_r_lt_div2_sh & (div_msb_diff == 0);

wire [31:0] div = busy_r ? div1_r : div2_i;
wire [4:0] msb_idx;
msb_idx_calc u_msb_idx_calc (
  .div_i(div),
  .msb_idx_o(msb_idx)
);

reg [4:0] div1_msb_idx_r;
always @(posedge clk) begin
  if (rst) begin
    div1_msb_idx_r <= 5'b0;
  end else if (busy_r) begin
    div1_msb_idx_r <= msb_idx;
  end
end

reg [4:0] div2_msb_idx_r;
always @(posedge clk) begin
  if (rst) begin
    div2_msb_idx_r <= 5'b0;
  end else if (fire) begin
    div2_msb_idx_r <= msb_idx;
  end
end

wire [5:0] div_msb_diff_ori = div1_msb_idx_r + {1'b1, ~div2_msb_idx_r} + 1;
wire [4:0] div_msb_diff = div_msb_diff_ori[5] ? 5'b0 : div_msb_diff_ori[4:0];

reg [4:0] div_msb_diff_r;
always @(posedge clk) begin
  if (rst) begin
    div_msb_diff_r <= 5'b0;
  end else if (div1_r_lt_div2_sh & (div_msb_diff != 0)) begin
    div_msb_diff_r <= div_msb_diff - 1;
  end else begin
    div_msb_diff_r <= div_msb_diff;
  end
end

wire [31:0] div2_sh = div2_i << div_msb_diff_r;
wire [32:0] div_diff = div1_r + {1'b1, ~div2_sh} + 1;
wire div1_r_lt_div2_sh = div_diff[32];

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

reg [31:0] div1_r;
always @(posedge clk) begin
  if (rst) begin
    div1_r <= 32'b0;
  end else if (fire) begin
    div1_r <= div1_i;
  end else if (~done) begin
    if (~div1_r_lt_div2_sh) begin
      div1_r <= div_diff[31:0];
    end
  end
end

reg [31:0] res_q_r;
always @(posedge clk) begin
  if (rst) begin
    res_q_r <= 32'b0;
  end else if (~done) begin
    res_q_r <= (res_q_r | (32'b1 << div_msb_diff_r));
  end
end

assign res_q_o = res_q_r;
assign res_r_o = div1_r;
assign ryd_o = done;

endmodule // divider


module msb_idx_calc (
  input [31:0] div_i,
  output [4:0] msb_idx_o
);

wire [31:0] div_rvs = {
  div_i[0],  div_i[1],  div_i[2],  div_i[3],  div_i[4],  div_i[5],  div_i[6],  div_i[7],
  div_i[8],  div_i[9],  div_i[10], div_i[11], div_i[12], div_i[13], div_i[14], div_i[15],
  div_i[16], div_i[17], div_i[18], div_i[19], div_i[20], div_i[21], div_i[22], div_i[23],
  div_i[24], div_i[25], div_i[26], div_i[27], div_i[28], div_i[29], div_i[30], div_i[31]
};

wire [31:0] div_rvs_lsb_one_hot = div_rvs & (~div_rvs + 32'b1);

reg [4:0] msb_idx_r;
always @(*) begin
  (* parallel_case, full_case *)
  case (div_rvs_lsb_one_hot)
    // 31 ~ 28
    32'h0000_0001: msb_idx_r = 31;
    32'h0000_0002: msb_idx_r = 30;
    32'h0000_0004: msb_idx_r = 29;
    32'h0000_0008: msb_idx_r = 28;
    // 27 ~ 24
    32'h0000_0010: msb_idx_r = 27;
    32'h0000_0020: msb_idx_r = 26;
    32'h0000_0040: msb_idx_r = 25;
    32'h0000_0080: msb_idx_r = 24;
    // 23 ~ 20
    32'h0000_0100: msb_idx_r = 23;
    32'h0000_0200: msb_idx_r = 22;
    32'h0000_0400: msb_idx_r = 21;
    32'h0000_0800: msb_idx_r = 20;
    // 19 ~ 16
    32'h0000_1000: msb_idx_r = 19;
    32'h0000_2000: msb_idx_r = 18;
    32'h0000_4000: msb_idx_r = 17;
    32'h0000_8000: msb_idx_r = 16;
    // 15 ~ 12
    32'h0001_0000: msb_idx_r = 15;
    32'h0002_0000: msb_idx_r = 14;
    32'h0004_0000: msb_idx_r = 13;
    32'h0008_0000: msb_idx_r = 12;
    // 11 ~ 8
    32'h0010_0000: msb_idx_r = 11;
    32'h0020_0000: msb_idx_r = 10;
    32'h0040_0000: msb_idx_r = 9;
    32'h0080_0000: msb_idx_r = 8;
    // 7 ~ 4
    32'h0100_0000: msb_idx_r = 7;
    32'h0200_0000: msb_idx_r = 6;
    32'h0400_0000: msb_idx_r = 5;
    32'h0800_0000: msb_idx_r = 4;
    // 3 ~ 0
    32'h1000_0000: msb_idx_r = 3;
    32'h2000_0000: msb_idx_r = 2;
    32'h4000_0000: msb_idx_r = 1;
    32'h8000_0000: msb_idx_r = 0;
  endcase
end

assign msb_idx_o = msb_idx_r;

endmodule // msb_idx_calc
