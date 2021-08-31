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

; This file contains variants of the same function with different
; instructions.  The generic one, the implementation that comes the
; last after the #else macro, is the most commented.

; Using 128-bit memory operations
#if defined (__ARC64_M128__)

ENTRY (memcpy)
	lsrl.f	r12, r2, 6
	beq.d	@.L_write_1_bytes
	movl	r3, r0
.L_write_64_bytes:
	lddl.ab	r4r5, [r1, +16]
	lddl.ab	r6r7, [r1, +16]
	lddl.ab	r8r9, [r1, +16]
	lddl.ab	r10r11, [r1, +16]
	stdl.ab	r4r5, [r3, +16]
	stdl.ab	r6r7, [r3, +16]
	stdl.ab	r8r9, [r3, +16]
	dbnz.d	r12, @.L_write_64_bytes
	stdl.ab	r10r11, [r3, +16]
.L_write_1_bytes:
	bmsk.f	r2, r2, 5
	jeq	[blink]
1:
	ldb.ab	r4, [r1, +1]
	dbnz.d	r2, @1b
	stb.ab	r4, [r3, +1]
	j_s	[blink]
ENDFUNC (memcpy)

; The generic implementation without any frills.
#else

; R0: dest
; R1: source
; R2: count
; ret (R0): dest
ENTRY (memcpy)
	cmp	r2, 64
	bls.d	@.L_write_1_bytes
	movl	r3, r0			; do not clobber the "dest"
	lsrl	r11, r2, 5		; counter for 32-byte chunks
.L_write_32_bytes:
	ldl.ab	r4, [r1, +8]
	ldl.ab	r5, [r1, +8]
	ldl.ab	r6, [r1, +8]
	ldl.ab	r7, [r1, +8]
	stl.ab	r4, [r3, +8]
	stl.ab	r5, [r3, +8]
	stl.ab	r6, [r3, +8]
	dbnz.d	r11, @.L_write_32_bytes
	stl.ab	r7, [r3, +8]
	bmsk_s	r2, r2, 4
.L_write_1_bytes:
	breq	r2, 0, @.L_return
1:
	ldb.ab	r4, [r1, +1]
	dbnz.d	r2, @1b
	stb.ab	r4, [r3, +1]
.L_return:
	j_s	[blink]
ENDFUNC (memcpy)

; if !defined (__ARC64_M128__)
#endif
