/*
 * Copyright (c) 2023, Synopsys, Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1) Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2) Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3) Neither the name of the Synopsys, Inc., nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#if (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED) \
	|| __riscv_xlen == 64 || !defined (__riscv_zbb))
/* See memcmp-stub.c  */
#else

#include <sys/asm.h>


/* Compare two words.  Used registers:
 * a0 the input string pointer A.
 * a1 the input string pointer A.
 * a7 loop bound.
 * clobber: a5, a0(pointer update), a1(pointer update)
 */
.macro check_one_word i n target_loop
	lw    a3, \i*SZREG(a0)
	lw    a4, \i*SZREG(a1)
	xor   a5, a3, a4
	bnez  a5, .LFoundDifferenceInW
	/* last check also inserts address/size fix and loop back.  */
	.if !(\i+1-\n)
	addi  a0, a0, \n*SZREG
	addi  a1, a1, \n*SZREG
	bne   a7, a0, \target_loop
	.endif
.endm

/*
 * Assumptions:
 *  CPU has B extension (clz/ctz)
 *  Memory boundaries are word aligned:
 *    If there are only < SZ(word) bytes left to read, there won't be any fault
 *     if we read the whole SZ(word) bytes
 *
 * Core algorithm:
 *  If size is insufficient (< SZREG*2), go to the final 1 byte loop
 *
 *  Depending on alignment requirements, align both pointers with a 1 byte loop
 *  Only do this if the missalignment matches
 *  If misalignment does not match, do 1 byte loop
 *
 *  The main loop is a five fold unrolled loop of 1 word searches
 *
 *  When size is insufficient for that loop, switch to a 1 word body loop
 *
 *  When there are no more words to read, go to the 1 byte loop
 *
 * A character detector is used based on
 * https://graphics.stanford.edu/~seander/bithacks.html##ValueInWord
 * This detector places a 0 in the bytes that dont match the target
 * character and != 0 if it matches. We can then infer the position of
 * the differing byte with a few arithmetic operations (including
 * masking according to the remaining bytes) instead of recurring to a
 * one byte loop.
 */

/* a0 : input string pointer A
 * a1 : input string pointer B
 * a2 : input n characters
 * ret (a0) : integer according to whether the operation was successfully
 * clobber : a0, a1, a2, a3, a4, a5, a6, a7
 */
	.text
	.globl memcmp
	.type  memcmp, @function
memcmp:
	# Small sizes go directly to one byte loop
	li    a5, SZREG*2
	bltu  a2, a5, .LBloopHead

#ifndef MISALIGN_OK
	/* N.B.  MISALIGN_OK is not defined by the toolchain.  */
	andi  a3, a0, SZREG-1
	andi  a4, a1, SZREG-1
	/* No misalignment.  */
	or    a5, a3, a4
	beqz  a5, .LMainLoopHead
	/* Unequal misalignment, go to 1 byte loop.  */
	bne   a4, a3, .LBloopHead
	/* Adjust alignment.  */
	li    a4, SZREG
	sub   a4, a4, a3
	sub   a2, a2, a4
	add   a7, a0, a4
.LAlignmentLoop:
	lbu   a3, 0(a0)
	lbu   a4, 0(a1)
	bne   a3, a4, .LReturnDifference
	addi  a0, a0, 1
	addi  a1, a1, 1
	bne   a7, a0, .LAlignmentLoop
	/* Fall through to main loop head.  */
#endif /* MISALIGN_OK */

.LMainLoopHead:
	/* Round a2 down to the closest multiple of the main loop body size.  */
	li    a6, SZREG*5
	rem   a6, a2, a6
	sub   a2, a2, a6
	beqz  a2, .LWLoopHead
	add   a7, a0, a2

	/* 5 word loop.  */
.LMainloop:
	check_one_word 0 5 .LMainloop
	check_one_word 1 5 .LMainloop
	check_one_word 2 5 .LMainloop
	check_one_word 3 5 .LMainloop
	check_one_word 4 5 .LMainloop

	/* Fall through to 1 word loop
	 * Check remaining words */
.LWLoopHead:
	li    a5, SZREG
	rem   a5, a6, a5
	sub   a2, a6, a5
	mv    a6, a5
	beqz  a2, .LRemainderBytes
	add   a7, a0, a2

.LWloop:
	check_one_word 0 1 .LWloop

.LRemainderBytes:
	/* Do we have remaining bytes?  */
	mv    a2, a6
	bnez  a2, .LParseW
	/* Fall through, no difference found in multi-word loop and
	 * word loop.  */
.LNoDifference:
	lui   a0, 0
	ret

	/* Look into final word.  */
.LParseW:
	lw    a3, 0(a0)
	lw    a4, 0(a1)
	/* Convert the number of remaining bytes into a mask.  */
	slli  a6, a6, 3
	li    a5, -1
	sll   a5, a5, a6
	not   a5, a5
	/* Remove unwanted data.  */
	and   a3, a3, a5
	and   a4, a4, a5
	/* Check difference.  */
	xor   a5, a3, a4
	beqz  a5, .LNoDifference
	/* Fallthrough (a5 was not zero, there is a difference!).
	 * The difference is in the last words read (in a3 and a4).  */
.LFoundDifferenceInW:

	/* Set a5 to the amount of bits we need to shift the loaded
	 * word so the result is in the first byte.  */
#if  __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
	clz   a5, a5
#else
	ctz   a5, a5
#endif
	srli  a5, a5, 3
	slli  a5, a5, 3
	/* Isolate target byte.  */
	srl   a3, a3, a5
	srl   a4, a4, a5
	andi  a4, a4, 0xFF
	andi  a3, a3, 0xFF
	/* Return the difference.  */
	sub   a0, a3, a4
	ret

	/* The 1 byte loop is the smallest code possible, fall through
	 * to it.  */
.LBloopHead:
	/* Setup a7 for size checking (instead of 'a2--; bnez a2' we
	 * can do 'beq a7, a0') */
	add   a7, a0, a2
	/* If the loop below immediately exits due to reaching the end
	 * of size, we need to propperly setup the 'return 0;'.  */
	mv    a3, a4

	/* 1 byte loop.  */
.LBloop:
	beq   a7, a0, .LReturnDifference
	lbu   a3, 0(a0)
	lbu   a4, 0(a1)
	addi  a0, a0, 1
	addi  a1, a1, 1
	beq   a3, a4, .LBloop

.LReturnDifference:
	sub   a0, a3, a4
	ret

#endif /* (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)) \
	|| __riscv_xlen == 64 || !defined(__riscv_zbb) */

