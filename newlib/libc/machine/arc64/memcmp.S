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

#include "asm.h"

; R0: lhs
; R1: rhs
; R2: count
; ret (R0):
;   - lhs < rhs: <0
;   - lhs = rhs:  0
;   - lhs > rhs: >0
ENTRY (memcmp)
	cmp	r2, 64
	bls.d	@.L_compare_1_bytes
	movl	r3, r0		; soon "r0" will be used as return value
	lsrl	r11, r2, 5	; counter for 32-byte chunks
	; If one is curious why the code below looks like the way it does, it
	; is possible to consult the documentation at the end of this file.
	ldl.ab	r4, [r3, +8]
	b.d	@1f		; go to the start of the loop without
	ldl.ab	r6, [r1, +8]	; checking "r8 == r10".
.L_compare_32_bytes:
	brnel.d	r8,  r10, @.L_8_byte_unequal_r8r10
	ldl.ab	r6,  [r1, +8]
1:
	ldl.ab	r8,  [r3, +8]
	brnel.d	r4,  r6, @.L_8_byte_unequal_r4r6
	ldl.ab	r10, [r1, +8]
	ldl.ab	r4,  [r3, +8]
	brnel.d	r8,  r10, @.L_8_byte_unequal_r8r10
	ldl.ab	r6,  [r1, +8]
	ldl.ab	r8,  [r3, +8]
	brnel.d	r4,  r6, @.L_8_byte_unequal_r4r6
	ldl.ab	r10, [r1, +8]
	dbnz.d	r11, @.L_compare_32_bytes
	ldl.ab	r4,  [r3, +8]	; may access beyond the "count"
	; Wrapping up the last loop by making one last compare
	; and adjusting the pointer because of an extra load
	; in the end
	brnel.d	r8,  r10, @.L_8_byte_unequal_r8r10
	subl	r3, r3, 8
	bmsk_s	r2, r2, 4
.L_compare_1_bytes:
	breq.d	r2, 0, @.L_return
	xor_s	r0, r0, r0
	ldb.ab	r4, [r3, +1]	
2:
	ldb.ab	r6, [r1, +1]
	brne.d	r4, r6, @.L_return
	sub	r0, r4, r6	; delay slot exits, we might as well use it.
	dbnz.d	r2, @2b
	ldb.ab	r4, [r3, +1]	; this load may read beyond the "count".
.L_return:
	j_s	[blink]
.L_8_byte_unequal_r4r6:
	movl	r1, r4
	b.d	@.L_diff_byte_in_regs
	movl	r2, r6
.L_8_byte_unequal_r8r10:
	movl	r1, r8
	movl	r2, r10
; If we're here, that means the two operands are not equal.
; 1) First we have to get a mask of their inequality through "xor"
; 2) Then, find the first bit position that they're different: "ffs"
; 3) Depending on the bit position, we want the whole byte containing
;    that bit, in both operands, becomes the very first byte (least
;    significant byte), so that we can subtract one from another.
;    Below is an illustration of bit positions and how much we should
;    shift the numbers right:
;    bit position range : (in binary)       | shift right by : (in binary)
;    -------------------+-------------------+----------------+------------
;    [ 0, 7]            : (000000 - 000111) | lsr  0         : 000000
;    [ 8,15]            : (001000 - 001111) | lsr  8         : 001000
;    [16,23]            : (010000 - 010111) | lsr 16         : 010000
;    [24,31]            : (011000 - 011111) | lsr 24         : 011000
;    ...                : ...               | ...            : ...
;    [56,63]            : (111000 - 111111) | lsr 56         : 111000
;    We need to ignore the least 3 bits of "position" to get "shift right"
;    amount: "and 0x38, ..."
; 4) When the bytes are positioned at byte #0, mask out the rest of the
;    bytes and subtract the two operands: lhs - rhs
.L_diff_byte_in_regs:
	xorl	r0, r1, r2	; (1)
	ffsl	r0, r0		; (2)
	and	r0, r0, 0x38	; (3)
	lsrl	r1, r1, r0	; (3)
	lsrl	r2, r2, r0	; (3)
	bmsk_s	r1, r1, 7	; (4)
	bmsk_s	r2, r2, 7	; (4)
	j_s.d	[blink]
	subl	r0, r1, r2	; (4)
ENDFUNC (memcmp)

