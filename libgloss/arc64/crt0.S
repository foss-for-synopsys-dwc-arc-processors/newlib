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

/*
   The startup code for the ARC family of processors does the following before
   transferring control to user defined main label:
       1.  Set sp to __stack_top (link time variable)
       2.  Zero out the bss section (for uninitialized globals)
   After returning from main, the processor is halted and the pipeline is
   flushed out.
*/

#if defined (__ARC64__)
	.file	"crt0.S"
	.extern main

	.section .text.__startup, "ax", @progbits
	.global	__start
	.type	__start, @function
	.align 4
__start:
	movhl_s	sp,@__stack_top		; Stack address
	orl_s	sp,sp,@__stack_top

	; Allow unaligned accesses.
	lr      r2, [0xA]
	bset    r2, r2, 19
	flag    r2

;;;  Clear the bss segment.
	movhl_s	r0,@__sbss_start	; r0 = start of the bss section
	orl_s	r0,r0,@__sbss_start
	movhl_s	r2,@_end
	orl_s	r2,r2,@_end
	subl	r2,r2,r0		; r2 = size of the bss section in bytes
	movl_s	r1,0
	bl	@memset

;;; Clear the registers.
	movl_s	r0,0
	movl_s	r1,0
	movl_s	r2,0
	movl_s	r3,0
	movl_s	r4,0
	movl_s	r5,0
	movl_s	r6,0
	movl_s	r7,0
	movl_s	r8,0
	movl_s	r9,0
	movl_s	r10,0
	movl_s	r11,0
	movl_s	r12,0
	movl_s	r13,0
	movl_s	r14,0
	movl_s	r15,0
	movl_s	r16,0
	movl_s	r17,0
	movl_s	r18,0
	movl_s	r19,0
	movl_s	r20,0
	movl_s	r21,0
	movl_s	r22,0
	movl_s	r23,0
	movl_s	r24,0
	movl_s	r25,0
	movl_s	r26,0
	movl_s	r27,0
	;; SP (r28) is initialized
	movl_s	ilink,0
	movl	r30,0

	;; Call constructors.
	jl	@_init

#if 0
;;; Setup destuctors to be called from exit if main never returns
	movhl_s	blink,@_impure_ptr
	orl_s	blink,blink,@inpure_ptr
	ldl	r1,[blink]
	movhl_s	r0,@_fini
	orl_s	r0,r0,@_fini
	addl	r1,r1,need_find_out	; &_GLOBAL_REENT->atexit0
	stl	r1,[r1,-8]		; _GLOBAL_REENT->atexit
	stl	r0,[r1,16]		; _GLOBAL_REENT->atexit0._fns[0]
	stl	1,[r1,8]		; _GLOBAL_REENT->atexit0._ind
#else
;;; Setup fini routines to be called from exit
	movhl_s	r0,@_fini
	orl_s	r0,r0,@_fini
	jl	@atexit
#endif

;;; Call main() with empty argc/argv/envp
	movl_s	r0,0
	movl_s	r1,0
	movl_s	r2,0
	movl_s	r3,0
	movhl_s	blink,@main
	orl_s	blink,blink,@main
	jl	[blink]

	j	@exit
	.size	__start, .-__start

	.section .text._exit_halt,"ax",@progbits
	.global	 _exit_halt
	.type	 _exit_halt, @function
	.align 4
_exit_halt:
	; r0 contains exit code
	mov	r0,r0
	flag	1
	b	@_exit_halt
	.size	_exit_halt, .-_exit_halt

#endif /* __ARC64__ */
