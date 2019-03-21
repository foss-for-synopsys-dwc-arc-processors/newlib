/*
 * qemu-stub.c -- stubs for default qemu simulator
 *
 *
 * The authors hereby grant permission to use, copy, modify,
 * distribute, and license this software and its documentation for any
 * purpose, provided that existing copyright notices are retained in
 * all copies and that this notice is included verbatim in any
 * distributions. No written agreement, license, or royalty fee is
 * required for any of the authorized uses.  Modifications to this
 * software may be copyrighted by their authors and need not follow
 * the licensing terms described here, provided that the new terms are
 * clearly indicated on the first page of each file where they apply.
 */
#include <sys/stat.h>
#include <errno.h>
#include <sys/times.h>

void
__attribute__((noreturn))
_exit (int ret)
{
  volatile unsigned int * const PWRDR = (unsigned int *) 0xf0000008;
  volatile unsigned int * const UARTDR = (unsigned int *) 0x90000000;

  *UARTDR = (ret) ? 0x31 : 0x30;

  while (1)
    {
      *PWRDR = 1;
    }
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

_ssize_t _read(int fd, void *buffer, unsigned int count)
{
  return 0;
}

int _open (char *file, int flags, int mode)
{
  return -1;
}

clock_t
_times (struct tms *buf)
{
  errno = ENOSYS;
  return -1;
}
