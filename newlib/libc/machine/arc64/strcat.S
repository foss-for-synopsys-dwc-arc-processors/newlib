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


; r0 char* dest
; r1 const char* src

; dest and src MUST NOT intercept

; Brief:
; Perform the same operation as strlen for finding the end
; of r0
; If r0 and r1 have
; If 4 byte aligned
; 	Do 4 byte search until there are no more 4 byte chunks
;	Then, do 1 byte search
; Otherwise, 1 byte search until alignment
;	Then, do 4 byte search as previously specified
;
;; More in depth description at the end
;
; R0 void* ptr
; R1 int ch
; R2 size_t count
; ret (R0):
;		- 0 : Byte not found
;		- Byte position

#if defined (__ARC64_ARCH64__)

ENTRY (strcat)
; Find end of r0
; ========================== STRLEN CODE START ==========================
; If address is 4 byte aligned, we can just directly read 4 bytes
	bmsk.f	r3,		r0,		1
	beq.d			@.L_start_4byte_search
	MOVP	r13,	r0	; Store r0 for size calculation

	subl	r3,		r3,		1		; [0]
	asl		r3,		r3,		2		; [1]

; Jump depending on the alignment
	bi	    [r3]
; Read 3 bytes
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq 			@.L_string_end_found
	nop
; Read 2 bytes
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq				@.L_string_end_found
	nop
; Read 1 byte
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq				@.L_string_end_found
	nop

; r13 is now either 4 or 8 byte aligned
.L_start_4byte_search:

; If aligned to 8 bytes, just jump ahead
	andl.f	0,		r13,	0b111
	beq.d	@1f
	xorl	r6,		r6,		r6	; reset mask showing NULL byte location

	ld.ab	r10,	[r13,	+4]
	sub		r11,	r10,	NULL_32DT_1
	bic		r11,	r11,	r10
	tst		r11,	NULL_32DT_2
	bne		@.L_reread_last_4bytes

1:
; Setup byte detector (more information bellow) [2]
	movhl	r8,		NULL_32DT_1
	orl		r8,		r8,		NULL_32DT_1

	movhl	r9,		NULL_32DT_2
	orl		r9,		r9,		NULL_32DT_2

	ldl.ab	  r2,	[r13, +8]
.L_search_32bytes:
	ldl.ab	  r3,	[r13, +8]
	ldl.ab	  r4,	[r13, +8]
	ldl.ab	  r5,	[r13, +8]

; If there is a 0 in any of the read 32 bytes, its location is encoded
; in r6 as a bit mask
; This bitmask can be used to calculate the appropriate regression in the pointer [3]
	subl	r10,	r2,		r8
	subl	r11,	r3,		r8
	subl	r12,	r4,		r8
	subl	r7,		r5,		r8

	bicl	r10,	r10,	r2
	bicl	r11,	r11,	r3
	bicl	r12,	r12,	r4
	bicl	r7,		r7,		r5

	tstl		r10,	r9
	bset.ne		r6,		r6,		4

	tstl		r11,	r9
	bset.ne		r6,		r6,		3

	tstl		r12,	r9
	bset.ne		r6,		r6,		2

	tstl		r7,		r9
	bset.ne		r6,		r6,		1

	breq.d	r6,		0,		@.L_search_32bytes
	ldl.ab	r2,		[r13,	+8]

; Back track only what is required [4]
fls		r6,		r6
asl		r6,		r6,		3
subl	r13,	r13,	r6

; Compensate writeback
subl	r13,	r13,	4
.L_reread_last_4bytes:
subl	r13,	r13,	4

;; 1 byte search until NULL byte is found
ldb		r10,	[r13]
.L_search_next_1byte_chunk:
	cmp		r10,	0
	bne.d	@.L_search_next_1byte_chunk
	ldb.aw	r10,	[r13, +1]

; NULL byte was found in r0 - 1
.L_string_end_found:
	subl	r13,	r13,		1


