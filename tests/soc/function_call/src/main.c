#include "print.h"

int main()
{
  const char hi[] = "Hello, RISC-V!";
  print_str(hi);
  unsigned int num1 = 1234;
  print_dec(num1);
  unsigned int num2 = 0x1234ABCD;
  print_hex(num2);

  __asm__ volatile ("ebreak");
  return 0;
}

