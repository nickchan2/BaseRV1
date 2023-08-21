load_next_instr:
    li      t0,32               # reset the shift counter
    li      t2,0x00000000       # reset the loaded instruction register
load_next_byte:
    addi    t0, t0, -8          # decrement the shift counter
wait_for_rx:
    lbu     t1, 0(a0)           # load data_ready
    beqz    t1, wait_for_rx     # if data_ready is not set, try again

    lbu     t1, 0(a1)           # get the received byte

    sll     t1, t1, t0          # shift the byte into position
    or      t2, t2, t1          # save received byte to loaded instruction register

    bnez    t0, load_next_byte

    beqz    t2, done_loading    # If the instruction 0x00000000 is received, finish loading

    sw      t2, 0(a2)           # Otherwise, store the instruction to memory
    addi    a2, a2, 4           # Increment the instruction load pointer
    beqz    zero, load_next_instr

done_loading:
    jalr    zero, zero, 0       # jump to the program
