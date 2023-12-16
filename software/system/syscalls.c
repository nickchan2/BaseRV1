
int _getpid(void)
{
    return 1;
}

int _kill(int, int)
{
    return -1;
}

void _exit(int)
{
    while (1) {}
}

int _read(int file, char *p, int len)
{
    
}
