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
/* See strlen-stub.c  */
#else

#include <sys/asm.h>

.text
.global strlen
.type   strlen, @function

/*
 * Assumptions:
 *  CPU has B extension (clz/ctz)
 *  Memory boundaries are word aligned:
 *    If there are only < SZ(word) bytes left to read, there won't be any fault
 *     if we read the whole SZ(word) bytes
 *
 * Core algorithm:
 *  Depending on alignment requirements, align the pointer with a 1 byte loop
 *
 * The main body is a simple 1 word loop
 *
 * A NULL detector is used based on
 * https://graphics.stanford.edu/~seander/bithacks.html##ZeroInWord
 * This detector places a 0 in the bytes that dont have a NULL and != 0 if it 
 * does. We can then infer the position of the first NULL byte with a few
 * arithmetic operations instead of recurring to a 1 byte loop
 */

strlen:

  .macro find_null
    and   t0, a2, a5
    or    t1, a2, a5
    add   t0, t0, a5
    or    t0, t0, t1
  .endm

  li    a5, 0x7f7f7f7f
  li    t5, -1
  mv    a1, a0

#ifndef MISALIGN_OK
  andi  a3, a0, SZREG-1
  # No misalignment
  beqz  a3, .LWLoopHead

.LAlignmentLoop:
  lbu   a3, 0(a0)
  beqz  a3, .LFoundInB
  addi  a0, a0, 1
  andi  a3, a0, SZREG-1
  bnez  a3, .LAlignmentLoop
  # Fall through to main loop head
#endif /* MISALIGN_OK */

.LWLoopHead:
  lw    a2, 0(a0)
  find_null
  bne   t0, t5, .LFoundInW

.LWLoop:
  lw    a2, 4(a0)
  find_null
  add   a0, a0, 4
  beq   t0, t5, .LWLoop

.LFoundInW:
  not   t4, t0
#if  __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
  clz   t4, t4
#else
  ctz   t4, t4
#endif
  srli  t0, t4, 3
  add   a0, a0, t0
  sub   a0, a0, a1
  ret

.LFoundInB:
  sub   a0, a0, a1
  ret

#endif /* (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)) \
          || __riscv_xlen == 64 || !defined(__riscv_zbb) */
