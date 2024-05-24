#include "print.h"

#define IO_BASE 0x400000
#define IO_UART 16
#define UART_ADDR (IO_BASE | IO_UART)

void print_chr(char ch)
{
  *((volatile unsigned int*)UART_ADDR) = ch;
}


void print_str(const char* msg)
{
  while (*msg) {
    *((volatile unsigned int*)UART_ADDR) = *(msg++);
  }
}

unsigned long long mul(unsigned int a, unsigned int b)
{
  unsigned long long res = 0;
  for (int i = 0; i < 32; ++i) {
    if ((b >> i) & 0x1) {
      res += (((unsigned long long)a) << i);
    }
  }
  return res;
}

unsigned int div(unsigned int a, unsigned int b)
{
  unsigned int res = 0;
  unsigned long long temp = 0;
  for (int i = 31; i >= 0; --i) {
    temp = ((unsigned long long)b) << i;
    if (a > temp) {
      res += (1 << i);
      a -= temp;
    }
  }
  return res;
}

unsigned int mod(unsigned int a, unsigned int b)
{
  unsigned int res = 0;
  unsigned long long temp = 0;
  for (int i = 31; i >= 0; --i) {
    temp = ((unsigned long long)b) << i;
    if (a > temp) {
      res += (1 << i);
      a -= temp;
    }
  }
  return a;
}

void print_dec(unsigned int val)
{
  unsigned char buf[10];
  unsigned char* p = buf;
  while (val || p == buf) {
    *(p++) = mod(val, 10);
    val = div(val, 10);
  }
  while (p != buf) {
    *((volatile unsigned int*)UART_ADDR) = "0123456789"[*(--p)];
  }
}

void print_hex(unsigned int val)
{
  unsigned char buf[8];
  unsigned char* p = buf;
  while (val || p == buf) {
    *(p++) = val & 0xF; // equivalent: val % 16 (not supported in RV32I)
    val >>= 4;  // equivalent: val /= 16 (not supported in RV32I)
  }
  while (p != buf) {
    *((volatile unsigned int*)UART_ADDR) = "0123456789ABCDEF"[*(--p)];
  }
}

