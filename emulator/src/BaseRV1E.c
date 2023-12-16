/**
 * @file    BaseRV1E.c
 * @brief   Source file for the emulator
 * 
 * @copyright (C) 2023 Nick Chan
 * See the LICENSE file at the root of the project for licensing info.
*/

/* ----------------------------------------------------------------------------
 * Private Includes
 * ------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "BaseRV1E.h"
#include "uart.h"

/* ----------------------------------------------------------------------------
 * Private Symbolic Constants
 * ------------------------------------------------------------------------- */

/* The system starts by executing code from the Boot ROM */
#define PC_START_ADDRESS        (MREGION_START_BOOT_ROM)

#define RAM_SIZE                (0x800U)

#define MREGION_START_RAM       (0x00000000U)
#define MREGION_END_RAM         (MREGION_START_RAM + RAM_SIZE - 1)

#define MREGION_START_BOOT_ROM  (0x10000000U)
#define MREGION_END_BOOT_ROM    (0x1000003FU)

#define MREGION_START_UART      (0x30000000U)
#define MREGION_END_UART        (0x30000003U)

#define MREGION_TIMER           (0x20000000U)

/* The position of the funct3 field in RISC-V instructions */
#define FUNCT3_Pos              (12U)

/* ----------------------------------------------------------------------------
 * Private Macros
 * ------------------------------------------------------------------------- */

#define rv_Log(...) do { \
    FILE *fd = fopen("rv_log.txt", "a"); \
    fseek(fd, 0, SEEK_END); \
    fprintf(logfile, __VA_ARGS__); \
    fclose(fd); \
} while (0);

#define STORE_MISALIGNED(addr, funct3) \
    ( (((funct3) == ) && ((addr) & 0b1)) || \
      (((funct3) == DT_WORD) && ((addr) & 0b11)) )

#define FIELD_OPCODE(i)         ((rv_opcode_t)((i) & 0b1111111))
#define FIELD_RS1(i)            ((reg_sel_t)(((i) >> 15U) & 0b11111U))
#define FIELD_RS2(i)            ((reg_sel_t)(((i) >> 20U) & 0b11111U))
#define FIELD_RD(i)             ((reg_sel_t)(((i) >> 7U) & 0b11111U))

#define FIELD_FUNCT3(i)         ((i) & (0b111 << FUNCT3_Pos))
#define FIELD_FUNCT3_OP(i)      ((rv_funct3_op_t)FIELD_FUNCT3(i))
#define FIELD_FUNCT3_BRANCH(i)  ((rv_funct3_branch_t)FIELD_FUNCT3(i))
#define FIELD_FUNCT3_LOAD(i)    ((rv_funct3_load_t)FIELD_FUNCT3(i))
#define FIELD_FUNCT3_STORE(i)   ((rv_funct3_store_t)FIELD_FUNCT3(i))

/* For instructions with the OP or OP-IMM opcodes, bit 30 of the instruction
 * sometimes encodes a special operation */
#define SPECIAL_OP(i)           ((i) & 0x40000000)

/* Immediate value for I-type instructions */
#define IMMEDIATE_I(i)  ((word_t)( (int32_t)(i) >> 20 ))

/* Immediate value for S-type instructions */
#define IMMEDIATE_S(i)  ((word_t)( (((int32_t)(i) >> 20) & ~0b11111) | \
                                   (((i) >> 7) & 0b11111) ))

/* Immediate value for B-type instructions */
#define IMMEDIATE_B(i)  ((word_t)( (((int32_t)(i) >> 20) & ~0b100000011111) | \
                                   (((i) << 4) & 0x800) | \
                                   (((i) >> 7) & 0b11110) ))

/* Immediate value for U-type instructions */
#define IMMEDIATE_U(i)  ((word_t)( (i) & 0xFFFFF000 ))

/* Immediate value for J-type instructions */
#define IMMEDIATE_J(i)  ((word_t)( (((int32_t)(i) >> 20) & 0xFFF007FE) | \
                                   ((i) & 0xFF000) | \
                                   (((i) >> 9) & 0x800) ))

/* ----------------------------------------------------------------------------
 * Private Types
 * ------------------------------------------------------------------------- */

typedef union {
    int32_t     s;
    uint32_t    u;
} word_t;

