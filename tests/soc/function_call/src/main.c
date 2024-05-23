#define IO_BASE 0x400000
#define IO_UART 16

void print_str(const char* msg);


int main()
{
  const char hi[] = "Hello, RISC-V!";
  print_str(hi);
  __asm__ volatile ("ebreak");
  return 0;
}

void print_str(const char* msg)
{
  char* uart_addr = (char*)(IO_BASE | IO_UART);
  while (*msg) {
    *uart_addr = *msg;
    msg++;
  }
}
