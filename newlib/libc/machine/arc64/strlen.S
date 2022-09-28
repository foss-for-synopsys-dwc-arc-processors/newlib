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

; Code Brief:
; Correct input pointer alignment and perform four 8 byte block search
; This code is optimized for big strings, but also performs well for small
; ones
;
; R0 const char* ptr (string to measure)
; ret (R0):
;		- unsigned (string size)
;

#if defined (__ARC64_ARCH64__)

ENTRY (strlen)

; If address is 4 byte aligned, we can just directly read 4 bytes
bmsk.f	r3,		r0,		1
beq.d			@.L_4B_step

; Store r0 for size calculation when returning
MOVP	r13,	r0

subl	r3,		r3,		1		; [0]
asl		r3,		r3,		2		; [1]

; Jump depending on the alignment.
bi	    [r3]
; Read 3 bytes
ldb.ab	r10,	[r13,	+1]
cmp		r10,	0
beq 			@.L_return_size
nop
; Read 2 bytes
ldb.ab	r10,	[r13,	+1]
cmp		r10,	0
beq				@.L_return_size
nop
; Read 1 byte
ldb.ab	r10,	[r13,	+1]
cmp		r10,	0
beq				@.L_return_size

; Last nop can be removed [2]

; By this point, r13 is either 4 or 8 byte aligned
.L_4B_step:

; If aligned to 8 bytes, just jump ahead
andl.f	0,		r13,	0b111
beq.d	@.L_start_4_8B_search
; Always reset bit mask that will encode NULL byte location
xorl	r6,		r6,		r6

ld.ab	r10,	[r13,	+4]
sub		r11,	r10,	NULL_32DT_1
bic		r11,	r11,	r10
tst		r11,	NULL_32DT_2
bne		@.L_reread_last_4bytes

.L_start_4_8B_search:
; Setup byte detector (more information bellow) [3] [5]
movhl	r8,		NULL_32DT_1
movhl	r9,		NULL_32DT_2

orl		r8,		r8,		NULL_32DT_1
orl		r9,		r9,		NULL_32DT_2

ldl.ab	r2,		[r13,	+8]
.L_4_8B_search:
		ldl.ab	r3,		[r13,	+8]
		ldl.ab	r4,		[r13,	+8]
		ldl.ab	r5,		[r13,	+8]

	; NULL byte position is detected and encoded in r6 [4] [5]
		subl	r10,	r2,		r8
		subl	r11,	r3,		r8
		subl	r12,	r4,		r8
		subl	r7,		r5,		r8

		bicl	r10,	r10,	r2
		bicl	r11,	r11,	r3
		bicl	r12,	r12,	r4
		bicl	r7,		r7,		r5

		tstl	r10,	r9
		xor.ne	r6,		r6,		0b10000

		tstl	r11,	r9
		xor.ne	r6,		r6,		0b01000

		tstl	r12,	r9
		xor.ne	r6,		r6,		0b00100

		tstl	r7,		r9
		xor.ne	r6,		r6,		0b00010

		breq.d	r6,		0,		@.L_4_8B_search
		ldl.ab	r2,		[r13,	+8]

; Back track only what is required [4]
fls		r6,		r6
asl		r6,		r6,		3
subl	r13,	r13,	r6

; Compensate writeback in the loop break
; Should be 8 byte compensation, but if we only compensate 4 bytes we can
; fallthrough to 4 byte reread
subl	r13,	r13,	4

.L_reread_last_4bytes:
subl	r13,	r13,	4

; Perform 1 byte search until NULL byte is found
ldb		r10,	[r13]
.L_search_next_1byte_chunk:
		cmp		r10,	0
		bne.d	@.L_search_next_1byte_chunk
		ldb.aw	r10,	[r13, +1]

; NULL byte was found in r13 - 1
.L_return_size:
subl	r0,		r13,		r0
j_s.d	[blink]
subl	r0,		r0,		1

;; The first step in this code is to "fix" the address alignment
;
;; First, we check if the address is already 4 byte aligned.
;; If so, we can simply read 4 bytes and start the 8 byte reads
;
;; Otherwise, we can look at the last 2 bits in the address, and infer
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
; Removing 1 from b1b0 [0] gives us the "branch index".
; Now to get the appropriate jump size (how many instructions there are per
; branch) we can just multiply by 4 [1]
;
; The last "branch" will never be jumped. If it was, we wouldnt be reading any
; byte and therefore not aligning (the address would have already be aligned to
; start with). This means we can safely remove the nop from it [2].
; The nops could also be removed entirely by having r3 be multiples of 3*8
; but the extra operation isnt worth it
;
;; This code uses a common technique for NULL byte detection inside a word.
;; Details on this technique can be found in:
;; (https://graphics.stanford.edu/~seander/bithacks.html#ZeroInWord)
;
; In sum, this technique allows for detecting a NULL byte inside any given 
; amount of bits by performing the following operation
; 		DETECTNULL(X) (((X) - 0x01010101) & ~(X) & 0x80808080)
;
; The code above implements this by setting r8 to 0x01010101 and r9 to
; 0x80808080
; This operation differs slightly between 64 bit and 32 bit analysis.
; As LIMM are 32 bit only, we need to perform MOVHL and ORL [3] operations to
; have the appropriate 64 bit values in place
;
;; The major optimization in this code is to perform several 8 load byte loads
;; in a row and using the previously mentioned NULL byte detection method to
;; find the end of the string
;
; To achieve this, finding a NULL byte sets a bitmask that [4], when passed via
; the "find last set" instruction returns the amount of 8 byte chunks to
; backtrack. We can then simply multiply by 8 and remove that value from the
; pointer to make it point to the 8 byte chunk containing the NULL byte.
; We can then perform a simple byte search to find it.
; One possible optimization is to not perform a final 1 byte search, but use
; the already loaded registers to, depending on endianness, find the position
; of the NULL byte and appropriately adjust the pointer for size calculation
;
; The order the NULL byte detection operations are performed in isnt random [5]
; They are ordered in order to reduce register dependency and allow the CPU to
; run them in parallel
;

ENDFUNC (strlen)
#endif
