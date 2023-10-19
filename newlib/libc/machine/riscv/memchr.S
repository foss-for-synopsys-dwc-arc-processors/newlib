/*
Copyright (c) 2023, Synopsys, Inc. All rights reserved.

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

#if (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)) \
    || __riscv_xlen == 64 || !defined(__riscv_zbb)
/* See memchr-stub.c  */
#else

#include <sys/asm.h>

.text
.globl memchr
.type  memchr, @function

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
 *  Depending on alignment requirements, align the pointer with a 1 byte loop
 *
 *  The main loop is a five fold unrolled loop of 1 word searches
 *
 *  When size is insufficient for that loop, switch to a 1 word body loop
 *
 *  When there are no more words to read, go to the 1 byte loop
 *
 * A character detector is used based on
 * https://graphics.stanford.edu/~seander/bithacks.html##ValueInWord
 * This detector places a 0 in the bytes that dont match the target character
 * and != 0 if it matches. We can then infer the position of the differing byte
 * with a few arithmetic operations (including masking according to the
 *  remaining bytes) instead of recurring to a 1 byte loop
 */

memchr:

  .macro check_one_word i n target_loop
    lw    a4, 0(a0)
    # Detect target byte
    xor   a4, a4, a3
    add   t0, a4, a5
    andn  a4, t0, a4
    and   a4, a4, t2
    bnez  a4, .LFoundTargetInW
    addi  a0, a0, SZREG
    # last check also inserts address/size fix and loop back
    .if !(\i+1-\n)
      bne   a7, a0, \target_loop
    .endif
    # fall through to word by word loop
  .endm

  # Small sizes go directly to one byte loop
  li    a5, SZREG*2
  bltu  a2, a5, .LBloopHead

#ifndef MISALIGN_OK
  andi  a3, a0, SZREG-1
  # No misalignment
  beqz  a3, .LMainLoopHead
  # Adjust alignment
  li    a4, SZREG
  sub   a4, a4, a3
  sub   a2, a2, a4
  add   a4, a4, a0

.LAlign1BLoop:
  lbu   a3, 0(a0)
  sub   a3, a3, a1
  beqz  a3, .LFoundTargetInB
  addi  a0, a0, 1
  bne   a4, a0, .LAlign1BLoop
  # Fall through to main loop head
#endif /* MISALIGN_OK */

.LMainLoopHead:
  # Setup char detector
  lui   a5, 0xfeff0
  add   a5, a5, -257
  lui   t2, 0x80808
  add   t2, t2, 128

  # Setup SZREG byte repetition of target byte
  slli  a3, a1, 8
  or    a3, a3, a1
  slli  a4, a3, 16
  or    a3, a3, a4

  #  Round a2 down to the closest multiple of the main loop body size
  li    a6, SZREG*5
  rem   a6, a2, a6
  sub   a2, a2, a6
  beqz  a2, .LWLoopHead
  add   a7, a0, a2

.LMainloop:
  check_one_word 0 5 .LMainloop
  check_one_word 1 5 .LMainloop
  check_one_word 2 5 .LMainloop
  check_one_word 3 5 .LMainloop
  check_one_word 4 5 .LMainloop

.LWLoopHead:
  #   Round a2 down to the remaining words
  li    t3, SZREG
  rem   t3, a6, t3
  sub   a2, a6, t3
  mv    a6, t3
  beqz  a2, .LRemainderBytes
  add   a7, a0, a2

.LWloop:
  check_one_word 0 1 .LWloop

.LRemainderBytes:
  # Do we have remaining bytes?
  mv    a2, a6
  bnez  a2, .LBloopHead
  # Fall through, no difference found
  lui   a0, 0
  ret

.LFoundTargetInW:
#if  __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
  clz   a4, a4
#else
  ctz   a4, a4
#endif
  srli  a4, a4, 3
  add   a0, a0, a4
  ret

.LBloopHead:
  add   a7, a0, a2

  # 1 byte loop
.LBloop:
  beq   a0, a7, .LNotFound
  lbu   a3, 0(a0)
  sub   a3, a3, a1
  addi  a0, a0, 1
  bnez  a3, .LBloop
  # Fallthrough, walk a0 back 1 byte
  addi  a0, a0, -1
.LFoundTargetInB:
  ret

.LNotFound:
  li    a0, 0
  ret

#endif /* (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)) \
          || __riscv_xlen == 64 || !defined(__riscv_zbb) */

