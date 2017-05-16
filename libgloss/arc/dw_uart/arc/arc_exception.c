/* ------------------------------------------
 * Copyright (c) 2016, Synopsys, Inc. All rights reserved.

 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:

 * 1) Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.

 * 2) Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation and/or
 * other materials provided with the distribution.

 * 3) Neither the name of the Synopsys, Inc., nor the names of its contributors may
 * be used to endorse or promote products derived from this software without
 * specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * \version 2016.05
 * \date 2014-07-15
 * \author Wayne Ren(Wei.Ren@synopsys.com)
--------------------------------------------- */

/**
 * \file
 * \ingroup ARC_HAL_EXCEPTION_CPU ARC_HAL_EXCEPTION_INTERRUPT
 * \brief C Implementation of exception and interrupt management
 */
#include "inc/arc/arc_exception.h"

//#define	 DBG_LESS
//#include "embARC_debug.h"

/**
 * \addtogroup ARC_HAL_EXCEPTION_CPU
 * @{
 * \var exc_entry_table
 * \brief exception entry table
 *
 * install exception entry table to ARC_AUX_INT_VECT_BASE in startup.
 * According to ARCv2 ISA, vectors are fetched in instruction space and thus
 * may be present in ICCM, Instruction Cache, or
 * main memory accessed by instruction fetch logic.
 * So it is put into a specific section .vector.
 *
 * Please note that the exc_entry_table maybe cached in ARC. Some functions is
 * defined in .s files.
 *
 */

/**
 * \ingroup ARC_HAL_EXCEPTION_CPU
 * \brief  default cpu exception handler
 * \param p_excinf pointer to the exception frame
 */
static void exc_handler_default(void *p_excinf)
{
	uint32_t excpt_cause_reg = 0;
	uint32_t excpt_ret_reg = 0;
	uint32_t exc_no = 0;

	excpt_cause_reg = __builtin_arc_lr(AUX_ECR);
	excpt_ret_reg = __builtin_arc_lr(AUX_ERRET);
	exc_no = (excpt_cause_reg >> 16) & 0xff;

	//dbg_printf(DBG_LESS_INFO, "default cpu exception handler\r\n");
	//dbg_printf(DBG_LESS_INFO, "exc_no:%d, last sp:0x%08x, ecr:0x%08x, eret:0x%08x\r\n",
		//exc_no, (uint32_t)p_excinf, excpt_cause_reg, excpt_ret_reg);
	Asm("kflag 1");
}


/**
 * \ingroup ARC_HAL_EXCEPTION_INTERRUPT
 * \brief  default interrupt handler
 * \param[in] p_excinf	information for interrupt handler
 */
static void int_handler_default(void *p_excinf)
{
	uint32_t int_cause_reg = 0;

	int_cause_reg = __builtin_arc_lr(AUX_IRQ_CAUSE);
	//dbg_printf(DBG_LESS_INFO, "default interrupt handler\r\n");
	//dbg_printf(DBG_LESS_INFO, "last sp:0x%08x, icause:0x%08x\r\n", (uint32_t)p_excinf, int_cause_reg);
	Asm("kflag 1");
}

__attribute__ ((aligned(1024), section(".vector")))
EXC_ENTRY exc_entry_table[NUM_EXC_ALL] = {
	[0] = NULL,
	[1 ... NUM_EXC_CPU-1] = exc_entry_cpu,
	[NUM_EXC_CPU ... NUM_EXC_ALL-1] = exc_entry_int
 };
/**
 * \var exc_int_handler_table
 * \brief the cpu exception and interrupt exception handler table
 * called in exc_entry_default and exc_entry_int
 */
EXC_HANDLER exc_int_handler_table[NUM_EXC_ALL] = {
	 [0 ... NUM_EXC_CPU-1] = exc_handler_default,
	 [NUM_EXC_CPU ... NUM_EXC_ALL-1] = int_handler_default
};

/**
 * \var exc_nest_count
 * \brief the counter for exc/int processing, =0 no int/exc
 * >1 in int/exc processing
 * @}
 */
uint32_t exc_nest_count;

/**
 * \ingroup ARC_HAL_EXCEPTION_CPU
 * \brief  install an exception handler
 * \param[in] excno	exception number
 * \param[in] handler the handler of exception to install
 */
int32_t exc_handler_install(const uint32_t excno, EXC_HANDLER handler)
{
	if (excno < NUM_EXC_ALL && handler != NULL) {
		exc_int_handler_table[excno] = handler;
		return 0;
	}

	return -1;
}

#ifndef EMBARC_OVERRIDE_ARC_INTERRUPT_MANAGEMENT
/**
 * \brief disable the specific interrupt
 *
 * \param[in] intno interrupt number
 */
int32_t int_disable(const uint32_t intno)
{
	if (intno >= NUM_EXC_CPU && intno < NUM_EXC_ALL) {
		arc_int_disable(intno);
		return 0;
	}

	return -1;
}

/**
 * \brief  enable the specific int
 *
 * \param[in] intno interrupt number
 */
int32_t int_enable(const uint32_t intno)
{
	if (intno >= NUM_EXC_CPU && intno < NUM_EXC_ALL) {
		arc_int_enable(intno);
		return 0;
	}

	return -1;
}

/**
 * \brief  unlock cpu, enable interrupts to happen
 */
void cpu_unlock(void)
{
	arc_unlock();
}

/**
 * \ingroup ARC_HAL_EXCEPTION_INTERRUPT
 * \brief  install an interrupt handler
 * \param[in] intno	interrupt number
 * \param[in] handler interrupt handler to install
 */
int32_t int_handler_install(const uint32_t intno, INT_HANDLER handler)
{
	/*!< \todo parameter check ? */
	if (intno >= NUM_EXC_CPU) {
		return exc_handler_install(intno, handler);
	}

	return -1;
}

#endif /* EMBARC_OVERRIDE_ARC_INTERRUPT_MANAGEMENT */
