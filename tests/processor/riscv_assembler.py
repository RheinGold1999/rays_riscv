# registers
x0 = 0
x1 = 1
x2 = 2
x3 = 3
x4 = 4
x5 = 5
x6 = 6
x7 = 7
x8 = 8
x9 = 9
x10 = 10
x11 = 11
x12 = 12
x13 = 13
x14 = 14
x15 = 15
x16 = 16
x17 = 17
x18 = 18
x19 = 19
x20 = 20
x21 = 21
x22 = 22
x23 = 23
x24 = 24
x25 = 25
x26 = 26
x27 = 27
x28 = 28
x29 = 29
x30 = 30
x31 = 31

# register ABI
zero = x0
ra = x1
sp = x2
gp = x3
tp = x4
t0 = x5
t1 = x6 
t2 = x7 
fp = x8 
s0 = x8
s1 = x9 
a0 = x10
a1 = x11
a2 = x12
a3 = x13
a4 = x14
a5 = x15
a6 = x16
a7 = x17
s2 = x18
s3 = x19
s4 = x20
s5 = x21
s6 = x22
s7 = x23
s8 = x24
s9 = x25
s10 = x26
s11 = x27
t3 = x28
t4 = x29
t5 = x30
t6 = x31


U32_MAX = 0xFFFF_FFFF
PC = 0

def init_pc():
  global PC
  PC = 0

def label_ref(label):
  return label - PC

# get_bitfield(val, msb, lsb): `val[msb:lsb]`
def get_bitfield(val, msb, lsb):
  return (val >> lsb) & ((1 << (msb + 1 - lsb)) - 1)

# set_bitfield(val, msb, lsb, bf): `val[msb:lsb] = bf`
def set_bitfield(val, bf, msb, lsb):
  mask = ((U32_MAX >> (msb + 1)) << (msb + 1)) ^ ((U32_MAX >> lsb) << lsb)
  unmask = U32_MAX ^ mask
  return (val & unmask) | ((bf & ((1 << (msb + 1 - lsb)) - 1)) << lsb)

# #########################################################
# RType
# rd <- rs1 OP rs2
# #########################################################
def RType(opcode, rd, rs1, rs2, funct3, funct7):
  inst = 0
  inst = set_bitfield(inst, opcode, 6, 0)
  inst = set_bitfield(inst, rd, 11, 7)
  inst = set_bitfield(inst, funct3, 14, 12)
  inst = set_bitfield(inst, rs1, 19, 15)
  inst = set_bitfield(inst, rs2, 24, 20)
  inst = set_bitfield(inst, funct7, 31, 25)
  global PC
  PC += 4
  return inst & U32_MAX

def ADD(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b000, 0b000_0000)

def SUB(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b000, 0b010_0000)

def SLL(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b001, 0b000_0000)

def SLT(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b010, 0b000_0000)

def SLTU(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b011, 0b000_0000)

def XOR(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b100, 0b000_0000)

def SRL(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b101, 0b010_0000)

def SRA(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b001, 0b000_0000)

def OR(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b110, 0b000_0000)

def AND(rd, rs1, rs2):
  return RType(0b011_0011, rd, rs1, rs2, 0b111, 0b000_0000)


# #########################################################
# IType
# rd <- rs1 OP imm
# #########################################################
def IType(opcode, rd, rs1, imm, funct3):
  inst = 0
  inst = set_bitfield(inst, opcode, 6, 0)
  inst = set_bitfield(inst, rd, 11, 7)
  inst = set_bitfield(inst, funct3, 14, 12)
  inst = set_bitfield(inst, rs1, 19, 15)
  imm_11_0 = get_bitfield(imm, 11, 0)
  inst = set_bitfield(inst, imm_11_0, 31, 20)
  global PC
  PC += 4
  return inst & U32_MAX

def ADDI(rd, rs1, imm):
  return IType(0b001_0011, rd, rs1, imm, 0b000)

def SLTI(rd, rs1, imm):
  return IType(0b001_0011, rd, rs1, imm, 0b010)

def SLTIU(rd, rs1, imm):
  return IType(0b001_0011, rd, rs1, imm, 0b011)

def XORI(rd, rs1, imm):
  return IType(0b001_0011, rd, rs1, imm, 0b100)

def ORI(rd, rs1, imm):
  return IType(0b001_0011, rd, rs1, imm, 0b110)

def ANDI(rd, rs1, imm):
  return IType(0b001_0011, rd, rs1, imm, 0b111)

# SLLI, SRLI, SRAI are encoded in RType format
def SLLI(rd, rs1, imm):
  return RType(0b001_0011, rd, rs1, (imm & 0x1F), 0b001, 0b000_0000)

def SRLI(rd, rs1, imm):
  return RType(0b001_0011, rd, rs1, (imm & 0x1F), 0b101, 0b000_0000)

def SRAI(rd, rs1, imm):
  return RType(0b001_0011, rd, rs1, (imm & 0x1F), 0b101, 0b010_0000)


# #########################################################
# JType
# JAL and JALR
# #########################################################
def JType(opcode, rd, imm):
  inst = 0
  inst = set_bitfield(inst, opcode, 6, 0)
  inst = set_bitfield(inst, rd, 11, 7)
  imm_19_12 = get_bitfield(imm, 19, 12)
  inst = set_bitfield(inst, imm_19_12, 19, 12)
  imm_11 = get_bitfield(imm, 11, 11)
  inst = set_bitfield(inst, imm_11, 20, 20)
  imm_10_1 = get_bitfield(imm, 10, 1)
  inst = set_bitfield(inst, imm_10_1, 30, 21)
  imm_20 = get_bitfield(imm, 20, 20)
  inst = set_bitfield(inst, imm_20, 31, 31)
  global PC
  PC += 4
  return inst & U32_MAX

