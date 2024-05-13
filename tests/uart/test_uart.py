# import os
# import sys
import random
# from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.result import TestSuccess
# from cocotb_tools.runner import get_runner


# MEM_SIZE = 4 * 1024 * 1024 
MEM_SIZE = 4 * 32
assert MEM_SIZE % 4 == 0, "MEM_SIZE should be multiple of 4"

WORD_SIZE = MEM_SIZE // 4
U32_MAX = 0xFFFF_FFFF


@cocotb.test()
async def memory_test(dut):
  mem_model = [0] * WORD_SIZE
  # raise TestSuccess("bypass")

  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))

  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0

  for ch in "Hello World!":
    addr = random.randint(0, WORD_SIZE - 1) // 4 * 4
    addr |= 0x40_0010
    rstrb = random.randint(0, 1)
    wmask = 0b0001
    wdata = ord(ch)
    
    dut.mem_addr_i.value = addr
    dut.mem_wmask_i.value = wmask
    dut.mem_wdata_i.value = wdata

    dut._log.info("")
    dut._log.info(f"addr={addr:#x}")
    dut._log.info(f"wmask={wmask:#x}")
    dut._log.info(f"wdata={wdata:#x}")

    # now write is done
    await FallingEdge(dut.clk)

