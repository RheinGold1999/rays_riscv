module multiplier (
  input clk,
  input rst,
  input [31:0] op1,
  input [31:0] op2,
  input vld,
  output [63:0] res,
  output rdy
);

reg vld_r;
always @(posedge clk) begin
  if (rst) begin
    vld_r <= 1'b0;
  end else begin
    vld_r <= vld;
  end
end
  
wire fire = (vld ^ vld_r) & (~rdy);
reg [63:0] res_r;
always @(posedge clk) begin
  if (rst) begin
    res_r <= 64'b0;
  end else if (fire) begin
    rst_r <= 64'b0;
  end
end

reg [31:0] op2_r;
always @(posedge clk) begin
  if (rst) begin
    op2_r <= 32'b0;
  end else if (fire) begin
    op2_r <= op2;
  end
end

reg rdy_r;
always @(posedge clk) begin
  if (rst) begin
    rdy_r <= 1'b0;
  end else if (vld & (op2_r == 0)) begin
    rdy_r <= 1'b1;
  end else begin
    rdy_r <= 1'b0;
  end
end

wire [31:0] op2_one_hot = op2_r & ((~op2_r) + 1); // find the 1 in lsb
reg [4:0] op2_lsb_one_idx;
always @(*) begin
  case (op2_one_hot)
    : 
    default: 
  endcase
end

endmodule