typedef enum {
    RV_EXCEPTION_NONE,
    RV_EXCEPTION_MISALIGNED,
    RV_EXCEPTION_ADDRESS_MISALIGNED,
    RV_EXCEPTION_INSTRUCTION_ADDRESS_MISALIGNED,
    RV_EXCEPTION_ACCESS_FAULT,
    RV_EXCEPTION_ILLEGAL_INSTRUCTION
} rv_exception_t;

typedef enum {
    OPCODE_OP       = 0b0110011, OPCODE_OP_IMM   = 0b0010011,
    OPCODE_LUI      = 0b0110111, OPCODE_AUIPC    = 0b0010111,
    OPCODE_JAL      = 0b1101111, OPCODE_JALR     = 0b1100111,
    OPCODE_BRANCH   = 0b1100011, OPCODE_LOAD     = 0b0000011,
    OPCODE_STORE    = 0b0100011, OPCODE_MISC_MEM = 0b0001111,
    OPCODE_SYSTEM   = 0b1110011
} rv_opcode_t;

typedef enum {
    FUNCT3_OP_ADD   = 0b000 << FUNCT3_Pos,
    FUNCT3_OP_SLL   = 0b001 << FUNCT3_Pos,
    FUNCT3_OP_SLT   = 0b010 << FUNCT3_Pos,
    FUNCT3_OP_SLTU  = 0b011 << FUNCT3_Pos,
    FUNCT3_OP_XOR   = 0b100 << FUNCT3_Pos,
    FUNCT3_OP_SRx   = 0b101 << FUNCT3_Pos,
    FUNCT3_OP_OR    = 0b110 << FUNCT3_Pos,
    FUNCT3_OP_AND   = 0b111 << FUNCT3_Pos
} rv_funct3_op_t;

typedef enum {
    FUNCT3_BEQ  = 0b000 << FUNCT3_Pos,
    FUNCT3_BNE  = 0b001 << FUNCT3_Pos,
    FUNCT3_BLT  = 0b100 << FUNCT3_Pos,
    FUNCT3_BGE  = 0b101 << FUNCT3_Pos,
    FUNCT3_BLTU = 0b110 << FUNCT3_Pos,
    FUNCT3_BGEU = 0b111 << FUNCT3_Pos
} rv_funct3_branch_t;

typedef enum {
    FUNCT3_LOAD_SIGNED_BYTE         = 0b000 << FUNCT3_Pos,
    FUNCT3_LOAD_SIGNED_HALFWORD     = 0b001 << FUNCT3_Pos,
    FUNCT3_LOAD_WORD                = 0b010 << FUNCT3_Pos,
    FUNCT3_LOAD_UNSIGNED_BYTE       = 0b100 << FUNCT3_Pos,
    FUNCT3_LOAD_UNSIGNED_HALFWORD   = 0b101 << FUNCT3_Pos
} rv_funct3_load_t;

typedef enum {
    FUNCT3_STORE_BYTE       = 0b000 << FUNCT3_Pos,
    FUNCT3_STORE_HALFWORD   = 0b001 << FUNCT3_Pos,
    FUNCT3_STORE_WORD       = 0b010 << FUNCT3_Pos,
} rv_funct3_store_t;

typedef uint32_t reg_sel_t;

/* ----------------------------------------------------------------------------
 * Private Function Declarations
 * ------------------------------------------------------------------------- */

static void rv_MainLoop(void);

static void rv_LoadProgram(const char *fn);

static rv_exception_t rv_DecodeAndExecute(void);

static rv_exception_t rv_Fetch(word_t addr);

static rv_exception_t rv_Load(uint32_t addr, rv_funct3_load_t funct3);

static rv_exception_t rv_Store(uint32_t addr, rv_funct3_store_t funct3, word_t write_data);

static word_t rv_GetRegVal(reg_sel_t reg_sel);

static void rv_SetRegVal(reg_sel_t reg_sel, word_t write_data);

/* ----------------------------------------------------------------------------
 * Private Global Variables
 * ------------------------------------------------------------------------- */

static word_t rf[31];
static word_t pc;
static uint32_t instruction;
static uint8_t *memory;
static word_t loaded;
static FILE *logfile;

static const uint32_t boot_rom[16] = {
    0x300005b7, 0x00000613, 0x028000ef, 0x00050293,
    0x020000ef, 0x00851513, 0x00a282b3, 0x014000ef,
    0x00a60023, 0x00160613, 0xfe561ae3, 0x00000067,
    0x0015c503, 0xfe050ee3, 0x0005c503, 0x00008067
};

