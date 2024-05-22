`include "define.v"

`resetall
`timescale 1ns / 1ps
`default_nettype none

module uart #(
  parameter IO_MEM_MAP_BIT = `IO_MEM_MAP_BIT,
  parameter UART_MEM_MAP_BIT = `UART_MEM_MAP_BIT
)(
  input         clk,
  input         rst,
  input  [31:0] mem_addr_i,
  input         mem_rstrb_i,
  output [31:0] mem_rdata_o,
  input  [3:0]  mem_wmask_i,
  input  [31:0] mem_wdata_i
);

wire access_uart_w = mem_addr_i[IO_MEM_MAP_BIT] & mem_addr_i[UART_MEM_MAP_BIT];

always @(posedge clk) begin
  if (access_uart_w) begin
    if (mem_wmask_i[0]) begin
      $display("[%0t ps][UART]: %c", $time, mem_wdata_i[7:0]);
    end
  end
end

endmodule
