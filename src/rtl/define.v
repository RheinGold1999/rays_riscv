`define KB 1024
`define MB (1024 * 1024)
`define MEM_SIZE (4 * `MB)

`define IO_MEM_MAP_BIT $clog2(`MEM_SIZE)
`define UART_MEM_MAP_BIT 4