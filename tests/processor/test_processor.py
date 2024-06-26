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
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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
        assert dut.regfile_ra[x10].value == loop_num, f"x10 should be {loop_num}"
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"


@cocotb.test()
async def test_rtype(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  rs1 = random.randint(-(1<<11), (1<<11)-1)
  # rs1 = random.randint(-(1<<11), -1)
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
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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
        assert dut.regfile_ra[x10].value.signed_integer == (rs1 + rs2), f"x10 (ADD) should be {rs1} + {rs2}"
        assert dut.regfile_ra[x11].value.signed_integer == (rs1 - rs2), f"x11 (SUB) should be {rs1} - {rs2}"
        assert dut.regfile_ra[x12].value.integer == ((rs1_u << (rs2 & 0x1F)) & U32_MAX), f"x12 (SLL) should be {rs1_u} << {(rs2 & 0x1F)}"
        assert dut.regfile_ra[x13].value.signed_integer == (rs1 < rs2), f"x13 (SLT) should be {rs1} < {rs2}"
        assert dut.regfile_ra[x14].value.signed_integer == (rs1_u < rs2_u), f"x14 (SLTU) should be {rs1_u} < {rs2_u}"
        assert dut.regfile_ra[x15].value.signed_integer == (rs1 ^ rs2), f"x15 (XOR) should be {rs1} ^ {rs2}"
        assert dut.regfile_ra[x16].value.integer == (rs1_u >> (rs2 & 0x1F)), f"x16 (SRL) should be {rs1_u} >> {(rs2 & 0x1F)}"
        assert dut.regfile_ra[x17].value.signed_integer == (rs1 >> (rs2 & 0x1F)), f"x17 (SRA) should be {rs1} >> {(rs2 & 0x1F)}"
        assert dut.regfile_ra[x18].value.signed_integer == (rs1 | rs2), f"x18 (OR) should be {rs1} | {rs2}"
        assert dut.regfile_ra[x19].value.signed_integer == (rs1 & rs2), f"x19 (AND) should be {rs1} & {rs2}"
        print(f"rs1={rs1}, rs2={rs2}")
        print(f"rs1_u={rs1_u}, rs2_u={rs2_u}")
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"


@cocotb.test()
async def test_itype(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  rs1 = random.randint(-(1<<11), (1<<11)-1)
  # rs1 = random.randint(-(1<<11), -1)
  imm = random.randint(-(1<<11), (1<<11)-1)
  rs1_u = c_uint32(rs1).value
  imm_u = c_uint32(imm).value
  init_pc()
  # rpdb.set_trace()
  instructions = [
    ADDI(x1, x0, rs1),
    # ADDI(x2, x0, rs2),

    ADDI(x10, x1, imm),
    SLLI(x12, x1, imm),
    SLTI(x13, x1, imm),
    SLTIU(x14, x1, imm),
    XORI(x15, x1, imm),
    SRLI(x16, x1, imm),
    SRAI(x17, x1, imm),
    ORI(x18, x1, imm),
    ANDI(x19, x1, imm),
    
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
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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
        assert dut.regfile_ra[x10].value.signed_integer == (rs1 + imm), f"x10 (ADD) should be {rs1} + {imm}"
        assert dut.regfile_ra[x12].value.integer == ((rs1_u << (imm & 0x1F)) & U32_MAX), f"x12 (SLL) should be {rs1_u} << {(imm & 0x1F)}"
        assert dut.regfile_ra[x13].value.signed_integer == (rs1 < imm), f"x13 (SLT) should be {rs1} < {imm}"
        assert dut.regfile_ra[x14].value.signed_integer == (rs1_u < imm_u), f"x14 (SLTU) should be {rs1_u} < {imm_u}"
        assert dut.regfile_ra[x15].value.signed_integer == (rs1 ^ imm), f"x15 (XOR) should be {rs1} ^ {imm}"
        assert dut.regfile_ra[x16].value.integer == (rs1_u >> (imm & 0x1F)), f"x16 (SRL) should be {rs1_u} >> {(imm & 0x1F)}"
        assert dut.regfile_ra[x17].value.signed_integer == (rs1 >> (imm & 0x1F)), f"x17 (SRA) should be {rs1} >> {(imm & 0x1F)}"
        assert dut.regfile_ra[x18].value.signed_integer == (rs1 | imm), f"x18 (OR) should be {rs1} | {imm}"
        assert dut.regfile_ra[x19].value.signed_integer == (rs1 & imm), f"x19 (AND) should be {rs1} & {imm}"
        print(f"rs1={rs1}, imm={imm}")
        print(f"rs1_u={rs1_u}, imm_u={imm_u}")
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"


@cocotb.test()
async def test_btype(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  L0_ = 48
  L1_ = 56
  L2_ = 64
  L3_ = 72
  L4_ = 80
  L5_ = 88
  # B0_ = 20
  B1_ = 24
  B2_ = 28
  B3_ = 32
  B4_ = 36
  B5_ = 40
  B6_ = 44
  init_pc()
  # rpdb.set_trace()
  instructions = [
    ADDI(x1, x0, -1),
    ADDI(x2, x0, 2),
    ADDI(x3, x0, 2),
    ADDI(x4, x0, 3),
    ADDI(x5, x0, -3),
  # B0_:
    BEQ(x2, x3, label_ref(L0_)),
  # B1_:
    BNE(x1, x2, label_ref(L1_)),
  # B2_:
    BLT(x1, x2, label_ref(L2_)),
  # B3_:
    BGE(x4, x5, label_ref(L3_)),
  # B4_:
    BLTU(x2, x1, label_ref(L4_)),
  # B5_:
    BGEU(x5, x4, label_ref(L5_)),
  # B6_:
    EBREAK(),


  # L0_:
    ADDI(x10, x0, 1),
    JAL(x0, label_ref(B1_)),
  # L1_:
    ADDI(x11, x0, 2),
    JAL(x0, label_ref(B2_)),
  # L2_:
    ADDI(x12, x0, 3),
    JAL(x0, label_ref(B3_)),
  # L3_:
    ADDI(x13, x0, 4),
    JAL(x0, label_ref(B4_)),
  # L4_:
    ADDI(x14, x0, 5),
    JAL(x0, label_ref(B5_)),
  # L5_:
    ADDI(x15, x0, 6),
    JAL(x0, label_ref(B6_)),
  ]
    
  for idx, inst in enumerate(instructions):
    print(f"inst[{idx}]={inst:#x}")

  # initialize memory
  mem_model = [0] * WORD_SIZE
  inst_size = len(instructions)
  assert inst_size <= len(mem_model), "instruction exceeds memory size"
  mem_model[0:inst_size] = instructions

  # clock
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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
        assert dut.regfile_ra[x10].value.integer == 1, f"x10 should be 1"
        assert dut.regfile_ra[x11].value.integer == 2, f"x11 should be 1"
        assert dut.regfile_ra[x12].value.integer == 3, f"x12 should be 3"
        assert dut.regfile_ra[x13].value.integer == 4, f"x13 should be 4"
        assert dut.regfile_ra[x14].value.integer == 5, f"x14 should be 5"
        assert dut.regfile_ra[x15].value.integer == 6, f"x15 should be 6"
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"

@cocotb.test()
async def test_utype(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  imm = c_int32(random.randint(-(1<<31), (1<<31)-1)).value
  init_pc()
  # rpdb.set_trace()
  instructions = [
    LUI(x1, imm),
    ADDI(x2, x0, imm),
    AUIPC(x3, imm),
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
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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
        assert dut.regfile_ra[x1].value.signed_integer == c_int32(imm & 0xFFFF_F000).value, f"x1 (LUI) should be {c_int32(imm & 0xFFFF_F000).value}"
        assert dut.regfile_ra[x3].value.signed_integer == c_int32((imm & 0xFFFF_F000) + 8).value, f"x3 (AUIPC) should be {c_int32((imm & 0xFFFF_F000) + 8).value}"
        print(f"imm={imm}")
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"


@cocotb.test()
async def test_load(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  imm = c_int32(random.randint(-(1<<31), (1<<31)-1)).value
  init_pc()
  # rpdb.set_trace()
  instructions = [
    imm,

    LB(x1, x0, 0),
    LB(x2, x0, 1),
    LB(x3, x0, 2),
    LB(x4, x0, 3),

    LH(x5, x0, 0),
    LH(x6, x0, 2),

    LW(x7, x0, 0),

    LBU(x8, x0, 0),
    LBU(x9, x0, 1),
    LBU(x10, x0, 2),
    LBU(x11, x0, 3),

    LHU(x12, x0, 0),
    LHU(x13, x0, 2),

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
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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
        assert dut.regfile_ra[x1].value.signed_integer == c_int8(get_bitfield(imm, 7, 0)).value, f"x1 should be {c_int8(get_bitfield(imm, 7, 0)).value}"
        assert dut.regfile_ra[x2].value.signed_integer == c_int8(get_bitfield(imm, 15, 8)).value, f"x1 should be {c_int8(get_bitfield(imm, 15, 8)).value}"
        assert dut.regfile_ra[x3].value.signed_integer == c_int8(get_bitfield(imm, 23, 16)).value, f"x1 should be {c_int8(get_bitfield(imm, 23, 16)).value}"
        assert dut.regfile_ra[x4].value.signed_integer == c_int8(get_bitfield(imm, 31, 24)).value, f"x1 should be {c_int8(get_bitfield(imm, 31, 24)).value}"

        assert dut.regfile_ra[x5].value.signed_integer == c_int16(get_bitfield(imm, 15, 0)).value, f"x1 should be {c_int16(get_bitfield(imm, 15, 0)).value}"
        assert dut.regfile_ra[x6].value.signed_integer == c_int16(get_bitfield(imm, 31, 16)).value, f"x1 should be {c_int16(get_bitfield(imm, 31, 16)).value}"

        assert dut.regfile_ra[x7].value.signed_integer == c_int32(imm).value, f"x1 should be {c_int32(imm).value}"

        assert dut.regfile_ra[x8].value.integer == c_uint8(get_bitfield(imm, 7, 0)).value, f"x1 should be {c_uint8(get_bitfield(imm, 7, 0)).value}"
        assert dut.regfile_ra[x9].value.integer == c_uint8(get_bitfield(imm, 15, 8)).value, f"x1 should be {c_uint8(get_bitfield(imm, 15, 8)).value}"
        assert dut.regfile_ra[x10].value.integer == c_uint8(get_bitfield(imm, 23, 16)).value, f"x1 should be {c_uint8(get_bitfield(imm, 23, 16)).value}"
        assert dut.regfile_ra[x11].value.integer == c_uint8(get_bitfield(imm, 31, 24)).value, f"x1 should be {c_uint8(get_bitfield(imm, 31, 24)).value}"

        assert dut.regfile_ra[x12].value.integer == c_uint16(get_bitfield(imm, 15, 0)).value, f"x1 should be {c_uint16(get_bitfield(imm, 15, 0)).value}"
        assert dut.regfile_ra[x13].value.integer == c_uint16(get_bitfield(imm, 31, 16)).value, f"x1 should be {c_uint16(get_bitfield(imm, 31, 16)).value}"

        print(f"imm={imm}")
        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"


@cocotb.test()
async def test_store(dut):
  # raise TestSuccess("bypass")

  # define lable and instructions
  imm1 = c_uint32(random.randint(-(1<<31), (1<<31)-1)).value
  imm1 = set_bitfield(imm1, 0, 11, 11)  # ADDI will signed-extends imm
  imm2 = c_uint32(random.randint(-(1<<31), (1<<31)-1)).value
  imm2 = set_bitfield(imm2, 0, 11, 11)  # ADDI will signed-extends imm
  imm3 = c_uint32(random.randint(-(1<<31), (1<<31)-1)).value
  imm3 = set_bitfield(imm3, 0, 11, 11)  # ADDI will signed-extends imm
  imm4 = c_uint32(random.randint(-(1<<31), (1<<31)-1)).value
  imm4 = set_bitfield(imm4, 0, 11, 11)  # ADDI will signed-extends imm
  init_pc()
  # rpdb.set_trace()
  L0_ = 64
  L1_ = 68
  L2_ = 72

  instructions = [
    # init x1 ~ x4 with imm1 ~ imm4 respectively
    LUI(x1, imm1),
    ADDI(x1, x1, imm1),

    LUI(x2, imm2),
    ADDI(x2, x2, imm2),

    LUI(x3, imm3),
    ADDI(x3, x3, imm3),

    LUI(x4, imm4),
    ADDI(x4, x4, imm4),

    SB(x1, x0, L0_),
    SB(x2, x0, L0_ + 1),
    SB(x3, x0, L0_ + 2),
    SB(x4, x0, L0_ + 3),

    SH(x1, x0, L1_),
    SH(x2, x0, L1_ + 2),

    SW(x1, x0, L2_),

    EBREAK(),
  # L0_:
    0,
  # L1_:
    0,
  # L2_:
    0,
  ]

  for idx, inst in enumerate(instructions):
    print(f"inst[{idx}]={inst:#x}")

  # initialize memory
  mem_model = [0] * WORD_SIZE
  inst_size = len(instructions)
  assert inst_size <= len(mem_model), "instruction exceeds memory size"
  mem_model[0:inst_size] = instructions

  # clock
  clock = Clock(dut.clk, 10, 'ns')
  cocotb.start_soon(clock.start(start_high=False))
  # reset
  dut.rst.value = 1
  await Timer(20, units='ns')
  await FallingEdge(dut.clk)
  dut.rst.value = 0
  
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

        dut._log.info(f"imm1={imm1:#x}")
        dut._log.info(f"imm2={imm2:#x}")
        dut._log.info(f"imm3={imm3:#x}")
        dut._log.info(f"imm4={imm4:#x}")

        L0_word = 0
        L0_word = set_bitfield(L0_word, get_bitfield(imm1, 7, 0), 7, 0)
        L0_word = set_bitfield(L0_word, get_bitfield(imm2, 7, 0), 15, 8)
        L0_word = set_bitfield(L0_word, get_bitfield(imm3, 7, 0), 23, 16)
        L0_word = set_bitfield(L0_word, get_bitfield(imm4, 7, 0), 31, 24)

        assert mem_model[L0_//4] == L0_word, f"mem_model[{L0_//4}] ({mem_model[L0_//4]:#x}) should be {L0_word:#x}"
        
        L1_word = 0
        L1_word = set_bitfield(L1_word, get_bitfield(imm1, 15, 0), 15, 0)
        L1_word = set_bitfield(L1_word, get_bitfield(imm2, 15, 0), 31, 16)
        assert mem_model[L1_//4] == L1_word, f"mem_model[{L1_//4}] ({mem_model[L1_//4]:#x}) should be {L1_word:#x}"

        L2_word = get_bitfield(imm1, 31, 0)
        assert mem_model[L2_//4] == L2_word, f"mem_model[{L2_//4}] ({mem_model[L2_//4]:#x}) should be {L2_word:#x}"

        raise TestSuccess("EBREAK")

    mem_model[word_addr] = wdata_after_mask(mem_model[word_addr], wdata, wmask)

    if word_addr > inst_size:
      assert False, "reach memory limit"

    await FallingEdge(dut.clk)

  assert False, "not reach EBREAK"

