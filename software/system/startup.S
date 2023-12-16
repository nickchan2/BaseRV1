/*
 * File:    startup.S
 * Brief:   System startup
 * 
 * Copyright (C) 2023 Nick Chan
 * See the LICENSE file at the root of the project for licensing info.
*/

.global __reset

__reset:
    
    /* Zero fill BSS */
    li      t0, _sbss
    li      t1, _ebss
BSSLoopRepeat:
    beq     t0, t1, BSSLoopEnd
    sb      zero, 0(t0)
    addi    t0, t0, 1
    j       BSSLoopRepeat
BSSLoopEnd:

    # TODO static constructers

    call main
