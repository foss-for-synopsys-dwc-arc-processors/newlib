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

ENTRY (strcmp)
	; Compare address alignments
	bmsk.f		r8,		r0,		1
	bmsk.f		r9,		r1,		1
	SUB.f		r8,		r8,		r9

	; If alignments are different, will never match alignment
	bne.d		@.L_start_1byte_search

	; Dont clobber r0
	; Pass it to r10 and use r0 for output immediately
	MOVP		r10,	r0
	; Check if have 4 byte alignment
	or			r8,		r0,		r1
	bmsk.f	r3,		r8,		1
	beq.d		@.L_start_4byte_search
	SUBP	r3,		r3,		1		; [0]
	
    ; r3x6
	asl		r8,		r3,		1		; [1]
	asl		r9,		r3,		2		; [2]
    ADDP    r3,     r8,     r9

	; r3 now represents the inverse of the amount of instructions to skip
	bi	    [r3]
; Read 3 bytes
	ldb.ab		r11,	[r10,	+1]
	ldb.ab		r12,	[r1,	+1]
	and.f		r0,		r11,	r12
	beq.d		@.L_return
	SUBP.f		r0,		r11,	r12
	bne.d		@.L_return
; Read 2 bytes
	ldb.ab		r11,	[r10,	+1]
	ldb.ab		r12,	[r1,	+1]
	and.f		r0,		r11,	r12
	beq.d		@.L_return
	SUBP.f		r0,		r11,	r12
	bne.d		@.L_return
; Read 1 byte
	ldb.ab		r11,	[r10,	+1]
	ldb.ab		r12,	[r1,	+1]
	and.f		r0,		r11,	r12
	beq.d		@.L_return
	SUBP.f		r0,		r11,	r12
	bne			@.L_return

.L_start_4byte_search:
	mov			r8,		0x01010101
	ror			r9,		r8						; Further magic byte detector setup

.L_search_next_4byte_chunk:
	ld.ab		r11,		[r10,	+4]
	ld.ab		r12,		[r1,	+4]

	; Find difference. If found, let 1 byte search handle it
	SUBP.f		r0,		r11,		r12
	bne.d		@.L_found_difference_in_4B
	
	; Find a NULL byte (the srings are the same, so if present, the NULL is in both)
	sub		r13, r12, r8
	bic		r13, r13, r12
	tst		r13, r9

	; Found NULL byte, but strings arent different, can return
	bne		@.L_return

	j		@.L_search_next_4byte_chunk

	
.L_found_difference_in_4B:
; Need to make sure the 1B search takes a 4B chunk into consideration
SUBP	r1,		r1,		4
SUBP	r10,	r10,	4

; 1 Byte search
.L_start_1byte_search:

ldb.ab		r11,		[r10,	+1]
ldb.ab		r12,		[r1,	+1]

.L_search_1byte_chunks:
	; Check for end of string. Do sub either way to provide appropriate difference
	and.f		r0,		r11,		r12
	beq.d		@.L_return
	SUBP.f		r0,		r11,		r12

	; Load next r10
	ldb.ab		r11,		[r10,	+1]

	; If the current bytes are different, SUB will return non zero
	beq.d		@.L_search_1byte_chunks
	; Load next r1
	ldb.ab		r12,		[r1,	+1]


.L_return:
	j_s	[blink]

ENDFUNC (strcmp)
