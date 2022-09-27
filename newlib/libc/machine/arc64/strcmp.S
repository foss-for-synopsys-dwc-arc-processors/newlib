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

#if defined (__ARC64_ARCH64__)

ENTRY (strcmp)
	; Compare address alignments
	bmsk.f		r8,		r0,		1
	bmsk.f		r9,		r1,		1
	SUB.f		r8,		r8,		r9

	; If alignments are different, will never match alignment
	bne.d		@.L_start_1byte_search

	; Dont clobber r0
	; Pass it to r10 and use r0 for output immediately
	MOVP		r13,	r0
	; Check if have 4 byte alignment
	or			r8,		r0,		r1
	bmsk.f		r3,		r8,		1
	beq.d		@.L_start_4byte_search
	subl		r3,		r3,		1		; [0]
	
    ; r3x6
	asl		r8,		r3,		1		; [1]
	asl		r9,		r3,		2		; [2]
    addl	r3,     r8,     r9

	; r3 now represents the inverse of the amount of instructions to skip
	bi	    [r3]
; Read 3 bytes
	ldb.ab		r11,	[r13,	+1]
	ldb.ab		r12,	[r1,	+1]
	and.f		r0,		r11,	r12
	beq.d		@.L_return
	subl.f		r0,		r11,	r12
	bne.d		@.L_return
; Read 2 bytes
	ldb.ab		r11,	[r13,	+1]
	ldb.ab		r12,	[r1,	+1]
	and.f		r0,		r11,	r12
	beq.d		@.L_return
	subl.f		r0,		r11,	r12
	bne.d		@.L_return
; Read 1 byte
	ldb.ab		r11,	[r13,	+1]
	ldb.ab		r12,	[r1,	+1]
	and.f		r0,		r11,	r12
	beq.d		@.L_return
	subl.f		r0,		r11,	r12
	bne			@.L_return



; r13 is now either 4 or 8 byte aligned
.L_start_4byte_search:

; If aligned to 8 bytes, just jump ahead
	andl.f	0,		r13,	0b111
	beq.d	@1f
	xorl	r6,		r6,		r6	; reset mask showing NULL byte location

	ld.ab		r11,		[r13,	+4]
	ld.ab		r12,		[r1,	+4]

	subl.f		r0,		r11,		r12
	bne			@.L_found_difference_in_4B

; Test if it is zero
	sub		r8,		r11,	NULL_32DT_1
	bic		r8,		r8,		r11

	sub		r9,		r11,	NULL_32DT_1
	bic		r9,		r8,		r11

	tst			r8,		NULL_32DT_2
	bne			@.L_return
	tst			r9,		NULL_32DT_2
	bne			@.L_return

1:
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


