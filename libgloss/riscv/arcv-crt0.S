/* Copyright (c) 2024  Synopsys. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.

   This file is based on default crt0.S file.
*/

#include "newlib.h"

#=========================================================================
# crt0.S : Entry point for RISC-V user programs
#=========================================================================

	.text
	.global _start
	.type   _start, @function
_start:
	.cfi_startproc

	# Initialize global pointer.  This is done with relaxation
	# disabled, not to end up with only "addi gp,gp,0"
	.option push
	.option norelax
1:
	auipc gp, %pcrel_hi(__global_pointer$)
	addi  gp, gp, %pcrel_lo(1b)
	.option pop

	# Initialize SP pointer. Similarly, we disable the relaxation.
	.option push
	.option norelax
1:
	auipc sp, %pcrel_hi(__stack_pointer$)
	addi  sp, sp, %pcrel_lo(1b)
	.option pop

	# Initialize FPU if it is presented. 8192 stands for 1 << 13 bit offset -
	# the first bit of FS[1:0] field of mstatus CSR.
#ifdef __riscv_flen
	csrr    t0, mstatus
	li      t1, 8192
	or      t0, t1, t0
	csrw    mstatus, t0
	csrwi   fcsr, 0
#endif

	# Clear the bss segment
	la      a0, __bss_start
	la      a2, _end
	sub     a2, a2, a0
	li      a1, 0
	call    memset
#ifdef _LITE_EXIT
	# Make reference to atexit weak to avoid unconditionally pulling in
	# support code.  Refer to comments in __atexit.c for more details.
	.weak   atexit
	la      a0, atexit
	beqz    a0, .Lweak_atexit
	.weak   __libc_fini_array
#endif

	la      a0, __libc_fini_array   # Register global termination functions
	call    atexit                  #  to be called upon exit
#ifdef _LITE_EXIT
.Lweak_atexit:
#endif
	call    __libc_init_array       # Run global initialization functions

#if defined (__riscv_zicsr)
	# ARC-V specific initialization
	call    _arcv_cache_enable       # Enable caches
	call    _arcv_dual_issue_enable  # Enable dual issue
	call    _arcv_fusion_enable      # Enable instruction fusion
#endif

	# Get arguments from custom symbols if they are defined. Otherwise,
	# get them from the stack.
	.weak _argc
	.weak _argv
	la      a0, _argc
	beqz    a0, .Lempty_args
	la      a1, _argv
	beqz    a1, .Lempty_args
	lw      a0, 0(a0)
	j       .Lmain

.Lempty_args:
	mv      a0, zero
	mv      a1, zero

.Lmain:
	mv      a2, zero
	call    main
	tail    exit
	.cfi_endproc
	.size  _start, .-_start
