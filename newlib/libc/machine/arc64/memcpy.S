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
	stl.ab	r4, [r3, +8]
	ldl.ab	r4, [r1, +8]
	stl.ab	r4, [r3, +8]
	ldl.ab	r4, [r1, +8]
	stl.ab	r4, [r3, +8]
	ldl.ab	r4, [r1, +8]
	dbnz.d	r11, @.L_write_32_bytes
	stl.ab	r4, [r3, +8]
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
