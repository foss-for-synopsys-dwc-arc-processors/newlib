/* Copyright (C) 2007, 2011, 2015 Free Software Foundation, Inc.
   This file is free software; you can redistribute it and/or modify
   it under the same terms as newlib/libc/string/memcpy.c .  */

/* This implementation is optimized for performance.  For code size a generic
   implementation of this function from newlib/libc/string/memcpy.c will be
   used.  */
#if !defined (__OPTIMIZE_SIZE__) && !defined (PREFER_SIZE_OVER_SPEED)

#include "asm.h"

#ifdef __ARC601__
/* Adapted from memcpy-700.S.  */
/* We assume that most sources and destinations are aligned, and
   that also lengths are mostly a multiple of four, although to a lesser
   extent.  */
ENTRY(memcpy)
	or	r3,r0,r1
	bmsk.f	0,r3,1
	breq_s	r2,0,.Lnil
	mov_s	r5,r0
	bne.d	.Lcopy_bytewise
	add	r6,r0,r2
	sub_s	r3,r2,1
	ld_s	r12,[r1,0]
	bbit0.d	r3,2,.Lnox4
	sub	r6,r6,8
	st.ab	r12,[r5,4]
	ld.a	r12,[r1,4]
.Lnox4:
	brlo	r2,9,.Lendloop
.Lnox4a:
	ld_s	r3,[r1,4]
	st.ab	r12,[r5,8]
	ld.a	r12,[r1,8]
	brlo.d	r5,r6,.Lnox4a
	st	r3,[r5,-4]
.Lendloop:
#ifdef __LITTLE_ENDIAN__
	ld	r3,[r5,0]
	add3	r2,-1,r2
	; uses long immediate
	xor_s	r12,r12,r3
	bmsk	r12,r12,r2
	xor_s	r12,r12,r3
#else /* BIG ENDIAN */
	bmsk_s  r2,r2,1
	breq_s  r2,0,.Last_store
	ld	r3,[r5,0]
	sub3	r2,31,r2
	; uses long immediate
	xor_s	r3,r3,r12
	bmsk	r3,r3,r2
	xor_s	r12,r12,r3
#endif /* ENDIAN */
.Last_store:
	j_s.d	[blink]
	st	r12,[r5,0]

.Lnil:
	j_s	[blink]
	.balign	4
.Lcopy_bytewise:
	ldb_s	r12,[r1,0]
	bbit1.d	r2,0,.Lnox1
	sub	r6,r6,2
	stb.ab	r12,[r5,1]
	ldb.a	r12,[r1,1]
.Lnox1:
	brlo	r2,3,.Lendbloop
.Lnox1a:
	ldb_s	r3,[r1,1]
	stb.ab	r12,[r5,2]
	ldb.a	r12,[r1,2]
	brlo.d	r5,r6,.Lnox1a
	stb	r3,[r5,-1]
.Lendbloop:
	j_s.d	[blink]
	stb	r12,[r5,0]
ENDFUNC(memcpy)
#endif /* __ARC601__ */

#endif /* !__OPTIMIZE_SIZE__ && !PREFER_SIZE_OVER_SPEED */
