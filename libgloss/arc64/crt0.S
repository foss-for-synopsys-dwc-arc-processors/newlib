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

;;;  Clear the bss segment.
	movhl_s	r0,@__sbss_start	; r0 = start of the bss section
	orl_s	r0,r0,@__sbss_start
	movhl_s	r2,@_end
	orl_s	r2,r2,@_end
	subl	r2,r2,r0		; r2 = size of the bss section in bytes
	movl_s	r1,0
	bl	@memset

	movl_s	r0,0		;r0 = argc
	movl_s	r1,0		;r1 = argv
	movl_s	r2,0		;r2 = envp = NULL
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
	flag	1
	b	@_exit_halt
	.size	_exit_halt, .-_exit_halt

#endif /* __ARC64__ */
