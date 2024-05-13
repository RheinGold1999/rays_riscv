# import os
# import sys
import random
# from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.result import TestSuccess
# from cocotb_tools.runner import get_runner


MEM_SIZE = 4 * 1024 * 1024
assert MEM_SIZE % 4 == 0, "MEM_SIZE should be multiple of 4"

WORD_SIZE = MEM_SIZE // 4
U32_MAX = 0xFFFF_FFFF

# @cocotb.coroutine
def load_bin_to_memory(dut, bin_file):
  print(f"type of dut.u_memory.MEM[0].value: {type(dut.u_memory.MEM[0].value)}")
  with open(bin_file, mode='rb') as file:
    data = file.read()
    word = 0
    for i, byte in enumerate(data):
      if i % 4 == 0:
        word = byte
      word |= byte << ((i % 4) * 8)
      if i % 4 == 3 or i == (len(data) - 1):
        dut.u_memory.MEM[i//4].value = word
        if word:
          dut._log.info(f"{i//4}-th word: {word:#x}")


@cocotb.test()
async def test_soc(dut):
  # raise TestSuccess("bypass")
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))

  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0

  # initialize PROGROM and DATARAM
  bin_file = "../software/hello_world/main.bin"
  load_bin_to_memory(dut, bin_file)

  # set CPU SP(x2)
  dut.u_cpu.regfile_ra[2].value = (MEM_SIZE - 16)

  await FallingEdge(dut.clk)

  for i in range(WORD_SIZE):
    if dut.u_memory.MEM[i].value.integer:
      dut._log.info(f"memory.MEM[{i}]={dut.u_memory.MEM[i].value.integer:#x}")

  for _ in range(1000):
    await FallingEdge(dut.clk)
  #   if rstrb:
  #     assert dut.mem_rdata_o.value == ori_data, f"data mismatch at address: {addr:#x}"


