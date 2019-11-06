ENTRY(_reset)
OUTPUT_FORMAT("elf32-littleriscv")

MEMORY {
    rom : ORIGIN = 0x00000000, LENGTH = 64
}

SECTIONS
{
    .text :
    {
        *(.text .text.*)
    } > rom
}
