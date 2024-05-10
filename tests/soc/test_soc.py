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
  with open(bin_file, mode='rb') as file:
    data = file.read()
    print(f"data size = {len(data)}")
    print(f"data type = {type(data)}")
    word = 0
    for i, byte in enumerate(data):
      if i % 4 == 0:
        word = byte
      word |= byte << ((i % 4) * 8)
      if i % 4 == 3 or i == (len(data) - 1):
        dut.u_memory.MEM[i//4].value = word
        # dut._log.info(f"{i//4}-th word: {word:#x}")
      


@cocotb.test()
async def test_soc(dut):
  bin_file = "../software/hello_world/main.bin"
  load_bin_to_memory(dut, bin_file)

  # # raise TestSuccess("bypass")

  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))

  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0

  for _ in range(1000):
  #   addr = random.randint(0, WORD_SIZE - 1) // 4 * 4
  #   rstrb = random.randint(0, 1)
  #   wmask = random.randint(0, 3) if rstrb == 0 else 0
  #   wdata = random.randint(0, U32_MAX)
    
  #   dut.mem_addr_i.value = addr
  #   dut.mem_wmask_i.value = wmask
  #   dut.mem_wdata_i.value = wdata

  #   dut._log.info("")
  #   dut._log.info(f"addr={addr:#x}")
  #   dut._log.info(f"wmask={wmask:#x}")
  #   dut._log.info(f"wdata={wdata:#x}")

  #   wr_mask = 0
  #   for i in range(4):
  #     if (wmask >> i) & 0x1:
  #       wr_mask |= (0xFF << (i * 8))
  #   wr_unmask = U32_MAX ^ wr_mask
  #   dut._log.info(f"wr_mask={wr_mask:#x}")
  #   dut._log.info(f"wr_unmask={wr_unmask:#x}")
  #   ori_data = mem_model[addr]
  #   dut._log.info(f"ori_data={ori_data:#x}")
  #   mem_model[addr] = (ori_data & wr_unmask) | (wdata & wr_mask)

  #   dut.mem_rstrb_i.value = rstrb
  #   # now write is done
    await FallingEdge(dut.clk)

  #   if rstrb:
  #     assert dut.mem_rdata_o.value == ori_data, f"data mismatch at address: {addr:#x}"