def JAL(rd, imm):
  return JType(0b110_1111, rd, imm)

def JALR(rd, rs1, imm):
  return IType(0b110_0111, rd, rs1, imm, 0b000)

# #########################################################
# BType
# Branch instruction
# #########################################################
def BType(opcode, rs1, rs2, imm, funct3):
  inst = 0
  inst = set_bitfield(inst, opcode, 6, 0)
  imm_11 = get_bitfield(imm, 11, 11)
  inst = set_bitfield(inst, imm_11, 7, 7)
  imm_4_1 = get_bitfield(imm, 4, 1)
  inst = set_bitfield(inst, imm_4_1, 11, 8)
  inst = set_bitfield(inst, funct3, 14, 12)
  inst = set_bitfield(inst, rs1, 19, 15)
  inst = set_bitfield(inst, rs2, 24, 20)
  imm_10_5 = get_bitfield(imm, 10, 5)
  inst = set_bitfield(inst, imm_10_5, 30, 25)
  imm_12 = get_bitfield(imm, 12, 12)
  inst = set_bitfield(inst, imm_12, 31, 31)
  global PC
  PC += 4
  return inst & U32_MAX

def BEQ(rs1, rs2, imm):
  return BType(0b110_0011, rs1, rs2, imm, 0b000)

def BNE(rs1, rs2, imm):
  return BType(0b110_0011, rs1, rs2, imm, 0b001)

def BLT(rs1, rs2, imm):
  return BType(0b110_0011, rs1, rs2, imm, 0b100)

def BGE(rs1, rs2, imm):
  return BType(0b110_0011, rs1, rs2, imm, 0b101)

def BLTU(rs1, rs2, imm):
  return BType(0b110_0011, rs1, rs2, imm, 0b110)

def BGEU(rs1, rs2, imm):
  return BType(0b110_0011, rs1, rs2, imm, 0b111)


# #########################################################
# UType
# LUI and AUIPC
# #########################################################
def UType(opcode, rd, imm):
  inst = 0
  inst = set_bitfield(inst, opcode, 6, 0)
  inst = set_bitfield(inst, rd, 11, 7)
  imm_31_12 = get_bitfield(imm, 31, 12)
  inst = set_bitfield(inst, imm_31_12, 31, 12)
  global PC
  PC += 4
  return inst & U32_MAX

def LUI(rd, imm):
  return UType(0b011_0111, rd, imm)

def AUIPC(rd, imm):
  return UType(0b001_0111, rd, imm)


# #########################################################
# Load instructions
# #########################################################
def LB(rd, rs1, imm):
  return IType(0b000_0011, rd, rs1, imm, 0b000)

def LH(rd, rs1, imm):
  return IType(0b000_0011, rd, rs1, imm, 0b001)

def LW(rd, rs1, imm):
  return IType(0b000_0011, rd, rs1, imm, 0b010)

def LBU(rd, rs1, imm):
  return IType(0b000_0011, rd, rs1, imm, 0b100)

def LHU(rd, rs1, imm):
  return IType(0b000_0011, rd, rs1, imm, 0b101)


# #########################################################
# Store instructions
# #########################################################
def SType(opcode, rs1, rs2, imm, funct3):
  inst = 0
  inst = set_bitfield(inst, opcode, 6, 0)
  imm_4_0 = get_bitfield(imm, 4, 0)
  inst = set_bitfield(inst, imm_4_0, 11, 7)
  inst = set_bitfield(inst, funct3, 14, 12)
  inst = set_bitfield(inst, rs1, 19, 15)
  inst = set_bitfield(inst, rs2, 24, 20)
  imm_11_5 = get_bitfield(imm, 11, 5)
  inst = set_bitfield(inst, imm_11_5, 31, 25)
  global PC
  PC += 4
  return inst & U32_MAX

def SB(rs1, rs2, imm):
  return SType(0b010_0011, rs2, rs1, imm, 0b000)

def SH(rs1, rs2, imm):
  return SType(0b010_0011, rs2, rs1, imm, 0b001)

def SW(rs1, rs2, imm):
  return SType(0b010_0011, rs2, rs1, imm, 0b010)


# #########################################################
# EBREAK
# #########################################################
def ECALL():
  inst = 0
  inst = set_bitfield(inst, 0b111_0011, 6, 0)
  inst = set_bitfield(inst, 0b0_0000, 11, 7)
  inst = set_bitfield(inst, 0b000, 14, 12)
  inst = set_bitfield(inst, 0b0_0000, 19, 15)
  inst = set_bitfield(inst, 0b0000_0000_0000, 31, 20)
  global PC
  PC += 4
  return inst & U32_MAX

def EBREAK():
  inst = 0
  inst = set_bitfield(inst, 0b111_0011, 6, 0)
  inst = set_bitfield(inst, 0b0_0000, 11, 7)
  inst = set_bitfield(inst, 0b000, 14, 12)
  inst = set_bitfield(inst, 0b0_0000, 19, 15)
  inst = set_bitfield(inst, 0b0000_0000_0001, 31, 20)
  global PC
  PC += 4
  return inst & U32_MAX


# #########################################################
# Test
# #########################################################
import pytest

def test_set_bitfield():
  val = 0xAB00
  bf = 0xCD
  assert set_bitfield(val, bf, 7, 0) == 0xABCD

def test_get_bitfield():
  val = 0xABCD
  assert get_bitfield(val, 11, 4) == 0xBC

if __name__ == "__main__":
  pytest.main("-s riscv_assembler.py")
