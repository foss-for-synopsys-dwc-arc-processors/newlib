/*
 * Copyright (C) 2020 Embecosm Limited
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <machine/syscall.h>
#include "semihost_syscall.h"
#include "semihost_fdtable.h"

#ifndef RISCV_MAX_OPEN_FILES
#define RISCV_MAX_OPEN_FILES 16
#endif

extern int errno;
extern int _open (const char *, int, ...);

/* fdtable keeps track of the position of each file and is used to map stdin,
   stdout and stderr to STDIN_FILENO, STDOUT_FILENO and STDERR_FILENO.  */

static struct fdentry fdtable[RISCV_MAX_OPEN_FILES];

/* Initialize fdtable.  A handle of -1 denotes an empty entry.  */

static void __attribute__ ((used))
init_semihosting_fdtable ()
{
  int i;

  for (i=0; i<RISCV_MAX_OPEN_FILES; i++)
    fdtable[i].handle = -1;

  /* Set up std streams. Note that the semihost _open() call returns an index
     into the fdtable.  */
  /* stdin.  */
  i = _open (":tt", O_RDONLY);
  fdtable[STDIN_FILENO].handle = fdtable[i].handle;
  fdtable[STDIN_FILENO].pos = 0;

  /* stdout.  */
  i = _open (":tt", O_WRONLY|O_CREAT|O_TRUNC);
  fdtable[STDOUT_FILENO].handle = fdtable[i].handle;
  fdtable[STDOUT_FILENO].pos = 0;

  /* stderr.  */
  i = _open (":tt", O_WRONLY|O_CREAT|O_APPEND);
  fdtable[STDERR_FILENO].handle = fdtable[i].handle;
  fdtable[STDERR_FILENO].pos = 0;
}

/* Initialize command line arguments. We must do it here because symbols in
   this file are referenced in libc and the linker always pushes an
   object file for this source file to the final binary. Anyway, it would be
   wise to do all semihosting initializations in one place.  */

#ifndef RISCV_MAX_CMDLINE_LENGTH
#define RISCV_MAX_CMDLINE_LENGTH 1024
#endif

#ifndef RISCV_MAX_ARGV_LENGTH
#define RISCV_MAX_ARGV_LENGTH 64
#endif

int _argc = 0;
char *_argv[RISCV_MAX_ARGV_LENGTH] = { NULL };

static void __attribute__ ((used))
init_semihosting_args ()
{
  static char cmdline[RISCV_MAX_CMDLINE_LENGTH];
  long args[2] = { (long) cmdline, sizeof(cmdline) };
  long ret = syscall_errno(SEMIHOST_get_cmdline, args);
  char *ptr;

  /* Exit early if semihosting call failed or NULL buffer is returned.  */
  if (ret != 0 || (char *) args[0] == NULL) {
    return;
  }

  /* If a semihosting implementation returns another pointer to a command
     line buffer and does not reuse our own one then copy that explicitly.  */
  if (args[0] != (long) cmdline) {
    strcpy(cmdline, (const char *) args[0]);
  }

  ptr = cmdline;
  while (_argc < RISCV_MAX_ARGV_LENGTH - 1) {
    /* Skip leading whitespace characters.  */
    while (isspace(*ptr))
      ptr++;

    /* Finish if the end is reached.  */
    if (*ptr == '\0')
      break;

    /* An argument is found.  */
    _argv[_argc++] = ptr;

    /* Skip argument's characters.  */
    while (*ptr != '\0' && !isspace(*ptr))
      ptr++;

    /* Finish if the end is reached (again).  */
    if (*ptr == '\0')
      break;

    /* Cut out an argument in a command line.  */
    *ptr = '\0';
    ptr++;
  }
}

void __attribute__ ((constructor, used))
init_semihosting ()
{
  init_semihosting_fdtable();
  init_semihosting_args();
}

/* Add entry to fdtable.  */

int
__add_fdentry (int handle)
{
  for (int i=0; i<RISCV_MAX_OPEN_FILES; i++)
    if (fdtable[i].handle == -1)
      {
	fdtable[i].handle = handle;
	fdtable[i].pos = 0;
	return i;
      }
  /* Too many open files.  */
  errno = ENFILE;
  return -1;
}

/* Return the fdentry for file or NULL if not found.  */

struct fdentry *
__get_fdentry (int file)
{
  if (file<0 || file>=RISCV_MAX_OPEN_FILES || fdtable[file].handle == -1)
    {
      errno = EBADF;
      return NULL;
    }
  return &fdtable[file];
}

/* Remove entry from fdtable.  */

void
__remove_fdentry (int file)
{
  fdtable[file].handle = -1;
}
