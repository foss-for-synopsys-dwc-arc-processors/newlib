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
 * \brief header file of exception and interrupt management module
 */

#ifndef _ARC_HAL_EXCEPTION_H_
#define _ARC_HAL_EXCEPTION_H_

#include "inc/arc/arc.h"
#include "inc/arc/arc_builtin.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \addtogroup ARC_HAL_EXCEPTION_CPU
 * @{
 * \todo need a conf.h from application or board to define the
 * features of processor, such as number of exception, code
 * density and FIQ.
 */
#ifndef NUM_EXC_CPU
#define NUM_EXC_CPU	16	/*!< number of CPU exceptions */
#endif

#ifndef NUM_EXC_INT
#define NUM_EXC_INT	9	/*!< number of interrupt exceptions, defined by users*/
#endif

#define NUM_EXC_ALL	(NUM_EXC_CPU + NUM_EXC_INT) /*!< total number of exceptions */

extern uint32_t exc_nest_count;

/** @}*/

/**
 * \addtogroup ARC_HAL_EXCEPTION_INTERRUPT
 * @{
 */
#ifndef INT_PRI_MIN
#define INT_PRI_MIN	(-2)		/*!< the minimum interrupt priority */
#endif

#define INT_PRI_MAX (-1)		/*!< the maximum interrupt priority */
/**
 * \brief disable the specific interrupt
 *
 * \param[in] intno interrupt number
 */
Inline void arc_int_disable(const uint32_t intno)
{
	write_aux_reg(AUX_IRQ_SELECT, intno);
	write_aux_reg(AUX_IRQ_ENABLE, 0);
}

/**
 * \brief  enable the specific int
 *
 * \param[in] intno interrupt number
 */
Inline void arc_int_enable(const uint32_t intno)
{
	write_aux_reg(AUX_IRQ_SELECT, intno);
	write_aux_reg(AUX_IRQ_ENABLE, 1);
}

/**
 * \brief  unlock cpu, enable interrupts to happen
 */
Inline void arc_unlock(void)
{
	Asm("":::"memory");
	Asm("seti");
}

/** @}*/

/**
 * \addtogroup ARC_HAL_EXCEPTION_CPU
 * @{
 */
/**
 * \typedef EXC_ENTRY
 * \brief  the data type for exception entry
 */
typedef void (*EXC_ENTRY) (void);
/**
 * \typedef EXC_HANDLER
 * \brief  the data type for exception handler
 */
typedef	void (*EXC_HANDLER) (void *exc_frame);
/** @}*/


/**
 * \ingroup ARC_HAL_EXCEPTION_INTERRUPT
 * \typedef INT_HANDLER
 * \brief  the data type for interrupt handler
 */
typedef void (*INT_HANDLER) (void *ptr);

extern EXC_ENTRY exc_entry_table[NUM_EXC_ALL];
extern EXC_HANDLER exc_int_handler_table[NUM_EXC_ALL];

/**
 * \fn exc_entry_cpu
 * \brief the default CPU exception entry
 */
extern void exc_entry_cpu(void);

/**
 * \fn exc_entry_firq
 * \brief the fast interrupt exception entry
 */
extern void exc_entry_firq(void);
/**
 * \fn exc_entry_int
 * \brief the interrupt exception entry
 */
extern void exc_entry_int(void);
/** @}*/

/* excetpion related apis */
extern int32_t exc_handler_install(const uint32_t excno, EXC_HANDLER handler);

/* interrupt related apis */
extern int32_t int_disable(const uint32_t intno);
extern int32_t int_enable(const uint32_t intno);
extern void cpu_unlock(void);
extern int32_t int_handler_install(const uint32_t intno, INT_HANDLER handler);

#ifdef __cplusplus
}
#endif

#if defined(LIB_SECURESHIELD) && defined(LIB_SECURESHIELD_OVERRIDES) && (SECURESHIELD_VERSION == 1)
#define OVERRIDE_ARC_HAL_EXCEPTION_H
#include "secureshield_overrides.h"
#endif

#endif /* _ARC_HAL_EXCEPTION_H_*/
