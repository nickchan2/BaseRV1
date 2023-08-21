/*
 * File:    bootloader.S
 * Brief:   Bootloader code
 * 
 * Copyright (C) 2023 Nick Chan
 * See the LICENSE file at the root of the project for licensing info.
*/

    li      a1, 0x30000000      # uart base address
    li      a2, 0x00000000      # Initialize the load pointer

# Get the byte count
    jal     wait_for_byte
    mv      t0, a0
    jal     wait_for_byte
    slli    a0, a0, 8
    add     t0, t0, a0

# Load data bytes to memory
next_byte:
    jal     wait_for_byte
    sb      a0, 0(a2)

    addi    a2, a2, 1           # Increment the load pointer
    bne     a2, t0, next_byte   # If not all bytes have been loaded, load the next byte

    jalr    zero, zero, 0       # Jump to the loaded program

wait_for_byte:
poll_again:
    lbu     a0, 1(a1)           # Load UART_DATA_READY
    beqz    a0, poll_again      # If data isn't ready, poll again
    lbu     a0, 0(a1)           # Load received byte
    ret                         # Return from subroutine
