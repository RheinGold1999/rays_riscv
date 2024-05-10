`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "define.v"
`include "processor.v"
`include "memory.v"
`include "uart.v"
`include "mem_bus.v"

module soc (
  input clk,
  input rst
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

processor u_cpu (
  .clk(clk),
  .rst(rst),
  .mem_addr_o(cpu_addr_w),
  .mem_rstrb_o(cpu_rstrb_w),
  .mem_rdata_i(cpu_rdata_w),
  .mem_wmask_o(cpu_wmask_w),
  .mem_wdata_o(cpu_wdata_w)
);

// RAM
wire [31:0] ram_addr_w;
wire        ram_rstrb_w;
wire [31:0] ram_rdata_w;
wire [3:0]  ram_wmask_w;
wire [31:0] ram_wdata_w;

memory #(
  .SIZE(`MEM_SIZE)
) u_memory (
  .clk(clk),
  .rst(rst),
  .mem_addr_i(ram_addr_w),
  .mem_rstrb_i(ram_rstrb_w),
  .mem_rdata_o(ram_rdata_w),
  .mem_wmask_i(ram_wmask_w),
  .mem_wdata_i(ram_wdata_w)
);

// UART
wire [31:0] uart_addr_w;
wire        uart_rstrb_w;
wire [31:0] uart_rdata_w;
wire [3:0]  uart_wmask_w;
wire [31:0] uart_wdata_w;

uart #(
  .IO_MEM_MAP_BIT(`IO_MEM_MAP_BIT),
  .UART_MEM_MAP_BIT(`UART_MEM_MAP_BIT)
) u_uart (
  .clk(clk),
  .rst(rst),
  .mem_addr_i(uart_addr_w),
  .mem_rstrb_i(uart_rstrb_w),
  .mem_rdata_o(uart_rdata_w),
  .mem_wmask_i(uart_wmask_w),
  .mem_wdata_i(uart_wdata_w)
);

mem_bus u_bus(
  // CPU
  .cpu_addr_i(cpu_addr_w),
  .cpu_rstrb_i(cpu_rstrb_w),
  .cpu_rdata_o(cpu_rdata_w),
  .cpu_wmask_i(cpu_wmask_w),
  .cpu_wdata_i(cpu_wdata_w),
  // RAM
  .ram_addr_o(ram_addr_w),
  .ram_rstrb_o(ram_rstrb_w),
  .ram_rdata_i(ram_rdata_w),
  .ram_wmask_o(ram_wmask_w),
  .ram_wdata_o(ram_wdata_w),
  // UART
  .uart_addr_o(uart_addr_w),
  .uart_rstrb_o(uart_rstrb_w),
  .uart_rdata_i(uart_rdata_w),
  .uart_wmask_o(uart_wmask_w),
  .uart_wdata_o(uart_wdata_w)
);

endmodule
