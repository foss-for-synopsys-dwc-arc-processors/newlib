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

; Brief:
; If 4 byte aligned
; 	Do 4 byte NULL byte search
;	When it is found, perfom a 1 byte search on the last 4 bytes
; Otherwise, 1 byte search until alignment
;	Then, do 4 byte search as previously specified
;
;; More in depth description at the end
;
; R0 const char* ptr
; ret (R0):
;		- String size

ENTRY (strlen)

	; address is 4 byte aligned, go to 4 byte search
	bmsk.f	r3,		r0,		1
	beq.d			@.L_start_4byte_search
	MOVP	r13,	r0	; Store r0 for size calculation

	subl	r3,		r3,		1		; [0]
	asl		r3,		r3,		2		; [1]

	; r3 now represents the inverse of the amount of instructions to skip
	bi	    [r3]
; Read 3 bytes
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq.d			@.L_return_ptr
	subl	r2,		r2,		1
; Read 2 bytes
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq.d			@.L_return_ptr
	subl	r2,		r2,		1
; Read 1 byte
	ldb.ab	r10,	[r13,	+1]
	cmp		r10,	0
	beq.d			@.L_return_ptr
	subl	r2,		r2,		1


.L_start_4byte_search:
	;; Setup byte detector (more information bellow)
	mov		r8,		0x01010101
	ror		r9,		r8

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
	subl	r13,		r13,		8

	ldb		r10,	[r13]

;; 1 byte search until NULL byte is found
.L_search_next_1byte_chunk:
	cmp		r10,	0
	bne.d	@.L_search_next_1byte_chunk
	ldb.aw	r10,	[r13, +1]

; NULL byte was found in r0 - 1
.L_return_ptr:
	subl	r0,		r13,		r0
	j_s.d	[blink]
	subl	r0,		r0,		1

;; The first step in this code is to "fix" the address alignment
;; This is done by looking at the last 2 bits in the address, and infering
;; how many 1 byte loads are required
; The following table shows how the last two bytes correlate to branch index
; and how many bytes we need to read
;
;   (b1,b0) | bytes to search |  branch index  | required jump
; ----------+-----------------+----------------+--------------
;   00b (0) |   <---  Already aligned, jumps directly to 4 byte search
;   01b (1) |        3        |        0       |   0
;   10b (2) |        2        |        1       |   4
;   11b (3) |        1        |        2       |   8
;
; Removing 1 from b1b0 [0] gives us the branch index.
; Now to get the appropriate jump size, we can just multiply by 4 [1]
;
;; This code uses a common technique for NULL byte detection inside a word.
;; Details on this technique can be found in:
;; (https://graphics.stanford.edu/~seander/bithacks.html#ZeroInWord)
;
; In sum, this technique allows for detecting a NULL byte inside any given amount of
; bits by performing the following operation
; 		DETECTNULL(X) (((X) - 0x01010101) & ~(X) & 0x80808080)
;
; The code above implements this by setting r8 to 0x01010101 and r9 to 0x80808080
;
;; There are a few possible optimizations identified
;
; [2]
; Dont reload from memory, but instead use the current value of r11
; There might be a possible problem due to endianness

ENDFUNC (strlen)
