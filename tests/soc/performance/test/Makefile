SIM ?= icarus
WAVES ?= 1

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/../../../../src/rtl/soc.v
COMPILE_ARGS += -I$(shell pwd)/../../../../src/rtl/
TOPLEVEL = soc
MODULE = test_performance

ifeq ($(SIM), icarus)
	PLUSARGS += -fst
	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-BLKLOOPINIT 
	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst -trace-threads 2 
	endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

MEM_WORD_SIZE = 1024 * 1024

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '  $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '  $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo '  for (int i = 0; i < 32; i = i + 1) begin' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL).u_cpu.regfile_ra[i]);' >> $@
	echo '  end' >> $@
	echo 'end' >> $@
	echo '' >> $@
	echo 'endmodule' >> $@

log:
	grep "CPU" cocotb.log > cpu.log
	grep "UART" cocotb.log > uart_.log
	grep " RD" cocotb.log > csrrs.log

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst
	@rm -rf *.log
	@rm -rf *.xml