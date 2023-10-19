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
    || __riscv_xlen == 64 || !defined(__riscv_zbb) || 1
/* See strcpy-stub.c  */
#else

#include <sys/asm.h>

.text
.global strcpy
.type   strcpy, @function

/*
 * Assumptions:
 *  CPU has B extension (clz/ctz)
 *  Memory boundaries are word aligned:
 *    If there are only < SZ(word) bytes left to read, there won't be any fault
 *     if we read the whole SZ(word) bytes
 *
 * Core algorithm:
 *  Depending on alignment requirements, align both pointers with a 1 byte loop
 *  Only do this if the missalignment matches
 *  If misalignment does not match, do 1 byte loop
 *
 *  The main loop is a five fold unrolled loop of 1 word copies
 *
 * A NULL detector is used based on
 * https://graphics.stanford.edu/~seander/bithacks.html##ZeroInWord
 * This detector places a 0 in the bytes that dont have a NULL and != 0 if it 
 * does. We can then infer the position of the first NULL byte with a few
 * arithmetic operations instead of recurring to a 1 byte loop
 */

strcpy:

  .macro check_one_word i n
    lw  a2, \i*SZREG(a1)
    # Find NULL
    and t0, a2, a5
    or  t1, a2, a5
    add t0, t0, a5
    or  t0, t0, t1
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
      add a1, a1, SZREG
      add a3, a3, SZREG
      # Last label falls through
  .endm

  mv    a3, a0
#ifndef MISALIGN_OK
  andi  a4, a3, SZREG-1
  andi  a6, a1, SZREG-1
  # No misalignment
  or    a6, a6, a4
  beqz  a6, .LMainLoopHead
  # Unequal misalignment
  bne   a6, a4, .L1BLoop

.LAlignLoop:
  lbu   a4, 0(a1)
  sb    a4, 0(a3)
  addi  a3, a3, 1
  addi  a1, a1, 1
  beqz  a4, .LReturn
  andi  a6, a3, SZREG-1
  bnez  a6, .LAlignLoop
  # Fall through to main loop head
#endif /* MISALIGN_OK */

.LMainLoopHead:
  li  a5, 0x7f7f7f7f
  li  t5, -1

.LMainLoop:
  check_one_word 0 5
  check_one_word 1 5
  check_one_word 2 5
  check_one_word 3 5
  check_one_word 4 5

  found_in_word 4 5
  found_in_word 3 5
  found_in_word 2 5
  found_in_word 1 5
# Don't skip the word containing the NULL byte
.LFoundSrcNullIn0:

.LFoundInW:
  not   t4, t0
#if  __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
  clz   t4, t4
#else
  ctz   t4, t4
#endif
  srli  t0, t4, 3
  # Include \0
  addi  t0, t0 ,1
  li    t1, SZREG
  # Jump table for bytes found
  sub   a4, t1, t0
  sll   a4, a4, 3
.LTableHead:
  auipc t0, %pcrel_hi(.LTable)
  add   a4, a4, t0
  jr    a4, %pcrel_lo(.LTableHead)

  # Prevent compression so jump is accurate
.option push
.option norvc
.option push
.option arch, -zcb
.option push
.option arch, -zca
.LTable:
  lbu a2, 4(a1)
  sb  a2, 4(a3)
  lbu a2, 3(a1)
  sb  a2, 3(a3)
  lbu a2, 2(a1)
  sb  a2, 2(a3)
  lbu a2, 1(a1)
  sb  a2, 1(a3)
  lbu a2, 0(a1)
  sb  a2, 0(a3)
.option pop
.option pop
.option pop
  ret

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