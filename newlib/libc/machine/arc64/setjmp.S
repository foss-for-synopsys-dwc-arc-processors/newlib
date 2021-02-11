/*
   Copyright (c) 2019, Synopsys, Inc. All rights reserved.

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

/* ABI interface file
   these are the stack mappings for the registers
   as stored in the ABI for ARC */

       .file "setjmp.S"

ABIr14	= 0
ABIr15	= ABIr14 + 8
ABIr16	= ABIr15 + 8
ABIr17	= ABIr16 + 8
ABIr18	= ABIr17 + 8
ABIr19	= ABIr18 + 8
ABIr20	= ABIr19 + 8
ABIr21	= ABIr20 + 8
ABIr22	= ABIr21 + 8
ABIr23	= ABIr22 + 8
ABIr24	= ABIr23 + 8
ABIr25	= ABIr24 + 8
ABIr26	= ABIr25 + 8
ABIr27	= ABIr26 + 8
ABIr28	= ABIr27 + 8
ABIr29	= ABIr28 + 8
ABIr30	= ABIr29 + 8
ABIr31	= ABIr30 + 8


ENTRY (setjmp)
	stl	r14, [r0, ABIr14]
	stl	r15, [r0, ABIr15]
	stl	r16, [r0, ABIr16]
	stl	r17, [r0, ABIr17]
	stl	r18, [r0, ABIr18]
	stl	r19, [r0, ABIr19]
	stl	r20, [r0, ABIr20]
	stl	r21, [r0, ABIr21]
	stl	r22, [r0, ABIr22]
	stl	r23, [r0, ABIr23]
	stl	r24, [r0, ABIr24]
	stl	r25, [r0, ABIr25]
	stl	r26, [r0, ABIr26]
	stl	r27, [r0, ABIr27]
	stl	r28, [r0, ABIr28]
	stl	r29, [r0, ABIr29]
	stl	r30, [r0, ABIr30]
	stl	blink, [r0, ABIr31]

	j.d	[blink]
	mov	r0,0
	.size	setjmp,.-setjmp

ENTRY (longjmp)
	; load registers
	ldl	r14, [r0, ABIr14]
	ldl	r15, [r0, ABIr15]
	ldl	r16, [r0, ABIr16]
	ldl	r17, [r0, ABIr17]
	ldl	r18, [r0, ABIr18]
	ldl	r19, [r0, ABIr19]
	ldl	r20, [r0, ABIr20]
	ldl	r21, [r0, ABIr21]
	ldl	r22, [r0, ABIr22]
	ldl	r23, [r0, ABIr23]
	ldl	r24, [r0, ABIr24]
	ldl	r25, [r0, ABIr25]
	ldl	r26, [r0, ABIr26]
	ldl	r27, [r0, ABIr27]
	ldl	r28, [r0, ABIr28]
	ldl	r29, [r0, ABIr29]
	ldl	r30, [r0, ABIr30]
	ldl	blink, [r0, ABIr31]

	mov.f	r1, r1			; to avoid return 0 from longjmp
	mov.eq	r1, 1
	j.d	[blink]
	mov	r0,r1
	.size	longjmp,.-longjmp
