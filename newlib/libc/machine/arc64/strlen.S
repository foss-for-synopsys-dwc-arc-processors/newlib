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

ENTRY (strlen)
	; If the address is already 4 byte aligned, just jump to 4 byte search
	bmsk.f	0,		r0,		1
	beq.d	@.L_start_4byte_search
	MOVP	r13,	r0	; Store r0 for size calculation

.L_start_1byte_search:
	; 1 byte search until 4 byte alignment is found
	ldb		r10,	[r13]
	cmp		r10,	0

.L_search_next_1byte_chunk:
	; Found NULL byte!
	beq.d	@.L_return_ptr
	ldb.aw	r10,	[r13, +1]

	; 4 byte alignment not reached yet
	bmsk.f	0,		r13,		1
	bne.d	@.L_search_next_1byte_chunk
	cmp		r10,	0

; 4 byte alignment reached!

; Bootstrap magic NULL byte detector for 4 byte search
.L_start_4byte_search:
	mov		r8,		0x01010101
	ror		r9,		r8						; Further magic byte detector setup

	; Load next 4 bytes
	ld.ab	r10,	[r13, +4]

; Handle 4 byte chunks
.L_search4byte_chunk:
	
	; Look for the NULL byte
	sub		r2,		r10,	r8
	bic		r2,		r2,		r10
	tst		r2,		r9

	; byte not found yet
	beq.d	@.L_search4byte_chunk
	; Load next 4 bytes
	ld.ab	r10,	[r13, +4]
	
	; NULL byte found!
	; Backtrack 8 bytes
	; 4 because of write-back, 4 because we dont know for sure where in the
	; 4 bytes the NULL byte is
	; Then let 1 byte search do its' thing
	SUBP	r13,		r13,		8
	j		@.L_start_1byte_search

; Byte was found in r0 - 1
.L_return_ptr:
	SUBP	r0,		r13,		r0
	j_s.d	[blink]
	SUBP	r0,		r0,		1

ENDFUNC (strlen)