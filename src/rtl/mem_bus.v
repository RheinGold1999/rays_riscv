`resetall
`timescale 1ns / 1ps
`default_nettype none

module mem_bus (
  // CPU (slave interface)
  input  [31:0] cpu_addr_i,
  input         cpu_rstrb_i,
  output [31:0] cpu_rdata_o,
  input  [3:0]  cpu_wmask_i,
  input  [31:0] cpu_wdata_i,

  // RAM (master interface)
  output [31:0] ram_addr_o,
  output        ram_rstrb_o,
  input  [31:0] ram_rdata_i,
  output [3:0]  ram_wmask_o,
  output [31:0] ram_wdata_o,

  // UART (master interface)
  output [31:0] uart_addr_o,
  output        uart_rstrb_o,
  input  [31:0] uart_rdata_i,
  output [3:0]  uart_wmask_o,
  output [31:0] uart_wdata_o,
);

wire is_io_w = cpu_addr_i[22];
wire is_ram_w = ~is_io_w;

// CPU
assign cpu_rdata_o = is_io_w ? uart_rdata_i : ram_rdata_i;

// RAM
assign ram_addr_o = cpu_addr_i;
assign ram_rstrb_o = is_ram_w & cpu_rstrb_i;
assign ram_wmask_o = {4{is_ram_w}} & cpu_wmask_i;
assign ram_wdata_o = cpu_wdata_i;

// UART
assign uart_addr_o = cpu_addr_i;
assign uart_rstrb_o = is_io_w & cpu_rstrb_i;
assign uart_wmask_o = {4{is_io_w}} & cpu_wmask_i;
assign uart_wdata_o = cpu_wdata_i;


endmodule
