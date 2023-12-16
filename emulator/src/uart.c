/* ----------------------------------------------------------------------------
 * Includes
 * ------------------------------------------------------------------------- */

#include <stdio.h>
#include <pthread.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <assert.h>

#include "uart.h"

/* ----------------------------------------------------------------------------
 * Private Global Varaibles
 * ------------------------------------------------------------------------- */

static struct uart {
    uint8_t rx_data;
    uint8_t rx_ready;
    uint8_t tx_data;
    uint8_t tx_busy;
} uart;

static pthread_mutex_t rx_mutex;
static pthread_mutex_t tx_mutex;

static int active = 0;

static pthread_t printing_thread_id;
static pthread_t rx_thread_id;

/* ----------------------------------------------------------------------------
 * Private Function Prototypes
 * ------------------------------------------------------------------------- */

// static void *rv_PrintingThread(void *arg);

static void *rv_RxThread(void *arg);

/* ----------------------------------------------------------------------------
 * Private Function Definitions
 * ------------------------------------------------------------------------- */

static void *rv_PrintingThread(void *arg) {
    uint8_t saved_tx;

    while (1) {
        if (!active) {
            break;
        }

        /* Check for tx data */
        pthread_mutex_lock(&tx_mutex);
        if (uart.tx_busy) {
            saved_tx = uart.tx_data;
            pthread_mutex_unlock(&tx_mutex);

            printf("%C", (char)saved_tx);
            fflush(stdout);

            /* Indicate that printing is done */
            pthread_mutex_lock(&tx_mutex);
            uart.tx_busy = 0U;
            pthread_mutex_unlock(&tx_mutex);
        }
        else {
            pthread_mutex_unlock(&tx_mutex);
        }
    }

    return NULL;
}

static void *rv_RxThread(void *arg) {
    char c;

    while (1) {
        c = getchar();
        pthread_mutex_lock(&rx_mutex);
        uart.rx_ready = 1;
        uart.rx_data = (uint8_t)c;
        pthread_mutex_unlock(&rx_mutex);

        printf("Got char %c\n", c);
        // if (!active) {
        //     break;
        // }

        // if (read(STDIN_FILENO, &c, 1) > 0) {
        //     pthread_mutex_lock(&rx_mutex);
        //     uart.rx_ready = 1U;
        //     uart.rx_data = (uint8_t)c;
        //     pthread_mutex_unlock(&rx_mutex);
        // }
    }

    return NULL;
}

/* ----------------------------------------------------------------------------
 * Public Function Definitions
 * ------------------------------------------------------------------------- */

void rv_InitUART(void) {
    /* Return if already initialized */
    if (active) {
        return;
    }

    active = 1;

    /* Clear UART register structure*/
    memset((void *)&uart, 0, sizeof(uart));

    /* Turn off canonical mode and echo */
    struct termios term_settings;
    tcgetattr(STDIN_FILENO, &term_settings);
    term_settings.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &term_settings);

    /* Initialize mutexes */
    pthread_mutex_init(&rx_mutex, NULL);
    pthread_mutex_init(&tx_mutex, NULL);

    /* Create thread for printing */
    // pthread_create(&printing_thread_id, NULL, rv_PrintingThread, NULL);

    /* Create rx thread */
    pthread_create(&rx_thread_id, NULL, rv_RxThread, NULL);
}

void rv_UninitUART(void) {
    /* Return if not initialized */
    if (!active) {
        return;
    }

    active = 0;

    /* Join threads */
    pthread_join(printing_thread_id, NULL);
    pthread_join(rx_thread_id, NULL);

    /* Destroy mutexes */
    pthread_mutex_destroy(&rx_mutex);
    pthread_mutex_destroy(&tx_mutex);
}

uint8_t rv_UARTRead(uint8_t addr) {
    assert(active);
    assert(addr <= 0b11);

    uint8_t read_data = 0;

    switch (addr) {
        case 0b00U:
            pthread_mutex_lock(&rx_mutex);
            uart.rx_ready = 0;
            read_data = uart.rx_data;
            pthread_mutex_unlock(&rx_mutex);
            break;
        case 0b01U:
            pthread_mutex_lock(&rx_mutex);
            read_data = uart.rx_ready;
            pthread_mutex_unlock(&rx_mutex);
            break;
        case 0b11U:
            pthread_mutex_lock(&tx_mutex);
            read_data = uart.tx_busy;
            pthread_mutex_unlock(&tx_mutex);
            break;
        default:
            break;
    }

    return read_data;
}

void rv_UARTWrite(uint8_t addr, uint8_t write_data) {
    assert(active);
    assert(addr <= 0b11);

    if ((addr == 0b10) && (uart.tx_busy == 0)) {
        printf("%c",(char)write_data);
        // pthread_mutex_lock(&tx_mutex);
        // uart.tx_busy = 1U;
        // uart.tx_data = write_data;
        // pthread_mutex_unlock(&tx_mutex);
    }
}
