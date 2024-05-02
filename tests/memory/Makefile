SIM ?= icarus
WAVES ?= 1

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/../../src/rtl/memory.v
TOPLEVEL = memory
MODULE = test_memory

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

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo '    for(int i =0; i < 32; i = i + 1) begin' >> $@
	echo '        $$dumpvars(0, $(TOPLEVEL).MEM[i]);' >> $@
	echo '    end' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst