#include <machine/syscall.h>
#include "internal_syscall.h"

/* Remove a file's directory entry.  */
int
_unlink(const char *name)
{
  return syscall_errno (SYS_unlink, 1, (long int) name, 0, 0, 0, 0, 0);
}
