#include <sys/stat.h>

/* Should be provided by crt0.S.  */
extern void __attribute__((noreturn)) _exit_halt ();

void
__attribute__((noreturn))
_exit (int ret)
{
  _exit_halt ();
}

int
_fstat (int fd, struct stat *buf)
{
    return 0;
}

int
_isatty (int fildes)
{
    return 1;
}

off_t
_lseek(int fd, off_t offset, int whence)
{
    return (off_t)0;
}

int
_close (int fd)
{
    return 0;
}

int
_kill (int pid, int sig)
{
    _exit (sig);
    return -1;
}

int
_getpid (void)
{
    return 1;
}
