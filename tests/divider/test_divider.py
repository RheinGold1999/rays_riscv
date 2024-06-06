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

  ##############################################################################
  # test 1
  ##############################################################################
  dut.vld_i.value = 1
  # op1 = random.randint(0, 0xFFFF_FFFF)
  op1 = 15
  # op2 = random.randint(0, 0xFFFF_FFFF)
  op2 = 6
  dut.div1_i.value = op1
  dut.div2_i.value = op2
  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_q_o.value == op1 // op2, \
    f"res_q_o={dut.res_q_o.value.integer}, op1 // op2={op1 // op2}"

  assert dut.res_r_o.value == op1 % op2, \
    f"res_r_o={dut.res_r_o.value.integer}, op1 % op2={op1 % op2}"

  ##############################################################################
  # test 2
  ##############################################################################
  op1 = 31
  op2 = 7
  dut.div1_i.value = op1
  dut.div2_i.value = op2
  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_q_o.value == op1 // op2, \
    f"res_q_o={dut.res_q_o.value.integer}, op1 // op2={op1 // op2}"

  assert dut.res_r_o.value == op1 % op2, \
    f"res_r_o={dut.res_r_o.value.integer}, op1 % op2={op1 % op2}"

  ##############################################################################
  # test 3
  ##############################################################################
  op1 = 0
  op2 = 7
  dut.div1_i.value = op1
  dut.div2_i.value = op2
  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_q_o.value == op1 // op2, \
    f"res_q_o={dut.res_q_o.value.integer}, op1 // op2={op1 // op2}"

  assert dut.res_r_o.value == op1 % op2, \
    f"res_r_o={dut.res_r_o.value.integer}, op1 % op2={op1 % op2}"

  ##############################################################################
  # test 4
  ##############################################################################
  op1 = 2
  op2 = 7
  dut.div1_i.value = op1
  dut.div2_i.value = op2
  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_q_o.value == op1 // op2, \
    f"res_q_o={dut.res_q_o.value.integer}, op1 // op2={op1 // op2}"

  assert dut.res_r_o.value == op1 % op2, \
    f"res_r_o={dut.res_r_o.value.integer}, op1 % op2={op1 % op2}"

  ##############################################################################
  # test 5
  ##############################################################################
  op1 = 11
  op2 = 6
  dut.div1_i.value = op1
  dut.div2_i.value = op2
  await FallingEdge(dut.clk)

  while dut.rdy_o.value == 0:
    await FallingEdge(dut.clk)

  assert dut.res_q_o.value == op1 // op2, \
    f"res_q_o={dut.res_q_o.value.integer}, op1 // op2={op1 // op2}"

  assert dut.res_r_o.value == op1 % op2, \
    f"res_r_o={dut.res_r_o.value.integer}, op1 % op2={op1 % op2}"

  ##############################################################################
  # test 6
  ##############################################################################
  for _ in range(10):
    dut.vld_i.value = 0
    await FallingEdge(dut.clk)

    dut.vld_i.value = 1
    op1 = random.randint(0, 0xFFFF_FFFF)
    op2 = random.randint(1, 0xFFFF_FFFF)
    dut.div1_i.value = op1
    dut.div2_i.value = op2
    await FallingEdge(dut.clk)

    while dut.rdy_o.value == 0:
      await FallingEdge(dut.clk)

    assert dut.res_q_o.value == op1 // op2, \
      f"res_q_o={dut.res_q_o.value.integer}, op1 // op2={op1 // op2}"

    assert dut.res_r_o.value == op1 % op2, \
      f"res_r_o={dut.res_r_o.value.integer}, op1 % op2={op1 % op2}"
