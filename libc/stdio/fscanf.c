#include "_stdio.h"

int
fscanf(FILE * fp, const char * fmt, ...)
{
  va_list ptr;
  int rv;

  va_strt(ptr, fmt);
  rv = vfscanf(fp, (char *)fmt, ptr);
  va_end(ptr);

  return rv;
}
