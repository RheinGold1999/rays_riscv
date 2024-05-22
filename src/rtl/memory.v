`include "define.v"

`resetall
`timescale 1ns / 1ps
`default_nettype none

module memory #(
  parameter SIZE = `MEM_SIZE,
  localparam ADDR_WIDTH = $clog2(SIZE)
)(
  input         clk,
  input         rst,
  input  [31:0] mem_addr_i,
  input         mem_rstrb_i,
  output [31:0] mem_rdata_o,
  input  [3:0]  mem_wmask_i,
  input  [31:0] mem_wdata_i
);

initial begin
  if ((SIZE % 4) != 0) begin
    $error("Error: memory SIZE must be multiple of 4");
    $finish;
  end
end

localparam DEPTH = SIZE / 4;
reg [31:0] MEM[0:DEPTH-1];
wire [ADDR_WIDTH-3:0] word_addr_w = mem_addr_i[ADDR_WIDTH-1:2];

always @(posedge clk) begin
  if (rst) begin
    for (int i = 0; i < DEPTH; i = i + 1) begin
      MEM[i] <= 32'h0000_0000;
    end
  end else begin
    if (mem_wmask_i[0]) begin
      MEM[word_addr_w][7:0] <= mem_wdata_i[7:0];
    end
    if (mem_wmask_i[1]) begin
      MEM[word_addr_w][15:8] <= mem_wdata_i[15:8];
    end
    if (mem_wmask_i[2]) begin
      MEM[word_addr_w][23:16] <= mem_wdata_i[23:16];
    end
    if (mem_wmask_i[3]) begin
      MEM[word_addr_w][31:24] <= mem_wdata_i[31:24];
    end
    if (|mem_wmask_i) begin
      $display("[%0t ps][MEM ]: addr=%h, wdata=%h, wmask=%b", $realtime, mem_addr_i, mem_wdata_i, mem_wmask_i);
    end
  end
end

reg [31:0] mem_rdata_r;
always @(posedge clk) begin
  if (rst) begin
    mem_rdata_r <= 32'b0;
  end else if (mem_rstrb_i) begin
    mem_rdata_r <= MEM[word_addr_w];
    $display("[%0t ps][MEM ]: addr=%h, rdata=%h", $realtime, mem_addr_i, mem_rdata_o);
  end
end

assign mem_rdata_o = mem_rdata_r;

endmodule
