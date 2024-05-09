`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "processor.v"
`include "memory.v"

module soc (
  input clk_i,
  input rst_i
);

// reg clk;
// reg rst;

// always begin
//   #5 clk = ~clk;
// end

// initial begin
//   clk = 1;
//   rst = 1;
//   #15
//   rst = 0; 
// end

// CPU
wire [31:0] cpu_addr_w;
wire        cpu_rstrb_w;
wire [31:0] cpu_rdata_w;
wire [3:0]  cpu_wmask_w;
wire [31:0] cpu_wdata_w;

processor u_processor(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .mem_addr_o(cpu_addr_w),
  .mem_rstrb_o(cpu__rstrb_w),
  .mem_rdata_i(cpu__rdata_w)
  .mem_wmask_o(cpu__wmask_w),
  .mem_wdata_o(cpu__wdata_w)
);

// RAM
wire [31:0] ram_addr_w;
wire        ram_rstrb_w;
wire [31:0] ram_rdata_w;
wire [3:0]  ram_wmask_w;
wire [31:0] ram_wdata_w;

memory #(
  .SIZE(4 * 1024 * 1024)
) u_memory(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .mem_addr_i(ram_addr_w),
  .mem_rstrb_i(ram__addr_w),
  .mem_rdata_o(ram__rdata_w),
  .mem_wmask_i(ram__wmask_w),
  .mem_wdata_i(ram__wdata_w)
);

// UART
wire [31:0] uart_addr_w;
wire        uart_rstrb_w;
wire [31:0] uart_rdata_w;
wire [3:0]  uart_wmask_w;
wire [31:0] uart_wdata_w;

uart u_uart(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .mem_addr_i(uart_addr_w),
  .mem_rstrb_i(uart__addr_w),
  .mem_rdata_o(uart__rdata_w),
  .mem_wmask_i(uart__wmask_w),
  .mem_wdata_i(uart__wdata_w)
);

endmodule
