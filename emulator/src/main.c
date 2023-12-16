#include "BaseRV1E.h"

int main(int argc, char **argv) {
    BRV1E_Run((argc == 2) ? argv[1] : (void *)0);
    return 0;
}
