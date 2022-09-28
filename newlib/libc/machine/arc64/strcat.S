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
; Perform the same operation as strlen for finding the end of r0 string
; If r0 and r1 have
; If 4 byte aligned
; 	Do 4 byte search until there are no more 4 byte chunks
;	Then, do 1 byte search
; Otherwise, 1 byte search until alignment
;	Then, do 4 byte search as previously specified
;
;; More in depth description at the end
;
; R0 char* dest (destination string)
; R1 const char* src (source string)
; ret (R0):
;		- char* (destiantion string)
;

#if defined (__ARC64_ARCH64__)

ENTRY (strcat)
; Find end of r0 string
; ========================== STRLEN CODE START ==========================

; If address is 4 byte aligned, we can just directly read 4 bytes
bmsk.f	r3,		r0,		1
beq.d			@.L_4B_step_dest

; Store r0 for size calculation when returning
MOVP	r13,	r0

subl	r3,		r3,		1		; [0]
asl		r3,		r3,		2		; [1]

; Jump depending on the alignment.
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

; By this point, r13 is either 4 or 8 byte aligned
.L_4B_step_dest:

; If aligned to 8 bytes, just jump ahead
andl.f	0,		r13,	0b111
beq.d			@.L_start_4_8B_search_dest

; Always reset bit mask that will encode NULL byte location
xorl	r6,		r6,		r6

ld.ab	r10,	[r13,	+4]
sub		r11,	r10,	NULL_32DT_1
bic		r11,	r11,	r10
tst		r11,	NULL_32DT_2
bne				@.L_reread_last_4bytes

.L_start_4_8B_search_dest:
; Setup byte detector (more information bellow) [2] [4]
movhl	r8,		NULL_32DT_1
movhl	r9,		NULL_32DT_2

orl		r8,		r8,		NULL_32DT_1
orl		r9,		r9,		NULL_32DT_2

ldl.ab	r2,		[r13,	+8]

.L_4_8B_search_dest:
		ldl.ab	r3,		[r13,	+8]
		ldl.ab	r4,		[r13,	+8]
		ldl.ab	r5,		[r13,	+8]

	; NULL byte position is detected and encoded in r6 [3] [4]
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

		breq.d		r6,		0,		@.L_4_8B_search_dest
		ldl.ab		r2,		[r13,	+8]

; Back track only what is required [3]
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
.L_search_next_1byte_chunk_dest:
		cmp		r10,	0
		bne.d	@.L_search_next_1byte_chunk_dest
		ldb.aw	r10,	[r13, +1]

; NULL byte was found in r0 - 1
.L_string_end_found:
subl	r13,	r13,		1

; ========================== STRLEN CODE END >|< ==========================

; Compare address alignments
bmsk.f	r10,		r13,		2
bmsk.f	r11,		r1,		    2
SUB.f	r10,		r10,	    r11

; If alignments are different, will never match alignment
bne		@.L_start_1byte_search_src

; If address is 4 byte aligned, we can just directly read 4 bytes
bmsk.f	r3,		r13,		1
beq.d			@.L_4B_step_src

subl	r3,		r3,		1		; [0]
asl		r3,		r3,		2		; [1]

; Jump depending on the alignment
bi	    [r3]
; Read 3 bytes
ldb.ab	r10,	[r1,	+1]
cmp		r10,	0
beq.d			@.L_return_dest
stb.ab	r10,	[r13,	+1]

; Read 2 bytes
ldb.ab	r10,	[r1,	+1]
cmp		r10,	0
beq.d			@.L_return_dest
stb.ab	r10,	[r13,	+1]

; Read 1 byte
ldb.ab	r10,	[r1,	+1]
cmp		r10,	0
beq.d			@.L_return_dest
stb.ab	r10,	[r13,	+1]


; By this point, r13 and r1 are either 4 or 8 byte aligned, with
; matching alignments
.L_4B_step_src:

; If aligned to 8 bytes, just jump ahead
andl.f	0,		r1,		0b111
beq.d			@.L_4_8B_search_src
; Always reset bit mask that will encode NULL byte location
xorl	r6,		r6,		r6

ld.ab	r10,	[r1,	+4]
sub		r11,	r10,	NULL_32DT_1
bic		r11,	r11,	r10
tst		r11,	NULL_32DT_2
bne				@.L_reread_last_4bytes_src

