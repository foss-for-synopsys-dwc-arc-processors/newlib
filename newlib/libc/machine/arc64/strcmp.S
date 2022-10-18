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
; Setup r0, r1, r3 r5 with the relevant loaded and intermediate values
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

	xorl	r12, r12, r12

; Setup byte detector (more information bellow) [1]
	vpack2wl	r8, NULL_32DT_1, NULL_32DT_1
; Set r9 as a copy of r8 for vectorized sub
	asll	r9, r8, 7

.L_4_4B_search:

; Using 128-bit memory operations
#if defined (__ARC64_M128__)
	
	lddl.ab	r2r3, [r0, +16]
	lddl.ab	r4r5, [r1, +16]

; The 64-bit crunching implementation.
#elif defined (__ARC64_ARCH64__)
	
	ldl.ab	r2, [r0, +8]
	ldl.ab	r3, [r0, +8]

	ldl.ab	r4, [r1, +8]
	ldl.ab	r5, [r1, +8]

#else
	# error Unknown configuration
#endif
	subl	r10, r2, r8
	subl	r11, r3, r8
	subl	r6, r4, r8
	subl	r7, r5, r8

	bicl	r10, r10, r2
	bicl	r11, r11, r3
	bicl	r6, r6, r4
	bicl	r7, r7, r5

	; Look for difference
	subl.f	0, r2, r4
	bset.ne r12, r12, 2
	
	subl.f	0, r3, r5
	bset.ne r12, r12, 1


	; Look for NULL byte
	andl.f	r10, r10, r9
	bset.ne	r12, r12, 2

	andl.f	r11, r11, r9
	bset.ne	r12, r12, 1

	andl.f	r6, r6, r9
	bset.ne	r12, r12, 2

	andl.f	r7, r7, r9
	bset.ne	r12, r12, 1

	breq	r12, 0, @.L_4_4B_search

.L_found_in_4B:
; Setup r0, r1, r3 r5 with the relevant loaded and intermediate values
	movl	r0, r11
	movl	r1, r7
	movl	r3, r3
	movl	r5, r5

	asr.f	r12, r12, 3
	
	movl.c	r0, r10
	movl.c	r1, r6
	movl.c	r3, r2
	movl.c	r5, r4

	ffsl.f	r10, r0
	movl.z	r10, 64

	ffsl.f	r11, r1
	movl.z	r11, 64

	xbful 	r10, r10, 0b0111000011
	xbful 	r11, r11, 0b0111000011

	; Get difference position in r6
	;; Force difference to 0
	xorl	r12, r3, r5

	vpack2wl	r7, NULL_32DT_3, NULL_32DT_3

	andl	r6, r12, r7
	addl	r6, r6, r7
	orl	r6, r6, r12
	orl	r6, r6, r7
	xorl	r6, r6, -1
	
	subl	r12, r6, r8
	bicl	r12, r12, r6
	andl	r12, r12, r9

	ffsl.f	r12, r12
	; If r12 is empty, all bytes are different (and turned to 0)
	movl.z	r12, 0
	
	xbful 	r12, r12, 0b0111000011

; r12 contains position of difference, r10 and r11 the position of NULL bytes
; r3 and r5 contain the differing 4 bytes

; Depending on r10, r11 and r12, set the first byte of r3 and r5 to their
; difference

; Move r12 into r4 not to clobber r12
	movl	r4, r11
; Is the difference located before or on top of a NULL byte?
	subl.f	0, r10, r12
	subl.ne.f	r4, r4, r12
	asll.ge	r12, r12, 3

; Difference is first
	lsrl.ge	r3, r3, r12
	lsrl.ge	r5, r5, r12
	bge.d	@.L_return

; If one NULL byte is first. Which one?
	subl.f	0, r10, r11
	
; r2 is first
	asll.le	r10, r10, 3
	asll.gt	r11, r11, 3

	lsrl.le	r3, r3, r10
	lsrl.le	r5, r5, r10

; r3 is first
	lsrl.gt	r3, r3, r11
	lsrl.gt	r5, r5, r11

.L_return:
	bmskl	r3, r3, 7
	bmskl	r5, r5, 7

	j_s.d	[blink]
	subl	r0, r3, r5


ENDFUNC (strcmp)

#endif


