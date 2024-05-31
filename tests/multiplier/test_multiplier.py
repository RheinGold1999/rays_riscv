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
async def memory_test(dut):

  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))

  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0

  dut.vld_i.value = 1
  # op1 = random.randint(0, 0xFFFF_FFFF)
  op1 = 2
  # op2 = random.randint(0, 0xFFFF_FFFF)
  op2 = 7
  dut.op1_i.value = op1
  dut.op2_i.value = op2

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_o.value == op1 * op2, \
    f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"
  
  op1 = 4
  op2 = 2
  dut.op1_i.value = op1
  dut.op2_i.value = op2

  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_o.value == op1 * op2, \
    f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"

  dut.vld_i.value = 0
  await FallingEdge(dut.clk)
    
  dut.vld_i.value = 1
  # op1 = random.randint(0, 0xFFFF_FFFF)
  op1 = 3
  # op2 = random.randint(0, 0xFFFF_FFFF)
  op2 = 3
  dut.op1_i.value = op1
  dut.op2_i.value = op2

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_o.value == op1 * op2, \
    f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"

  dut.vld_i.value = 0
  await FallingEdge(dut.clk)
  await FallingEdge(dut.clk)
    
  dut.vld_i.value = 1
  # op1 = random.randint(0, 0xFFFF_FFFF)
  op1 = 0 
  # op2 = random.randint(0, 0xFFFF_FFFF)
  op2 = 3
  dut.op1_i.value = op1
  dut.op2_i.value = op2

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_o.value == op1 * op2, \
    f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"

  dut.vld_i.value = 0
  await FallingEdge(dut.clk)
 
  dut.vld_i.value = 1
  # op1 = random.randint(0, 0xFFFF_FFFF)
  op1 = 3 
  # op2 = random.randint(0, 0xFFFF_FFFF)
  op2 = 0
  dut.op1_i.value = op1
  dut.op2_i.value = op2

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_o.value == op1 * op2, \
    f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"

  op1 = random.randint(0, 0xFFFF_FFFF)
  op2 = random.randint(0, 0xFFFF_FFFF)
  dut.op1_i.value = op1
  dut.op2_i.value = op2

  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_o.value == op1 * op2, \
    f"res_o={dut.res_o.value.integer}, op1*op2={op1 * op2}"
  
  dut.vld_i.value = 0
  await FallingEdge(dut.clk)
  await FallingEdge(dut.clk)

