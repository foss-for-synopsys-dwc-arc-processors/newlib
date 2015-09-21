/* Copyright (C) 2015 Synopsys, Inc.
   This file is free software; you can redistribute it and/or modify
   it under the same terms as newlib/libc/string/strncpy.c .  */

#if defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)
# include "../../string/strncpy.c"
#else
/* See strncpy-*.S  */
#endif
