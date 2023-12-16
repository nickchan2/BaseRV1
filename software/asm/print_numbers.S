/*
 * File:    print_numbers.S
 * Brief:   TODO
 * 
 * Copyright (C) 2023 Nick Chan
 * See the LICENSE file at the root of the project for licensing info.
*/

	li		a0, 0x30000002	# uart_tx_data address
    li		a1, 10			# for loop branch value
    li		a2, 0x30		# ascii number base

repeat:
	li		t1, 0			# reset for loop counter
for:

	li		t0, 50000000	# set the delay counter
delay:
	addi	t0, t0, -1
    bne		t0, zero, delay
    
    add		t0, t1, a2
    
    sb		t0, 0(a0)
    
    addi	t1, t1, 1
    bne		t1, a1, for

	j		repeat
    