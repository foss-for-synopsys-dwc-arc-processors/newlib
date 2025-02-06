/*
 * Copyright (C) 2020 Embecosm Limited
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <machine/syscall.h>
#include "semihost_syscall.h"
#include "semihost_fdtable.h"
#include <errno.h>
#include <string.h>
#include <fcntl.h>

extern int errno;
extern int _close (int);

#define SEMIHOST_MODE_R 0
#define SEMIHOST_MODE_RPLUS 2
#define SEMIHOST_MODE_W 4
#define SEMIHOST_MODE_WPLUS 6
#define SEMIHOST_MODE_A 8
#define SEMIHOST_MODE_APLUS 10

/* Open a file.  */
int
_open (const char *name, int flags, ...)
{
  int fh;
  int mode;
  long data_block[3];

  /* Work out mode from flags.  */
  if ((flags & (O_RDONLY | O_WRONLY | O_RDWR)) == O_RDONLY)
    mode = SEMIHOST_MODE_R;
  else if ((flags & (O_WRONLY | O_CREAT | O_TRUNC))
	   == (O_WRONLY | O_CREAT | O_TRUNC))
    mode = SEMIHOST_MODE_W;
  else if ((flags & (O_WRONLY | O_CREAT | O_APPEND))
	   == (O_WRONLY | O_CREAT | O_APPEND))
    mode = SEMIHOST_MODE_A;
  else if ((flags & (O_WRONLY | O_CREAT | O_EXCL))
	   == (O_WRONLY | O_CREAT | O_EXCL))
    {
      /* Semihosting does not support O_EXCL flag. If
	 O_WRONLY | O_CREAT | O_EXCL combination is passed, then
	 we need to check existence of a file manually and emit
	 EEXIST error if it already exists. Otherwise, let
	 semihosting to open a file in SEMIHOST_MODE_W mode.  */
      fh = _open (name, O_RDONLY);
      if (fh != -1)
	{
	  _close (fh);
	  errno = EEXIST;
	  return -1;
	}
      mode = SEMIHOST_MODE_W;
    }
  else if ((flags & (O_RDWR | O_CREAT | O_TRUNC))
	   == (O_RDWR | O_CREAT | O_TRUNC))
    mode = SEMIHOST_MODE_WPLUS;
  else if ((flags & (O_RDWR | O_CREAT | O_APPEND))
	   == (O_RDWR | O_CREAT | O_APPEND))
    mode = SEMIHOST_MODE_APLUS;
  else if (flags & O_RDWR)
    mode = SEMIHOST_MODE_RPLUS;
  else
    {
      errno = EINVAL;
      return -1;
    }

  data_block[0] = (long) name;
  data_block[1] = mode;
  data_block[2] = strlen (name);
  fh = syscall_errno (SEMIHOST_open, data_block);
  /* Failed to open file.  */
  if (fh == -1)
    return -1;

  /* Register the file in the fdtable.  */
  return __add_fdentry (fh);
}
