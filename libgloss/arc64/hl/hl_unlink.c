/*
 * hl_unlink.c -- provide _unlink().
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

#include <errno.h>
#include <stdint.h>
#include <unistd.h>

#include "hl_toolchain.h"
#include "hl_api.h"


/* Unlink host file.  Implements HL_SYSCALL_UNLINK.  */
static __always_inline int
_hl_unlink (const char *path)
{
  int32_t ret;
  uint32_t host_errno;
  volatile __uncached char *p;

  p = _hl_message (HL_SYSCALL_UNLINK, "s:ii",
		   path,			/* s */
		   (uint32_t *) &ret,		/* :i */
		   (uint32_t *) &host_errno	/* :i */);

  if (p == NULL)
    {
      errno = ETIMEDOUT;
      ret = -1;
    }
  else if (ret < 0)
    {
      errno = host_errno;
      ret = -1;
    }

  _hl_delete ();

  return ret;
}

int
_unlink (const char *path)
{
  return _hl_unlink (path);
}
