/*
   Copyright (c) 2022, Synopsys, Inc. All rights reserved.

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

ENTRY (strcat)
; Find end of r0 string
; ========================== STRLEN CODE START ==========================


; Preserve r0 for size calculation when returning
	movl	r13, r0
	xorl	r6, r6, r6

; Setup byte detector (more information bellow) [1]
	vpack2wl	r8, NULL_32DT_1, NULL_32DT_1
	asll	r9, r8, 7


.L_4_8B_search:

; Using 128-bit memory operations
#if defined (__ARC64_M128__)

	lddl.ab r2r3, [r13, +16]
	lddl.ab r4r5, [r13, +16]

; The 64-bit crunching implementation.
#elif defined (__ARC64_ARCH64__)

	ldl.ab	r2, [r13, +8]
	ldl.ab	r3, [r13, +8]
	ldl.ab	r4, [r13, +8]
	ldl.ab	r5, [r13, +8]

#else
# error Unknown configuration
#endif

; NULL byte position is detected and encoded in r6 [0] [9]
	subl	r10, r2, r8
	subl	r11, r3, r8
	subl	r12, r4, r8
	subl	r7, r5, r8

	bicl	r10, r10, r2
	bicl	r11, r11, r3
	bicl	r12, r12, r4
	bicl	r7, r7, r5

	tstl	r10, r9
	bset.ne	r6, r6, 4

	tstl	r11, r9
	bset.ne	r6, r6, 3

	tstl	r12, r9
	bset.ne	r6, r6, 2

	tstl	r7, r9
	bset.ne	r6, r6, 1

	breq.d	r6, 0, @.L_4_8B_search

	fls	r6, r6 ; [2]

; Point r13 to first NULL byte containing double word [3]
	sub3l	r13, r13, r6

; Select appropriate register to analyze [4]
	subl	r6, r6, 1
	asl r6, r6, 1

	bi	[r6]
	MOVP	r2, r7
	b	@.L_fix_r13
	MOVP	r2, r12
	b	@.L_fix_r13
	MOVP	r2, r11
	b	@.L_fix_r13
	MOVP	r2, r10
	nop

; Point r13 to first NULL byte in selected double word
.L_fix_r13:
	andl	r2, r2, r9 ; [5]

	ffsl	r2, r2 ; [6]

	xbful 	r2, r2, 0b01111000011 ; [7]

	addl	r13, r13, r2 ; [8]


; ========================== STRLEN CODE END >|< ==========================

	xorl	r6, r6, r6

.L_4_8B_search_src:
; Using 128-bit memory operations
#if defined (__ARC64_M128__)

	lddl.ab	r2r3, [r1, +16]
	lddl.ab	r4r5, [r1, +16]

; The 64-bit crunching implementation.
#elif defined (__ARC64_ARCH64__)

	ldl.ab	r2, [r1, +8]
	ldl.ab	r3, [r1, +8]
	ldl.ab	r4, [r1, +8]
	ldl.ab	r5, [r1, +8]

#else
	# error Unknown configuration
#endif

; NULL byte position is detected and encoded in r6 [4] [5]
	subl	r10, r2, r8
	subl	r11, r3, r8
	subl	r12, r4, r8
	subl	r7, r5, r8

	bicl	r10, r10, r2
	bicl	r11, r11, r3
	bicl	r12, r12, r4
	bicl	r7, r7, r5

	tstl	r10, r9
	bset.ne	r6, r6, 4

	tstl	r11, r9
	bset.ne	r6, r6, 3

	tstl	r12, r9
	bset.ne	r6, r6, 2

	tstl	r7, r9
	bset.ne	r6, r6, 1

	brne	r6, 0, @.L_found_in_32B

; Using 128-bit memory operations
#if defined (__ARC64_M128__)

	stdl.ab	r2r3, [r13, +16]
	stdl.ab	r4r5, [r13, +16]

; The 64-bit crunching implementation.
#elif defined (__ARC64_ARCH64__)

	stl.ab	r2, [r13, +8]
	stl.ab	r3, [r13, +8]
	stl.ab	r4, [r13, +8]
	stl.ab	r5, [r13, +8]

#else
# error Unknown configuration
#endif

j 		@.L_4_8B_search_src

.L_found_in_32B:

fls	r6, r6 ; [2]

; Point r13 to first NULL byte containing double word [3]
	sub3l	r1, r1, r6

; Select appropriate register to analyze [4]
	subl	r6, r6, 1
; Invert so the biggest branch is at the end, and we dont need to increase
; block size
	subl	r6, 3, r6

	mpyl	r6, r6, 5

; Store double words
	bi	[r6]

	MOVP	r10, r10
	MOVP	r11, r2
	b	@.L_fix_r1
	nop
	nop

	stl.ab	r2, [r13, +8]
	MOVP	r10, r11
	MOVP	r11, r3
	b	@.L_fix_r1
	nop

	stl.ab	r2, [r13, +8]
	stl.ab	r3, [r13, +8]
	MOVP	r10, r12
	MOVP	r11, r4
	b	@.L_fix_r1

	stl.ab	r2, [r13, +8]
	stl.ab	r3, [r13, +8]
	stl.ab	r4, [r13, +8]
	MOVP	r10, r7
	MOVP	r11, r5


; Point r13 to first NULL byte in selected double word
.L_fix_r1:
	andl	r10, r10, r9 ; [5]

	ffsl	r12, r10 ; [6]
	addl	r12, r12, 1 ; [6]
	xbful 	r12, r12, 0b00111000011 ; [7]

	; 
	subl	r12, 8, r12
	asl		r12, r12, 3

	movl	r10, 0xffffffffffffffff

	lsrl	r10, r10, r12

	notl	r9, r10

	ldl	r2, [r13]

	andl	r3, r10, r11

	andl	r4, r9, r2

	orl		r3, r3, r4
	
	stl.ab	r3, [r13, +8]

	j_s.d	[blink]


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