; The 32-byte loop at the heart of the "memcmp" function has gone through
; a few optimisation filters.  Knowing the transformations will help
; in understanding the logic of the final code.
;
; 1) At first, we have the unrolled loop to process 32-byte chunks
;      1:
;        ldl.ab r4, [r3, 8]
;        ldl.ab r6, [r1, 8]
;        brnel  r4, r6, @.L_unequal
;        ldl.ab r4, [r3, 8]
;        ldl.ab r6, [r1, 8]
;        ...
;        brnel  r4, r6, @.L_unequal
;        dbnz   r11, @1b
;
; 2) We would like to create a gap between the "loads" and the "branch"
;    instruction that consumes them.  For that purpose, we use two more
;    registers (r8, r10) and intertwine the "load"s and "compare"s:
;      ldl.ab r4, [r3, 8]
;      ldl.ab r6, [r1, 8]
;      brnel  r8, r10, @.L_unequal_r8r10
;      ldl.ab r8, [r3, 8]
;      ldl.ab r10, [r1, 8]
;      brnel  r4, r6, @.L_unequal_r4r6
;      ...
;    The first "brnel r8, r10" during the first iteration of the loop
;    does not hold the correct data.  In order to adjust for that, before
;    entering the loop, we will load the data into "r4" and "r6" and then
;    instead of a "fall-through" to the loop body, we jump after the first
;    "brnel r8, r10":
;        ldl.ab r4, [r3, 8]
;        ldl.ab r6, [r1, 8]
;        b      @2f
;    1:
;        ldl.ab r4, [r3, 8]
;        ldl.ab r6, [r1, 8]
;        brnel  r8, r10, @.L_unequal_r8r10
;    2:
;        ldl.ab r8, [r3, 8]
;        ldl.ab r10, [r1, 8]
;        brnel  r4, r6, @.L_unequal_r4r6
;        ldl.ab r4, [r3, 8]
;        ldl.ab r6, [r1, 8]
;        brnel  r8, r10, @.L_unequal_r8r10
;        ldl.ab r8, [r3, 8]
;        ldl.ab r10, [r1, 8]
;        brnel  r4, r6, @.L_unequal_r4r6
;        dbnz   r11, @1b
;        brnel  r8, r10, @.L_unequal_r8r10
;    Take a note of the extra "brnel" added after the "dbnz" which will
;    compare the result of the last "loads" into "r8" and "r10".  In the
;    beginning we made 4 loads before starting to compare (each compare
;    consumes 2 loads), so this extra "brnel" is only catching up.
;
; 3) Time to fill the delay slot of all those "brnel":
;        ldl.ab r4, [r3, 8]
;        b.d    @2f                          ; filled with what used
;        ldl.ab r6, [r1, 8]                  ; to be previous inst.
;    1:
;        ldl.ab  r4, [r3, 8]
;        brnel.d r8, r10, @.L_unequal_r8r10  ; filled with what used
;        ldl.ab  r6, [r1, 8]                 ; to be previous inst.
;    2:
;        ldl.ab  r8, [r3, 8]
;        brnel.d r4, r6, @.L_unequal_r4r6    ; filled with what used
;        ldl.ab  r10, [r1, 8]                ; to be previous inst.
;        ...
;        brnel.d r4, r6, @.L_unequal_r4r6    ; filled with what used
;        ldl.ab  r10, [r1, 8]                ; to be previous inst.
;        dbnz    r11, @1b                    ; cannot be filled (yet)
;        brnel  r8, r10, @.L_unequal_r8r10   ; cannot be filled (yet)
;
; 4) Since "dbnz" could benefit from having a loop _body_ instruction
;    in its delay slot, the first "load" in the beginning of the loop
;    body can come to the end of the loop, so it can fill "dbnz.d".
;    That is possible because that code chunk was skipped during the
;    first iteration and have spilled before the loop start:
;        ldl.ab r4, [r3, 8]
;        b.d    @2f
;        ldl.ab r6, [r1, 8]
;    1:
;        brnel.d r8, r10, @.L_unequal_r8r10
;        ldl.ab  r6, [r1, 8]
;    2:
;        ldl.ab  r8, [r3, 8]
;        ...
;        brnel.d r4, r6, @.L_unequal_r4r6
;        ldl.ab  r10, [r1, 8]
;        dbnz.d  r11, @1b                    ; filled!
;        ldl.ab  r4, [r3, 8]
;    There is one catch though:  During the _last_ iteration, that
;    "load" is executed once too many.  To correct for that:
;        ...
;        ldl.ab  r10, [r1, 8]
;        dbnz.d  r11, @1b
;        ldl.ab  r4, [r3, 8]
;        subl    r3, r3, 8                   ; adjusting instruction
;        brnel   r8, r10, @.L_unequal_r8r10  ; not filled yet!
;        ...
;    Last bit of the puzzle falls into its place:  The "brnel" outside
;    the loop can be filled with this "subl" instruction:
;        ...
;        ldl.ab  r10, [r1, 8]
;        dbnz.d  r11, @1b
;        ldl.ab  r4, [r3, 8]
;        brnel.d r8, r10, @.L_unequal_r8r10  ; filled by the 
;        subl    r3, r3, 8                   ; adjusting instruction
;        ...