; ========================== STRLEN CODE END >|< ==========================

	; Compare address alignments
	bmsk.f		r10,		r13,		2
	bmsk.f		r11,		r1,		    2
	SUB.f		r10,		r10,	    r11

	; If alignments are different, will never match alignment
	bne		@.L_start_1byte_search_src

    ; Aligned at 4 byte!
	bmsk.f	r3,		r13,		1
	beq.d			@.L_start_4byte_search_src

	subl	r3,		r3,		1		; [0]
	asl		r3,		r3,		2		; [1]

	; r3 now represents the inverse of the amount of instructions to skip
	bi	    [r3]
; Read 3 bytes
	ldb.ab	r10,	[r1,	+1]
	cmp		r10,	0
	beq.d			@.L_return_ptr
    stb.ab	r10,	[r13,	+1]
; Read 2 bytes
	ldb.ab	r10,	[r1,	+1]
	cmp		r10,	0
	beq.d			@.L_return_ptr
    stb.ab	r10,	[r13,	+1]
; Read 1 byte
	ldb.ab	r10,	[r1,	+1]
	cmp		r10,	0
	beq.d			@.L_return_ptr
    stb.ab	r10,	[r13,	+1]


; r13 is now either 4 or 8 byte aligned
.L_start_4byte_search_src:

; If aligned to 8 bytes, just jump ahead
	andl.f	0,		r1,		0b111
	beq.d	@.L_search_32bytes_src
	xorl	r6,		r6,		r6	; reset mask showing NULL byte location

	ld.ab	r10,	[r1,	+4]
	sub		r11,	r10,	NULL_32DT_1
	bic		r11,	r11,	r10
	tst		r11,	NULL_32DT_2
	bne		@.L_reread_last_4bytes_src

	stl.ab	r10,	[r13,	+4]

.L_search_32bytes_src:
	ldl.ab	r2,	[r1,	+8]
	ldl.ab	r3,	[r1,	+8]
	ldl.ab	r4,	[r1,	+8]
	ldl.ab	r5,	[r1,	+8]

; If there is a 0 in any of the read 32 bytes, its location is encoded
; in r6 as a bit mask
; This bitmask can be used to calculate the appropriate regression in the pointer [3]
	subl	r10,	r2,		r8
	subl	r11,	r3,		r8
	subl	r12,	r4,		r8
	subl	r7,		r5,		r8

	bicl	r10,	r10,	r2
	bicl	r11,	r11,	r3
	bicl	r12,	r12,	r4
	bicl	r7,		r7,		r5

	tstl		r10,	r9
	bset.ne		r6,		r6,		4

	tstl		r11,	r9
	bset.ne		r6,		r6,		3

	tstl		r12,	r9
	bset.ne		r6,		r6,		2

	tstl		r7,		r9
	bset.ne		r6,		r6,		1

	brne	r6,		0,		@.L_found_in_32B

	stl.ab	r2,	[r13,	+8]
	stl.ab	r3,	[r13,	+8]
	stl.ab	r4,	[r13,	+8]
	stl.ab	r5,	[r13,	+8]

	j @.L_search_32bytes_src

.L_found_in_32B:

; Back track only what is required [4]
;fls		r6,		r6

;bi		[r6]
;stl.ab	r5,	[r13,	+8]
;stl.ab	r4,	[r13,	+8]
;stl.ab	r3,	[r13,	+8]
;stl.ab	r2,	[r13,	+8]

;asl		r6,		r6,		3
;subl	r1,		r1,		r6

; Compensate writeback
;addl	r1,	r1,	4

subl	r1,		r1,		28

.L_reread_last_4bytes_src:

subl	r1,     r1,     4

.L_start_1byte_search_src:

	; Look for NULL byte
	ldb.ab	r11,	[r1, +1]
	cmp		r11,	0

    bne.d   @.L_start_1byte_search_src
	stb.ab	r11,	[r13, +1]

.L_return_ptr:
	j_s	[blink]


ENDFUNC (strcat)

#endif
