`resetall
`timescale 1ns / 1ps
`default_nettype none

module uart #(
  parameter IO_CRTL_BIT = 22,
  parameter UART_CTRL_BIT = 4
)(
  input         clk_i,
  input         rst_i,
  input  [31:0] mem_addr_i,
  input         mem_rstrb_i,
  output [31:0] mem_rdata_o,
  input  [3:0]  mem_wmask_i,
  input  [31:0] mem_wdata_i
);

wire access_uart_w = mem_addr_i[IO_CRTL_BIT] & mem_addr_i[UART_CTRL_BIT];

always @(posedge clk_i) begin
  if (access_uart_w) begin
    if (mem_wmask_i[0]) begin
      $display("[%t ps][UART]: %c", $time, mem_wdata_i[7:0]);
    end
  end
end

endmodule
