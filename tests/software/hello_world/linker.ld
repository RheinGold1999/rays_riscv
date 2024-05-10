MEMORY {
    PROGROM (RX) : ORIGIN = 0x000000, LENGTH = 0x100000   /* 2MB ROM*/
    DATARAM (RX) : ORIGIN = 0x100000, LENGTH = 0x100000   /* 2MB ROM*/
}

SECTIONS {
    .text : {
        . = ALIGN(4);
        main.o (.text)
        *(.text*)
    } > PROGROM

    .data : {
        . = ALIGN(4);
        *(.data*)
        *(.sdata*)
        *(.rodata*)
        *(.srodata*)
        *(.bss*)
        *(.sbss*)
    } > DATARAM
}