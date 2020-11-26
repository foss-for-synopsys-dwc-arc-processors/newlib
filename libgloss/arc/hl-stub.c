/*
 * hl-stub.c -- provide _kill() and _getpid().
 *
 * Copyright (c) 2021 Synopsys Inc.
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 *
 */

#include <sys/times.h>
#include <errno.h>
#include <unistd.h>

#include "glue.h"


/* If PID is equal to __MYPID, exit with sig as retcode.  */
int
_kill (int pid, int sig)
{
  if (pid == __MYPID)
    _exit (sig);

  errno = ENOSYS;
  return -1;
}


/* Return __MYPID.  */
int
_getpid (void)
{
  return __MYPID;
}
