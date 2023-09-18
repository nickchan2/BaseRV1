#ifndef UART_H
#define UART_H

/* ----------------------------------------------------------------------------
 * Includes
 * ------------------------------------------------------------------------- */

#include <stdlib.h>

/* ----------------------------------------------------------------------------
 * Public Function Prototypes
 * ------------------------------------------------------------------------- */

/**
 * @brief       Initialize the UART.
*/
void rv_InitUART(void);

/**
 * @brief       Un-initialize the UART.
*/
void rv_UninitUART(void);

/**
 * @brief       Read from the UART.
 * @param[in]   addr The address to read from. Valid addresses are 0b00 to 0b11
 *              inclusive.
 * @return      The value that was read. 0 is returned if the address was
 *              invalid.
*/
uint8_t rv_UARTRead(uint8_t addr);

/**
 * @brief       Write to the UART.
 * @param[in]   addr The address to write to. Valid addresses are 0b00 to 0b11
 *              inclusive.
 * @param[in]   write_data The data to write.
*/
void rv_UARTWrite(uint8_t addr, uint8_t write_data);

#endif /* UART_H */
