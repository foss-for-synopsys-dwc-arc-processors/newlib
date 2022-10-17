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
	bset.ne r12, r12, 6
	
	sub.f	0, r3, r5
	bset.ne r12, r12, 5


	; Look for NULL byte
	tst	r10, r13
	bset.ne	r12, r12, 4

	tst	r11, r13
	bset.ne	r12, r12, 3

	tst	r6, r13
	bset.ne	r12, r12, 2

	tst	r7, r13
	bset.ne	r12, r12, 1

	breq.d	r12, 0, @.L_4_4B_search

	; Did we find a difference?
	lsr.f	0, r12, 5
	bne	@.L_found_in_4B

	; Nope, means we just found a NULL byte
	j.d	[blink]
	mov	r0, 0

.L_found_in_4B:
	
	mov	r10, r3
	mov	r11, r5

	;mov r8, r11
	;mov r9, r7

	asr.f	r12, r12, 7
	
	mov.c	r10, r2
	mov.c	r11, r4
	
	;mov.c	r8, r10
	;mov.c	r9, r6

	;rol8	r10, r10
.L_search_next_byte:

	;rol8	r11, r11

	; Extract byte
	bmsk	r2, r10, 7
	bmsk.f	r3, r11, 7
	cmp.ne	r2, 0

	; Return if one of them is NULL byte
	beq.d	@.L_return

	sub.f		r0, r2, r3
	lsr8	r10, r10
	;sub.f	r0, r10, r11
	; Return if the difference is not 0
	beq.d	@.L_search_next_byte
	lsr8	r11, r11
	
	
.L_return:
	j_s	[blink]


; r0 and r1 contain the 4B from r0 and r1 that differ
; Now we can xor and invert to force a NULL in the different byte

; Make all bytes that match, equal to 0
	;xor	r2, r0, r1
; Invert. Only differing bytes are NULL now
	;not	r2, r2
; Detect and find NULL byte
	;sub	r3, r2, r8
	;bic r3, r3, r2
	;and r3, r13

	;ffs	r1, r1 ; [6]

	;xbfu 	r1, r1, 0b0111000011 ; [7]






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


