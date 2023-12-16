/*
 * File:    ram.ld
 * Brief:   TODO
 * 
 * Copyright (C) 2023 Nick Chan
 * See the LICENSE file at the root of the project for licensing info.
*/

ENTRY(__reset)

MEMORY
{
    ram (xrw) : ORIGIN = 0x00000000, LENGTH = 2048
}

SECTIONS
{
    .text : { *(.text) } >ram
    .bss :
    {
        ._sbss = .;
        *(.bss)
        ._ebss = .;
    }
}