static uint64_t inst_cnt;

/* ----------------------------------------------------------------------------
 * Private Function Definitions
 * ------------------------------------------------------------------------- */

static void rv_MainLoop(void) {
    while (1) {
        rv_Log("Cnt: %2llu | ", inst_cnt);

        /* Fetch instruction */
        rv_exception_t exception_status = rv_Fetch(pc);

        /* Check for fetch exception */
        if (exception_status != RV_EXCEPTION_NONE) {
            return;
        }

        /* Decode and execute instruction */
        rv_DecodeAndExecute();

        ++inst_cnt;

        rv_Log("\n");

        sleep(1);
    }
}

static void rv_LoadProgram(const char *fn) {
    if (fn == NULL) {
        fn = "program.txt";
    }

    FILE *fd = fopen(fn, "rb");
    assert(fd != NULL);

    size_t midx = 0;
    uint8_t buf[16];
    size_t nread;
    while ((nread = fread(buf, 1, 16, fd))) {
        memcpy(memory + midx, buf, nread);
        midx += nread;
    }

    fclose(fd);
}

static rv_exception_t rv_DecodeAndExecute(void) {
    word_t result, op1, op2;
    rv_exception_t exception;
    uint32_t branch_taken;
    uint32_t addr;

    switch (FIELD_OPCODE(instruction)) {
        case OPCODE_OP:
            op1 = rv_GetRegVal(FIELD_RS1(instruction));
            op2 = rv_GetRegVal(FIELD_RS2(instruction));
            
            switch (FIELD_FUNCT3_OP(instruction)) {
                case FUNCT3_OP_ADD:  result.s = (SPECIAL_OP(instruction)) ? (op1.s - op2.s) : (op1.s + op2.s); break;
                case FUNCT3_OP_SLL:  result.u = op1.u << op2.u; break;
                case FUNCT3_OP_SLT:  result.u = (op1.s < op2.s); break;
                case FUNCT3_OP_SLTU: result.u = (op1.u < op2.u); break;
                case FUNCT3_OP_XOR:  result.u = op1.u ^ op2.u; break;
                case FUNCT3_OP_SRx:  result.u = (SPECIAL_OP(instruction)) ? (op1.s >> op2.u) : (op1.u >> op2.u); break;
                case FUNCT3_OP_OR:   result.u = op1.u | op2.u; break;
                case FUNCT3_OP_AND:  result.u = op1.u & op2.u; break;
                default: assert(0); break;
            }

            rv_SetRegVal(FIELD_RD(instruction), result);

            pc.u += 4U;
            break;

        case OPCODE_OP_IMM:
            op1 = rv_GetRegVal(FIELD_RS1(instruction));
            op2 = IMMEDIATE_I(instruction);
            
            switch (FIELD_FUNCT3_OP(instruction)) {
                case FUNCT3_OP_ADD:  result.s = op1.s + op2.s; break;
                case FUNCT3_OP_SLL:  result.u = op1.u << op2.u; break;
                case FUNCT3_OP_SLT:  result.u = (op1.s < op2.s); break;
                case FUNCT3_OP_SLTU: result.u = (op1.u < op2.u); break;
                case FUNCT3_OP_XOR:  result.u = op1.u ^ op2.u; break;
                case FUNCT3_OP_SRx:  result.u = (SPECIAL_OP(instruction)) ? (op1.s >> op2.u) : (op1.u >> op2.u); break;
                case FUNCT3_OP_OR:   result.u = op1.u | op2.u; break;
                case FUNCT3_OP_AND:  result.u = op1.u & op2.u; break;
                default: assert(0); break;
            }

            rv_SetRegVal(FIELD_RD(instruction), result);

            pc.u += 4;
            break;

        case OPCODE_LUI:
            /* rd <= immU */
            rv_SetRegVal(FIELD_RD(instruction), IMMEDIATE_U(instruction));
            pc.u += 4;
            break;

        case OPCODE_AUIPC:
            /* rd <= pc + immU */
            rv_SetRegVal(FIELD_RD(instruction), (word_t)(pc.u + IMMEDIATE_U(instruction).u));
            pc.u += 4;
            break;

        case OPCODE_JAL:
            rv_Log("J immediate: %08x", IMMEDIATE_J(instruction).s);
            /* rd <= pc + 4 */
            rv_SetRegVal(FIELD_RD(instruction), (word_t)(pc.u + 4));
            /* pc <= pc + immJ */
            pc.s += IMMEDIATE_J(instruction).s;
            break;

        case OPCODE_JALR:
            /* rd <= pc + 4 */
            rv_SetRegVal(FIELD_RD(instruction), (word_t)(pc.u + 4));
            /* pc <= rs1 + immI */
            pc.u = rv_GetRegVal(FIELD_RS1(instruction)).u + IMMEDIATE_I(instruction).u;
            break;

        case OPCODE_BRANCH:
            op1 = rv_GetRegVal(FIELD_RS1(instruction));
            op2 = rv_GetRegVal(FIELD_RS2(instruction));

            switch (FIELD_FUNCT3_BRANCH(instruction)) {
                case FUNCT3_BEQ:  branch_taken = (op1.s == op2.s); rv_Log("BEQ | "); break;
                case FUNCT3_BNE:  branch_taken = (op1.s != op2.s); rv_Log("BNE | "); break;
                case FUNCT3_BLT:  branch_taken = (op1.s < op2.s);  rv_Log("BLT | "); break;
                case FUNCT3_BGE:  branch_taken = (op1.s >= op2.s); rv_Log("BGE | "); break;
                case FUNCT3_BLTU: branch_taken = (op1.u < op2.u);  rv_Log("BLTU | "); break;
                case FUNCT3_BGEU: branch_taken = (op1.u >= op2.u); rv_Log("BGEU | "); break;
                default: assert(0); break;
            }
            
            if (branch_taken) {
                rv_Log("Taken with immediate %d | ", IMMEDIATE_B(instruction).s);
                pc.s = pc.s + IMMEDIATE_B(instruction).s;
            }
            else {
                rv_Log("Not taken | ");
                pc.u += 4;
            }
            break;

        case OPCODE_LOAD:
            addr = rv_GetRegVal(FIELD_RS1(instruction)).u + IMMEDIATE_I(instruction).u;
            rv_Log("Load from 0x%08x | ", addr);
            /* rd <= mem[rs1 + immI] */
            exception = rv_Load(addr, FIELD_FUNCT3_LOAD(instruction));
            if (exception != RV_EXCEPTION_NONE) {
                return exception;
            }
            rv_SetRegVal(FIELD_RD(instruction), loaded);
            pc.u += 4;
            break;

        case OPCODE_STORE:
            /* mem[rs1 + immS] <= rs2 */
            exception = rv_Store(
                rv_GetRegVal(FIELD_RS1(instruction)).u + IMMEDIATE_S(instruction).u,
                FIELD_FUNCT3_STORE(instruction),
                rv_GetRegVal(FIELD_RS2(instruction))
            );
            if (exception != RV_EXCEPTION_NONE) {
                return exception;
            }
            pc.u += 4;
            break;

        case OPCODE_MISC_MEM:
            /* Fence is a nop */
            pc.u += 4;
            break;

        case OPCODE_SYSTEM:
            /* System instructions are a nop */
            pc.u += 4;
            break;

        default:
            /* Illegal opcode */
            return RV_EXCEPTION_ILLEGAL_INSTRUCTION;
    }

    return RV_EXCEPTION_NONE;
}

