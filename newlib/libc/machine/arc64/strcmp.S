/*
   Copyright (c) 2021, Synopsys, Inc. All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1) Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   2) Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

   3) Neither the name of the Synopsys, Inc., nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
*/

#include <sys/asm.h>

#if defined (__ARC64_ARCH32__)

ENTRY (strcmp)
	xor	r12, r12, r12

; Setup byte detector (more information bellow) [1]
	mov	r8, NULL_32DT_1
; Set r9 as a copy of r8 for vectorized sub
	mov	r9, r8
	
	asl	r13, r8, 7

.L_4_4B_search:

#if defined (__ARC64_LL64__)

	ldd.ab	r2r3, [r0, +8]

	ldd.ab	r4r5, [r1, +8]

#else

	ld.ab	r2, [r0, +4]
	ld.ab	r3, [r0, +4]

	ld.ab	r4, [r1, +4]
	ld.ab	r5, [r1, +4]

#endif

	vsub2	r10, r2, r8
	vsub2	r6, r4, r8

	bic	r10, r10, r2
	bic	r11, r11, r3
	bic	r6, r6, r4
	bic	r7, r7, r5

	; Look for difference
	sub.f	0, r2, r4
	bset.ne r12, r12, 2
	
	sub.f	0, r3, r5
	bset.ne r12, r12, 1


	; Look for NULL byte
	and.f	r10, r10, r13
	bset.ne	r12, r12, 2

	and.f	r11, r11, r13
	bset.ne	r12, r12, 1

	and.f	r6, r6, r13
	bset.ne	r12, r12, 2

	and.f	r7, r7, r13
	bset.ne	r12, r12, 1

	breq	r12, 0, @.L_4_4B_search

.L_found_in_4B:
	
	mov r0, r11
	mov r1, r7
	mov	r3, r3
	mov	r5, r5

	asr.f	r12, r12, 3
	
	mov.c	r0, r10
	mov.c	r1, r6
	mov.c	r3, r2
	mov.c	r5, r4

	ffs.f	r10, r0
	mov.z	r10, 32

	ffs.f	r11, r1
	mov.z	r11, 32

	xbfu 	r10, r10, 0b0111000011
	xbfu 	r11, r11, 0b0111000011

	; Get difference position in r6
	;; Force difference to 0
	xor	r12, r3, r5

	mov	r7, NULL_32DT_3

	and	r6, r12, r7
	add	r6, r6, r7
	or	r6, r6, r12
	or	r6, r6, r7
	xor	r6, r6, -1
	
	sub	r12, r6, r8
	bic r12, r12, r6
	and r12, r12, r13

	ffs.f r12, r12
	; If r12 is empty, all bytes are different (and turned to 0)
	mov.z	r12, 0
	
	xbfu 	r12, r12, 0b0111000011

; r12 contains position of difference, r10 and r11 the position of NULL bytes
; r3 and r5 contain the differing 4 bytes

; Depending on r10, r11 and r12, set the first byte of r3 and r5 to their
; difference

; Move r12 into r4 not to clobber r12
	mov	r4, r11
; Is the difference located before or on top of a NULL byte?
	sub.f	0, r10, r12
	sub.ne.f	r4, r4, r12
	asl.ge	r12, r12, 3

; Difference is first
	lsr.ge	r3, r3, r12
	lsr.ge	r5, r5, r12
	bge.d	@.L_return

; If one NULL byte is first. Which one?
	sub.f	0, r10, r11
	
; r2 is first
	asl.le	r10, r10, 3
	asl.gt	r11, r11, 3

	lsr.le	r3, r3, r10
	lsr.le	r5, r5, r10

; r3 is first
	lsr.gt	r3, r3, r11
	lsr.gt	r5, r5, r11

.L_return:
	bmsk	r3, r3, 7
	bmsk	r5, r5, 7

	j_s.d	[blink]
	sub	r0, r3, r5


ENDFUNC(strcmp)

#else

ENTRY (strcmp)

; r13 is now either 4 or 8 byte aligned
.L_start_4byte_search:

	xorl	r6,		r6,		r6	; reset mask showing NULL byte location

; Setup byte detector (more information bellow) [2]
	movhl	r8,		NULL_32DT_1
	orl		r8,		r8,		NULL_32DT_1

	movhl	r9,		NULL_32DT_2
	orl		r9,		r9,		NULL_32DT_2

; If there is a 0 in any of the read 32 bytes, its location is encoded
; in r6 as a bit mask
; This bitmask can be used to calculate the appropriate regression in the pointer [3]
.L_search_8bytes:
	ldl.ab	  r3,	[r1, +8]
	;r4 r5
	ldl.ab	  r10,	[r13, +8]

; Look for a zero
	subl	r12,	r3,		r8
	bicl	r12,	r12,	r3
	tstl	r12,	r9
	bne.d	@.L_found_difference_in_8B

	subl	r12,	r10,	r8
	bicl	r12,	r12,	r10
	tstl	r12,	r9
	bne.d	@.L_found_difference_in_8B
; Look for difference
	subl.f	0,		r3,		r10
	bne		@.L_found_difference_in_8B



	j		@.L_search_8bytes


.L_found_difference_in_8B:
subl	r1,		r1,		4
subl	r13,	r13,	4

.L_found_difference_in_4B:
; Need to make sure the 1B search takes a 4B chunk into consideration
subl	r1,		r1,		4
subl	r13,	r13,	4

; 1 Byte search
.L_start_1byte_search:

ldb.ab		r11,		[r13,	+1]
ldb.ab		r12,		[r1,	+1]

.L_search_1byte_chunks:
	; Check for end of string. Do sub either way to provide appropriate difference
	cmp			0,		r11
	cmp			0,		r12
	beq.d		@.L_return
	subl.f		r0,		r11,		r12

	; Load next r10
	ldb.ab		r11,		[r13,	+1]

	; If the current bytes are different, SUB will return non zero
	beq.d		@.L_search_1byte_chunks
	; Load next r1
	ldb.ab		r12,		[r1,	+1]


.L_return:
	j_s	[blink]

ENDFUNC (strcmp)

#endif


