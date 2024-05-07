/*
 * Copyright (C) 2020 Embecosm Limited
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <machine/syscall.h>
#include "semihost_syscall.h"

#define ADP_Stopped_ApplicationExit 0x20026

/* Exit a program without cleaning up files.  */
void
_exit (int exit_status)
{
  /* SYS_EXIT_EXTENDED semihosting call allows exiting with an exit code both
     on 32-bit and 64-bit targets. However, it's not available in the first
     version of the semihosting specification. Since the first version is
     pretty old, it may be assumed that semihosting v2 is available and
     SYS_EXIT_EXTENDED may be used.

     TODO: Implement a mechanism for detecting semihosting features like it's
     done in libsemihosting for ARM.  */
  long data_block[] = {ADP_Stopped_ApplicationExit, exit_status};
  syscall_errno (SEMIHOST_exit_extended, data_block);
  while (1);
}