static rv_exception_t rv_Fetch(word_t addr) {
    rv_Log("Fetching from 0x%08x | ", pc.u);

    /* Check for misaligned fetch */
    if (addr.u & 0b11) {
        printf("PC 0x%08x caused a misaligned address instruction exception\n | ", addr.u);
        return RV_EXCEPTION_INSTRUCTION_ADDRESS_MISALIGNED;
    }

    switch (addr.u) {
        case MREGION_START_RAM ... MREGION_END_RAM:
            /* Fetch from RAM */
            instruction = *(uint32_t *)&memory[addr.u];
            break;

        case MREGION_START_BOOT_ROM ... MREGION_END_BOOT_ROM:
            /* Fetch from boot ROM */
            rv_Log("BTRM idx %2d | ", (addr.u >> 2) & 0b11111U);
            instruction = boot_rom[(addr.u >> 2) & 0b11111U];
            break;

        default:
            /* Raise an access-fault exception */
            rv_Log("Fetching from 0x%08x raised an access fault exception | ", addr.u);
            return RV_EXCEPTION_ACCESS_FAULT;
    }

    rv_Log("Instruction: 0x%08x | ", instruction);

    return RV_EXCEPTION_NONE;
}

static rv_exception_t rv_Load(uint32_t addr, rv_funct3_load_t funct3) {
    /* Check for misaligned data access */
    // if (DATA_ACCESS_MISALIGNED(addr, funct3)) {
    //     return RV_EXCEPTION_ADDRESS_MISALIGNED; // FIXME
    // }

    switch (addr) {
        case MREGION_START_RAM ... MREGION_END_RAM:
            switch (funct3) {
                case FUNCT3_LOAD_WORD:
                    loaded.s = *(int32_t *)&memory[addr];
                    break;
                case FUNCT3_LOAD_SIGNED_HALFWORD:
                    loaded.s = (int32_t)(*(int16_t *)&memory[addr]);
                    break;
                case FUNCT3_LOAD_SIGNED_BYTE:
                    loaded.s = (int32_t)(*(int8_t *)&memory[addr]);
                    break;
                case FUNCT3_LOAD_UNSIGNED_HALFWORD:
                    loaded.s = (int32_t)(*(uint16_t *)&memory[addr]);
                    break;
                case FUNCT3_LOAD_UNSIGNED_BYTE:
                    loaded.s = (int32_t)(*(uint8_t *)&memory[addr]);
                    break;
                default:
                    assert(0);
                    break;
            }
            break;

        case MREGION_TIMER:
            // TODO load from timer
            break;

        case MREGION_START_UART ... MREGION_END_UART:
            loaded.u = (uint32_t)rv_UARTRead((uint8_t)addr);
            rv_Log("0x%08X from UART | ", loaded.u);
            break;

        default:
            /* Raise an access-fault exception */
            return RV_EXCEPTION_ACCESS_FAULT;
    }

    return RV_EXCEPTION_NONE;
}

