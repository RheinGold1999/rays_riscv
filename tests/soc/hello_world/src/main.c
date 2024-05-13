#define IO_BASE 0x400000
#define IO_UART 16

int main()
{
  const char message[] = "Hello, World!\n";
  const char* msg_p = message;
  char* uart_addr = (char*)(IO_BASE | IO_UART);
  while (*msg_p) {
    // print to UART
    *uart_addr = *msg_p;
    msg_p++;
  }
  return 0;
}