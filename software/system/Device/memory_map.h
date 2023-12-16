/*
 * File:    memory_map.h
 * Brief:   The memory map
 * 
 * Copyright (C) 2023 Nick Chan
 * See the LICENSE file at the root of the project for licensing info.
*/

#ifndef MEMORY_MAP_H
#define MEMORY_MAP_H

#include "integer.h"

typedef struct __attribute__((packed))
{
    volatile u8 rx_data;
    volatile u8 rx_ready;
    volatile u8 tx_data;
    volatile u8 tx_busy;
} uart_t;

#define UART ((uart_t*)0x30000000)

typedef struct __attribute__((packed))
{
    volatile u32 in;
    volatile u32 out;
} gpio_t;

#define GPIO ((gpio_t*)0x00000000)

typedef struct __attribute__((packed))
{
    volatile u32   time;
    volatile u8    reset;
} timer_t;

#define TIMER ((timer_t*)0x20000000)

#endif  /* MEMORY_MAP_H */