static rv_exception_t rv_Store(uint32_t addr, rv_funct3_store_t funct3, word_t write_data) {
    /* Check for misaligned data access */
    // if (DATA_ACCESS_MISALIGNED(addr, funct3)) {
    //     return RV_EXCEPTION_ADDRESS_MISALIGNED; // TODO
    // }

    switch (addr) {
        case MREGION_START_RAM ... MREGION_END_RAM:
            switch (funct3) {
                case FUNCT3_STORE_WORD:
                    *(uint32_t *)&memory[addr] = write_data.u;
                    break;
                case FUNCT3_STORE_HALFWORD:
                    *(uint16_t *)&memory[addr] = (uint16_t)write_data.u;
                    break;
                case FUNCT3_STORE_BYTE:
                    *(uint8_t *)&memory[addr] = (uint8_t)write_data.u;
                    break;
                default:
                    break;
            }
            break;
        case MREGION_TIMER:
            // TODO what to do when tryting to write to timer?
            break;
        case MREGION_START_UART ... MREGION_END_UART:
            rv_UARTWrite((uint8_t)addr, (uint8_t)write_data.u);
            break;
        default:
            /* Raise an access-fault exception */
            return RV_EXCEPTION_ACCESS_FAULT;
    }

    return RV_EXCEPTION_NONE; 
}

static word_t rv_GetRegVal(reg_sel_t reg_sel) {
    assert(reg_sel <= 32);
    return (reg_sel) ? rf[reg_sel + 1] : (word_t)0;
}

static void rv_SetRegVal(reg_sel_t reg_sel, word_t write_data) {
    assert(reg_sel <= 32);
    if (reg_sel) {
        rf[reg_sel + 1] = write_data;
    }
}

/* ----------------------------------------------------------------------------
 * Public Function Definitions
 * ------------------------------------------------------------------------- */

void BRV1E_Run(const char *mem_image) {
    logfile = fopen("rv_log.txt", "w");
    fclose(logfile);

    /* Initialize UART */
    rv_InitUART();

    /* Allocate memory for RAM */
    memory = malloc(RAM_SIZE);
    assert(memory != NULL);

    rv_LoadProgram(mem_image);

    /* Initialize the PC */
    pc.u = PC_START_ADDRESS;

    /* Reset the instruction count */
    inst_cnt = 0;

    rv_Log("Emulator started\n");

    /* Emulator main loop */
    rv_MainLoop();

    rv_Log("Exiting emulator\n");

    /* Free RAM memory */
    free(memory);
    memory = NULL;

    /* Un-initialize the UART */
    // rv_UninitUART();
}
