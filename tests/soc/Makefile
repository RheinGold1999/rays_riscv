SIM ?= icarus
WAVES ?= 1

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/../../src/rtl/soc.v
COMPILE_ARGS += -I$(shell pwd)/../../src/rtl/
TOPLEVEL = soc
MODULE = test_soc
MEM_INIT_FILE = $(shell pwd)/../software/hello_world/main.word.txt

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

iverilog_dump.v: $(MEM_INIT_FILE)
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '  $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '  $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo '  for (int i = 0; i < 32; i = i + 1) begin' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL).u_cpu.regfile_ra[i]);' >> $@
	echo '  end' >> $@
	echo 'end' >> $@
	echo '' >> $@

	# echo 'initial begin' >> $@
	# echo '  $$readmemh("$(MEM_INIT_FILE)", $(TOPLEVEL).u_memory.MEM);' >> $@
	# echo '  for (int i = 0; i < $(MEM_WORD_SIZE); i = i + 1) begin' >> $@
	# echo '    if ($(TOPLEVEL).u_memory.MEM[i] != 0) begin' >> $@
	# echo '      $$display("MEM[%d]=%h", i, $(TOPLEVEL).u_memory.MEM[i]);' >> $@
	# echo '      $$dumpvars(0, $(TOPLEVEL).u_memory.MEM[i]);' >> $@
	# echo '    end' >> $@
	# echo '  end' >> $@
	# echo 'end' >> $@

	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst