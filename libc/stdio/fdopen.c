#include <stdio.h>

FILE *
fdopen(int file, char *mode)
{
   return __fopen((char*)0, file, (FILE*)0, mode);
}
