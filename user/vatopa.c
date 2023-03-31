#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int pid;
    int va;

    if (argc != 2 && argc != 3)
    {
        printf("Usage: vatopa virtual_address [pid]\n");
        return -1;
    }

    va = atoi(argv[1]);
    if (argc == 3)
    {
        pid = atoi(argv[2]);
    }
    else
    {
        pid = getpid();
    }

    printf("0x%x", va2pa(va, pid));
    return 0;
}