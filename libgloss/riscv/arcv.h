/*
   Copyright (c) 2024, Synopsys, Inc. All rights reserved.

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

#ifndef _ARCV_H
#define _ARCV_H

#define CSR_NUM_MARCHID                     0xF12
#define ARCV_MARCHID_FAMILY_OFFSET          0x0
#define ARCV_MARCHID_FAMILY_MASK            0xFF
#define ARCV_MARCHID_RMX_VALUE              0x01
#define ARCV_MARCHID_RHX100_VALUE           0x02

#define CSR_NUM_ARCV_MEXEC_CTRL             0x7C5
#define ARCV_MEXEC_DUAL_ISSUE_OFFSET        0x0
#define ARCV_MEXEC_FUSION_OFFSET            0x2
#define ARCV_MEXEC_FUSION_CTRL_OFFSET       0x8
#define ARCV_MEXEC_FUSION_CTRL_MASK         0x3FFF

#define CSR_NUM_ARCV_MCACHE_CTRL            0x7C8
#define ARCV_MCACHE_CTRL_IC_EN_OFFSET       0x0
#define ARCV_MCACHE_CTRL_DC_EN_OFFSET       0x8
#define ARCV_MCACHE_CTRL_DC_L0_EN_OFFSET    0xC
#define ARCV_MCACHE_CTRL_L2_EN_OFFSET       0x10

inline unsigned long __attribute__((always_inline))
_arcv_csr_read (int csr_num)
{
  unsigned long result;
  __asm__ __volatile__("csrr %0, %1" : "=r"((result)) : "i"((csr_num)));
  return result;
}

inline void __attribute__((always_inline))
_arcv_csr_write (int csr_num, unsigned long data)
{
  __asm__ __volatile__("csrw %0, %1" :: "i"(csr_num), "r"(data));
}

void _arcv_cache_enable ();
void _arcv_fusion_enable ();
void _arcv_dual_issue_enable ();

#endif
