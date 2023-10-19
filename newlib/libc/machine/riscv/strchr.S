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
/* See strchr-stub.c  */
#else

#include <sys/asm.h>

.text
.global strchr
.type   strchr, @function

/*
 * Assumptions:
 *  CPU has B extension (clz/ctz)
 *  Memory boundaries are word aligned:
 *    If there are only < SZ(word) bytes left to read, there won't be any fault
 *     if we read the whole SZ(word) bytes
 *
 * Core algorithm:
 *  Depending on alignment requirements, align the pointer with a 1 byte loop
 *  If misalignment does not match, do 1 byte loop
 *
 * The main body is a simple 1 word loop
 *
 * A NULL detector is used based on
 * https://graphics.stanford.edu/~seander/bithacks.html##ZeroInWord and
 * https://graphics.stanford.edu/~seander/bithacks.html##ValueInWord
 * This detector places a 0 in the bytes that dont have a NULL, nor the target
 * byte and != 0 if it does. We can then infer the position of the first match
 * and check if it is NULL (string ended) or the matched character
 */

strchr:

  .macro char_or_null_check
    xor   a2,a4,a7
    add   a5,a4,a6
    add   a3,a2,a6
    andn  a5,a5,t2
    andn  t2,a3,a2
    or    a5,a5,t2
    and   a5,a5,t1
  .endm

#ifndef MISALIGN_OK
  andi  a2, a0, SZREG-1
  # No misalignment
  beqz  a2, .LMainLoopHead
.LAlignLoop:
  lbu   a3, 0(a0)
  beq   a3, a1, .LFoundTargetByte
  beqz  a3, .LFoundNulll
  addi  a0, a0, 1
  andi  a2, a0, SZREG-1
  bnez  a2, .LAlignLoop
  # Fall through to main loop head
#endif /* MISALIGN_OK */

.LMainLoopHead:
  # Build char and NULL detectors
  lui   t1, 0x80808
  lui   a6, 0xfeff0
  slli  a7, a1, 8
  add   t1, t1,128
  or    a7, a7, a1
  add   a6, a6,-257
  # Check first word aligned with a0 outside the loop
  # So inside we can search one word "ahead", removing the need to pull back a0
  # when we find anything
  lw    a4, 0(a0)
  slli  a5, a7, 16
  or    a7, a7, a5
  char_or_null_check
  bnez  a5, .LFoundSomething

.LMainLoop:
  lw    a4, 4(a0)
  add   a0, a0, 4
  char_or_null_check
  beqz  a5, .LMainLoop

.LFoundSomething:
#if  __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
  clz   a5, a5
#else
  ctz   a5, a5
#endif
  srli  a5, a5, 3
  slli  a6, a5, 3
  srl   a4, a4, a6
  and   a4, a4, 0xff
  beq   a4, a1, .LFoundTarget

  # Fallthrough, if its not the target byte, must be NULL
.LFoundNulll:
  li  a0, 0

.LFoundTargetByte:
  ret

.LFoundTarget:
  add a0, a0, a5
  ret

#endif /* (defined (__OPTIMIZE_SIZE__) || defined (PREFER_SIZE_OVER_SPEED)) \
          || __riscv_xlen == 64 || !defined(__riscv_zbb) */

