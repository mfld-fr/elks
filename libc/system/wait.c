#include <sys/types.h>
#include <sys/wait.h>

pid_t
wait(int * status)
{
   return wait4(-1, status, 0, (void*)0);
}
