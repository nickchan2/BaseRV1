#ifndef LOGGING_H
#define LOGGING_H

#include <stdio.h>

#define ENABLE_LOGGING (1)

#if ENABLE_LOGGING
    #define rv_Log(...) (printf(__VA_ARGS__))
#else
    #define rv_Log(...) do {} while (0)
#endif

#endif /* LOGGING_H */
