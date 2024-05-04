import random
from ctypes import *

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.result import TestSuccess

from riscv_assembler import *

# from remote_pdb import RemotePdb
# rpdb = RemotePdb("127.0.0.1", 4000)

MEM_SIZE = 4 * 1024  # 4 KB
# MEM_SIZE = 4 * 32
assert MEM_SIZE % 4 == 0, "MEM_SIZE should be multiple of 4"

WORD_SIZE = MEM_SIZE // 4
U32_MAX = 0xFFFF_FFFF

def wdata_after_mask(ori_data, wdata, wmask):
  wr_mask = 0
  for i in range(4):
    if (wmask >> i) & 0x1:
      wr_mask |= (0xFF << (i * 8))
  wr_unmask = U32_MAX ^ wr_mask
  wr_data = (ori_data & wr_unmask) | (wdata & wr_mask)
  return wr_data

@cocotb.test()
async def test_loop(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  L0_ = 8
  wait_ = 24
  L1_ = 32
  slow_bit = 1
  loop_num = 4
  init_pc()
  # rpdb.set_trace()
  instructions = [
    ADD(x10, x0, x0),
    ADDI(x12, x0, loop_num),
  # L0_:
    ADDI(x10, x10, 1),
    JAL(x1, label_ref(wait_)),
    BNE(x10, x12, label_ref(L0_)),
    EBREAK(),
  # wait_:
    ADDI(x11, x0, 1),
    SLLI(x11, x11, slow_bit),
  # L1_:
    ADDI(x11, x11, -1),
    BNE(x11, x0, label_ref(L1_)),
    JALR(x0, x1, x0),
  ]

  for idx, inst in enumerate(instructions):
    print(f"inst[{idx}]={inst:#x}")

  # initialize memory
  mem_model = [0] * WORD_SIZE
  inst_size = len(instructions)
  assert inst_size <= len(mem_model), "instruction exceeds memory size"
  mem_model[0:inst_size] = instructions

  # clock
  clock = Clock(dut.clk_i, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst_i.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk_i)
  dut.rst_i.value = 0
  
  for _ in range(500):
    addr = dut.mem_addr_o.value
    wmask = dut.mem_wmask_o.value
    wdata = dut.mem_wdata_o.value
    rstrb = dut.mem_rstrb_o.value

    dut._log.info("")
    dut._log.info(f"addr={addr}")
    dut._log.info(f"wmask={wmask}")
    dut._log.info(f"wdata={wdata}")
    dut._log.info(f"rstrb={rstrb}")

    word_addr = addr.integer >> 2
    if rstrb:
      rdata = mem_model[word_addr]
      dut.mem_rdata_i.value = rdata
      dut._log.info(f"rdata={rdata}")
      if rdata == EBREAK():
        dut._log.info("reach EBREAK")
        assert dut.rf_ra[x10].value == loop_num, f"x10 should be {loop_num}"
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk_i)

  assert False, "don't reach EBREAK"


@cocotb.test()
async def test_rtype(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  # rs1 = random.randint(-(1<<11), (1<<11)-1)
  rs1 = random.randint(-(1<<11), -1)
  rs2 = random.randint(-(1<<11), (1<<11)-1)
  rs1_u = c_uint32(rs1).value
  rs2_u = c_uint32(rs2).value
  init_pc()
  # rpdb.set_trace()
  instructions = [
    ADDI(x1, x0, rs1),
    ADDI(x2, x0, rs2),

    ADD(x10, x1, x2),
    SUB(x11, x1, x2),
    SLL(x12, x1, x2),
    SLT(x13, x1, x2),
    SLTU(x14, x1, x2),
    XOR(x15, x1, x2),
    SRL(x16, x1, x2),
    SRA(x17, x1, x2),
    OR(x18, x1, x2),
    AND(x19, x1, x2),
    
    EBREAK(),
  ]

  for idx, inst in enumerate(instructions):
    print(f"inst[{idx}]={inst:#x}")

  # initialize memory
  mem_model = [0] * WORD_SIZE
  inst_size = len(instructions)
  assert inst_size <= len(mem_model), "instruction exceeds memory size"
  mem_model[0:inst_size] = instructions

  # clock
  clock = Clock(dut.clk_i, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst_i.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk_i)
  dut.rst_i.value = 0
  
  for _ in range(500):
    addr = dut.mem_addr_o.value
    wmask = dut.mem_wmask_o.value
    wdata = dut.mem_wdata_o.value
    rstrb = dut.mem_rstrb_o.value

    dut._log.info("")
    dut._log.info(f"addr={addr}")
    dut._log.info(f"wmask={wmask}")
    dut._log.info(f"wdata={wdata}")
    dut._log.info(f"rstrb={rstrb}")

    word_addr = addr.integer >> 2
    if rstrb:
      rdata = mem_model[word_addr]
      dut.mem_rdata_i.value = rdata
      dut._log.info(f"rdata={rdata}")
      if rdata == EBREAK():
        dut._log.info("reach EBREAK")
        assert dut.rf_ra[x10].value.signed_integer == (rs1 + rs2), f"x10 (ADD) should be {rs1} + {rs2}"
        assert dut.rf_ra[x11].value.signed_integer == (rs1 - rs2), f"x11 (SUB) should be {rs1} - {rs2}"
        assert dut.rf_ra[x12].value.integer == ((rs1 << (rs2 & 0x1F)) & U32_MAX), f"x12 (SLL) should be {rs1} << {(rs2 & 0x1F)}"
        assert dut.rf_ra[x13].value.signed_integer == (rs1 < rs2), f"x13 (SLT) should be {rs1} < {rs2}"
        assert dut.rf_ra[x14].value.signed_integer == (rs1_u < rs2_u), f"x14 (SLTU) should be {rs1_u} < {rs2_u}"
        assert dut.rf_ra[x15].value.signed_integer == (rs1 ^ rs2), f"x15 (XOR) should be {rs1} ^ {rs2}"
        assert dut.rf_ra[x16].value.signed_integer == (rs1_u >> (rs2 & 0x1F)), f"x16 (SRL) should be {rs1_u} >> {(rs2 & 0x1F)}"
        assert dut.rf_ra[x17].value.signed_integer == (rs1 >> (rs2 & 0x1F)), f"x17 (SRA) should be {rs1} >> {(rs2 & 0x1F)}"
        assert dut.rf_ra[x18].value.signed_integer == (rs1 | rs2), f"x18 (OR) should be {rs1} | {rs2}"
        assert dut.rf_ra[x19].value.signed_integer == (rs1 & rs2), f"x19 (AND) should be {rs1} & {rs2}"
        print(f"rs1={rs1}, rs2={rs2}")
        print(f"rs1_u={rs1_u}, rs2_u={rs2_u}")
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk_i)

  assert False, "don't reach EBREAK"