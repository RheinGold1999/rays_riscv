#include "print.h"
#include "perf.h"


int main()
{
  // for (int i = 0; i < 1; ++i) {
  //   unsigned long long cycles = rdcycle();
  //   unsigned long long instret = rdcycle();
  //   print_str("i=");
  //   print_dec((unsigned int)i);
  //   print_str("    ");
  //   print_str("cycles=");
  //   print_dec((unsigned int)cycles);
  //   print_str("    ");
  //   print_str("instret=");
  //   print_dec((unsigned int)instret);
  //   print_chr('\n');
  // }
  unsigned long long cycles = rdcycle();
  unsigned long long instret = rdcycle();
  unsigned int CPI_100 = div((unsigned int)mul(100, cycles), instret);
  print_str("cycles=");
  print_dec((unsigned int)cycles);
  print_str("    ");
  print_str("instret=");
  print_dec((unsigned int)instret);
  print_str("    ");
  print_str("100CPI=");
  print_dec((unsigned int)CPI_100);
  print_chr('\n');

  __asm__ volatile ("ebreak");
  return 0;
}

