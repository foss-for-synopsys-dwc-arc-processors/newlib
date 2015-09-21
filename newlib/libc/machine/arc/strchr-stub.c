/* Copyright (C) 2015 Synopsys, Inc.
   This file is free software; you can redistribute it and/or modify
   it under the same terms as newlib/libc/string/strchr.c .  */

#if defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)
# include "../../string/strchr.c"
#else
/* See strchr-*.S  */
#endif