; NULL byte detector is already setup by strlen

stl.ab	r10,	[r13,	+4]

.L_4_8B_search_src:
		ldl.ab	r2,		[r1,	+8]
		ldl.ab	r3,		[r1,	+8]
		ldl.ab	r4,		[r1,	+8]
		ldl.ab	r5,		[r1,	+8]

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
		bset.ne	r6,		r6,		4

		tstl	r11,	r9
		bset.ne	r6,		r6,		3

		tstl	r12,	r9
		bset.ne	r6,		r6,		2

		tstl	r7,		r9
		bset.ne	r6,		r6,		1

		brne	r6,		0,		@.L_found_in_32B

		stl.ab	r2,	[r13,	+8]
		stl.ab	r3,	[r13,	+8]
		stl.ab	r4,	[r13,	+8]
		stl.ab	r5,	[r13,	+8]

		j 		@.L_4_8B_search_src

.L_found_in_32B:

; Back track only what is required [5]
fls		r6,		r6

asl		r5,		r6,		3
sub		r6,		r6,		1

subl	r1,		r1,		r5
asl		r6,		r6,		2

bi		[r6]
stl.ab	r2,		[r13,	+8]
stl.ab	r3,		[r13,	+8]
stl.ab	r4,		[r13,	+8]
b				@.L_start_1byte_search_src

stl.ab	r2,		[r13,	+8]
stl.ab	r3,		[r13,	+8]
b				@.L_start_1byte_search_src
nop

stl.ab	r2,		[r13,	+8]
nop
nop
nop

; Passthrough to last branch

b		@.L_start_1byte_search_src

.L_reread_last_4bytes_src:

subl	r1,     r1,     4

; Perform 1 byte search until NULL byte is found
.L_start_1byte_search_src:

		; Look for NULL byte
		ldb.ab	r11,	[r1, 	+1]
		cmp		r11,	0

		bne.d   		@.L_start_1byte_search_src
		stb.ab	r11,	[r13, 	+1]

.L_return_dest:
j_s	[blink]


ENDFUNC (strcat)


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
; The nops could be removed by having r3 be multiples of 3*8 but the extra
; operation isnt worth it
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
; As LIMM are 32 bit only, we need to perform MOVHL and ORL [2] operations to
; have the appropriate 64 bit values in place
;
;; The major optimization in this code is to perform several 8 load byte loads
;; in a row and using the previously mentioned NULL byte detection method to
;; find the end of the string
;
; To achieve this, finding a NULL byte sets a bitmask that [3], when passed via
; the "find last set" instruction returns the amount of 8 byte chunks to
; backtrack. We can then simply multiply by 8 and remove that value from the
; pointer to make it point to the 8 byte chunk containing the NULL byte.
; We can then perform a simple byte search to find it.
; One possible optimization is to not perform a final 1 byte search, but use
; the already loaded registers to, depending on endianness, find the position
; of the NULL byte and appropriately adjust the pointer for size calculation
;
; The order the NULL byte detection operations are performed in isnt random [4]
; They are ordered in order to reduce register dependency and allow the CPU to
; run them in parallel
;
;; When the src NULL byte is found, the encoded position is used to perform the
;; appropriate stores, and reset pointers such that 1 byte search can be
;; performed optimally, and not waste the contents already loaded [5]
;
; The operation is a lot like what is done for alignment
; We must backtrack r1 appropriately. If we dont always retreat 32 bytes, we
; must store the already loaded 8 byte chunks present in r2, r3, r4 (r5 is 
; never loaded because if the target byte was found, at the very least it
; is in r5, which needs to be re-searched.
;
;    r6 bit | bytes to backtrack | Registers to store |
; ----------+--------------------+----------+---------|
;   01b (1) |          8         |      r2, r3, r4    |
;   10b (2) |          16        |        r2, r3      |
;  100b (3) |          24        |          r2        |
; 1000b (4) |          32        |         none       |
;
; To set r1, we multipply r6 by 8 and we can use that to reduce r1
; appropriately
; To set r13, and not waste the loaded contents, we can subtract 1 from r6
; and then multiply it by 4 to obtain the appropriate instructions to run
; 
; The nops are very important to keep the alignment of the jump
;
;


#endif
