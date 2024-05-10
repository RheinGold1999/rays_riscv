main.elf: main.o
		riscv64-unknown-elf-ld -T linker.ld -m elf32lriscv -nostdlib -no-relax main.o -o main.elf

main.o: main.S
		riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -mno-relax main.S -o main.o

main.S: main.c
		riscv64-unknown-elf-gcc -S main.c -o main.S -march=rv32i -mabi=ilp32  -nostdlib -mno-relax

clean::
		@rm -fr *.o
		@rm -fr *.elf
