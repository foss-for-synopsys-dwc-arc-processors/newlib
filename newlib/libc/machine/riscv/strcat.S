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
/* See memcmp-stub.c  */
#else

#include <sys/asm.h>

.text
.global strcat
.type   strcat, @function

/*
 * Assumptions:
 *  CPU has B extension (clz/ctz)
 *  Memory boundaries are word aligned:
 *    If there are only < SZ(word) bytes left to read, there won't be any fault
 *     if we read the whole SZ(word) bytes
 *
 * Core algorithm:
 *  If the destination string is misaligned, align it
 *
 *  Find the end of the dest string (similar logic to our optimized strlen)
 *
 *  If the end of dst and the start of src are misaligned with matching
 *   misalignments, we perform a 1 byte alignment loop
 *  If the misalignments don't match, we go into a 1 byte loop
 *
 *  The main loop is a five fold unrolled loop of 1 word copies
 *
 * A NULL detector is used based on
 * https://graphics.stanford.edu/~seander/bithacks.html##ZeroInWord
 * This detector places a 0 in the bytes that dont have a NULL and != 0 if it 
 * does. We can then infer the position of the first NULL byte with a few
 * arithmetic operations instead of recurring to a 1 byte loop
 */

strcat:

  .macro find_null
    and t0, a2, a5
    or  t1, a2, a5
    add t0, t0, a5
    or  t0, t0, t1
  .endm

  mv  a3, a0
  # Get to the end of dst string
#ifndef MISALIGN_OK
  andi  a2, a3, SZREG-1
  # No misalignment
  beqz  a2, .LWLoopHead

.LDestAlignLoop:
  lbu   a4, 0(a3)
  addi  a3, a3, 1
  beqz  a4, .LFoundDstDuringAlignment
  andi  a6, a3, SZREG-1
  bnez  a6, .LDestAlignLoop
  # Fall through to main loop head
#endif /* MISALIGN_OK */

.LWLoopHead:
  li    a5, 0x7f7f7f7f
  li    t5, -1

.LWLoop:
  lw    a2, 0(a3)
  find_null
  add   a3, a3, 4
  beq   t0, t5, .LWLoop
  not   t4, t0
#if  __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
  clz   t4, t4
#else
  ctz   t4, t4
#endif
  srli  t0, t4, 3
  add   a3, a3, t0
  add   a3, a3, -3
.LFoundDstDuringAlignment:
  add   a3, a3, -1

  # a3 is now positioned at the end of dst
  # Look for NULL in word, copy entire word if not found
  # If found, jump to respective found_in_word
  .macro check_one_word i n
    lw  a2, \i*SZREG(a1)
    find_null
    # Found NULL?
    bne t0, t5, .LFoundSrcNullIn\i
    sw  a2, \i*SZREG(a3)
    # last check also inserts address/size fix and loop back
    .if !(\i+1-\n)
      add a1, a1, \n*SZREG
      add a3, a3, \n*SZREG
      j   .LMainLoop
    .endif
    # fall through to word by word loop
  .endm

  # Adjust size of pointers to words already processed
  .macro found_in_word i n
    .LFoundSrcNullIn\i:
      add a1, a1, \i*SZREG
      add a3, a3, \i*SZREG
      # Last label falls through
      .if \i+1-\n
        j .L1BLoop
      .endif
  .endm

#ifndef MISALIGN_OK
  andi  a4, a3, SZREG-1
  andi  a6, a1, SZREG-1
  # No misalignment
  or    a6, a6, a4
  beqz  a6, .LMainLoop
  # Unequal misalignment
  bne   a6, a4, .L1BLoop
  # Alignment loop
.LAlignBothLoop:
  lbu   a4, 0(a1)
  sb    a4, 0(a3)
  addi  a3, a3, 1
  addi  a1, a1, 1
  beqz  a4, .LReturn
  andi  a6, a3, SZREG-1
  bnez  a6, .LAlignBothLoop
  # Fall through to main loop head
#endif /* MISALIGN_OK */

.LMainLoop:
  check_one_word 0 5
  check_one_word 1 5
  check_one_word 2 5
  check_one_word 3 5
  check_one_word 4 5

  found_in_word 0 5
  found_in_word 1 5
  found_in_word 2 5
  found_in_word 3 5
  found_in_word 4 5
  # Fall through to .L1BLoop

.L1BLoop:
  lbu   a2, 0(a1)
  sb    a2, 0(a3)
  add   a3, a3, 1
  add   a1, a1, 1
  bnez  a2, .L1BLoop

.LReturn:
  ret

#endif /* (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)) \
          || __riscv_xlen == 64 || !defined(__riscv_zbb) */
