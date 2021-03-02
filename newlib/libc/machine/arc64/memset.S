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
; R1: ch
; R2: count
; ret (R0): dest
ENTRY (memset)
	bmsk_s	r1, r1, 7		; treat it like unsigned char
	cmp	r2, 64
	bls.d	@.L_write_1_bytes
	movl	r4, r0			; work on a copy of "r0"
	lsl8	r3, r1
	or_s	r1, r1, r3
	lsl16	r3, r1
	or_s	r1, r1, r3
	; FIXME vpack2wl r1, r1, r1
	mov_s	r3, r1
	addhl	r1, r1, r3
	lsrl	r5, r2, 5		; counter for 32-byte chunks
.L_write_32_bytes:
	stl.ab	r1, [r4, +8]
	stl.ab	r1, [r4, +8]
	stl.ab	r1, [r4, +8]
	dbnz.d	r5, @.L_write_32_bytes
	stl.ab	r1, [r4, +8]
	bmsk_s	r2, r2, 4
.L_write_1_bytes:
	breq	r2, 0, @.L_return
	dbnz.d	r2, @.
	stb.ab	r1, [r4, +1]
.L_return:
	j_s	[blink]
ENDFUNC (memset)
