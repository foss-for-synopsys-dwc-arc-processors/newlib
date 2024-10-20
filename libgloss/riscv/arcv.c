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

#include "arcv.h"

void _arcv_cache_enable ()
{
#if defined (__riscv_zicsr)
  unsigned long mcache = _arcv_csr_read(CSR_NUM_ARCV_MCACHE_CTRL);
  mcache |=
    (1 << ARCV_MCACHE_CTRL_IC_EN_OFFSET) |
    (1 << ARCV_MCACHE_CTRL_DC_EN_OFFSET) | 
    (1 << ARCV_MCACHE_CTRL_DC_L0_EN_OFFSET) |
    (1 << ARCV_MCACHE_CTRL_L2_EN_OFFSET);
  _arcv_csr_write(CSR_NUM_ARCV_MCACHE_CTRL, mcache);
#endif
}

void _arcv_dual_issue_enable ()
{
#if defined (__riscv_zicsr)
  unsigned long mexec, family, marchid;

  marchid = _arcv_csr_read(CSR_NUM_MARCHID);
  family = (marchid >> ARCV_MARCHID_FAMILY_OFFSET) & ARCV_MARCHID_FAMILY_MASK;
  if (family != ARCV_MARCHID_RHX100_VALUE) {
    return;
  }

  mexec = _arcv_csr_read(CSR_NUM_ARCV_MEXEC_CTRL);
  mexec = ~mexec;
  mexec |= 1 << ARCV_MEXEC_DUAL_ISSUE_OFFSET;
  mexec = ~mexec;
  _arcv_csr_write(CSR_NUM_ARCV_MEXEC_CTRL, mexec);
#endif
}

void _arcv_fusion_enable ()
{
#if defined (__riscv_zicsr)
  unsigned long mexec, family, marchid;

  marchid = _arcv_csr_read(CSR_NUM_MARCHID);
  family = (marchid >> ARCV_MARCHID_FAMILY_OFFSET) & ARCV_MARCHID_FAMILY_MASK;
  if (family != ARCV_MARCHID_RHX100_VALUE) {
    return;
  }

  mexec = _arcv_csr_read(CSR_NUM_ARCV_MEXEC_CTRL);
  mexec = ~mexec;
  mexec |=
    (1 << ARCV_MEXEC_FUSION_OFFSET) |
    (ARCV_MEXEC_FUSION_CTRL_MASK << ARCV_MEXEC_FUSION_CTRL_OFFSET);
  mexec = ~mexec;
  _arcv_csr_write(CSR_NUM_ARCV_MEXEC_CTRL, mexec);
#endif
}
