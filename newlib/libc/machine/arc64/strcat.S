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

ENTRY (strcat)
; Find end of r0
; ========================== STRLEN CODE START ==========================
	;; Setup byte detector (more information bellow)
	mov		r8,		0x01010101
	ror		r9,		r8
    
	; address is 4 byte aligned, go to 4 byte search
	bmsk.f	r3,		r0,		1
	beq.d			@.L_start_4byte_search
	MOVP	r13,	r0	; Store r0 for size calculation

	SUBP	r3,		r3,		1		; [0]
	asl		r3,		r3,		2		; [1]

	; r3 now represents the inverse of the amount of instructions to skip
	bi	    [r3]
; Read 3 bytes
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq.d			@.L_string_end_found
	SUBP	r2,		r2,		1
; Read 2 bytes
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq.d			@.L_string_end_found
	SUBP	r2,		r2,		1
; Read 1 byte
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq.d			@.L_string_end_found
	SUBP	r2,		r2,		1

.L_start_4byte_search:

	; Load next 4 bytes
	ld.ab	r10,	[r13, +4]

; Handle 4 byte chunks
.L_search4byte_chunk:
	
	; Look for the NULL byte
	sub		r2,		r10,	r8
	bic		r2,		r2,		r10
	tst		r2,		r9

	; NULL byte not found yet
	beq.d	@.L_search4byte_chunk
	; Load next 4 bytes
	ld.ab	r10,	[r13, +4]
	
; NULL byte found!
; Backtrack 8 bytes [2]
; 4 because of write-back, 4 because we dont know for sure where in the
; 4 bytes the NULL byte is. Then perform 1 byte search
SUBP	r13,		r13,		8
ldb		r10,	[r13]

;; 1 byte search until NULL byte is found
.L_search_next_1byte_chunk:
	cmp		r10,	0
	bne.d	@.L_search_next_1byte_chunk
	ldb.aw	r10,	[r13, +1]

; NULL byte was found in r0 - 1
.L_string_end_found:
	SUBP	r13,		r13,	1

; ========================== STRLEN CODE END >|< ==========================

	; Compare address alignments
	bmsk.f		r10,		r13,		2
	bmsk.f		r11,		r1,		    2
	SUB.f		r10,		r10,	    r11

	; If alignments are different, will never match alignment
	bne		@.L_start_1byte_search

ld.ab	r11,	[r1, +4]
sub		r12, r11, r8
bic		r12, r12, r11
tst		r12, r9
bne.d	@.L_start_search_next_1byte_chunk

.L_copy_4byte_chunk:
	; Set r10 to be the previously read 4 bytes
    ; Move known non NULL containing bytes to r10
	MOVP	r10,    r11
	; Read next 4 bytes
	ld.ab	r11,	[r1, +4]
	; Check if NULL byte is in the next 4 bytes
	sub		r12,    r11,    r8
	bic		r12,    r12,    r11
	tst		r12,    r9

	; NULL byte not found, store previous non-NULL byte containing bytes and continue
	beq.d	@.L_copy_4byte_chunk
	st.ab	r10,	[r13, +4]

.L_start_search_next_1byte_chunk:

SUBP	r1,     r1,     4

.L_start_1byte_search:

	; Look for NULL byte
	ldb.ab	r11,	[r1, +1]
	cmp		r11,	0

    bne.d   @.L_start_1byte_search
	stb.ab	r11,	[r13, +1]

.L_return_ptr:
	j_s	[blink]


ENDFUNC (strcat)
