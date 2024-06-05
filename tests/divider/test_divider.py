# import os
# import sys
import random
# from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.result import TestSuccess
# from cocotb_tools.runner import get_runner


@cocotb.test()
async def divider_test(dut):

  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))

  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0

  dut.vld_i.value = 1
  # op1 = random.randint(0, 0xFFFF_FFFF)
  op1 = 15
  # op2 = random.randint(0, 0xFFFF_FFFF)
  op2 = 6
  dut.div1_i.value = op1
  dut.div2_i.value = op2

  # while dut.rdy_o.value == 0:
  #   await FallingEdge(dut.clk)

  # assert dut.res_o.value == op1 * op2, \
  #   f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"

  # dut.vld_i.value = 0
  # await FallingEdge(dut.clk)

  for i in range(30):
    await FallingEdge(dut.clk)

