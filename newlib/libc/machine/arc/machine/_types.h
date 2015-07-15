/*
   Copyright (C) 2015 Synopsys, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the same terms as newlib/libc/include/sys/_types.h.
 */

#ifndef _MACHINE__TYPES_H
#define _MACHINE__TYPES_H

#include <machine/_default_types.h>

/* Why ARC needs __dev_t to be long? The answer has been lost in time, as this
 * change was done by Joern in 2007, and the respective source control commit
 * is lost - both GitHub and older ARC SVN include this as "import newlib for
 * ARC" single commit. ChangeLog.ARC entry is pretty much useless, as it
 * doesn't explain _why_ type should be long. My blind guess based on nothing
 * is that the goal is to have this type equal to register size of 32bits... */
#define __dev_t_defined
typedef long __dev_t;

#endif /* _MACHINE__TYPES_H */
