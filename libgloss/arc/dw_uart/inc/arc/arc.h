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
 * \date 2014-06-20
 * \author Wayne Ren(Wei.Ren@synopsys.com)
--------------------------------------------- */

/**
 * \file
 * \ingroup ARC_HAL_CORE_COMM
 * \brief  header file including common core definitions
 */

 /**
  * \addtogroup ARC_HAL_CORE_COMM
  * @{
  */


#ifndef _ARC_HAL_CORE_H_
#define _ARC_HAL_CORE_H_

/**
 * \name status register STATUS32
 * @{
 */
#define AUX_STATUS32			(0xa)
#define AUX_STATUS32_P0			(0xb)
/** @} */

/**
 * \name zero overhead loop auxiliary register
 * @{
 */
#define AUX_LP_START			(0x2)	/*!< loop start address (32-bit) */
#define AUX_LP_END			(0x3)	/*!< loop end address (32-bit) */
/** @} */

/**
 * \name indexed table auxiliary register
 * @{
 */
#define AUX_JLI_BASE			(0x290)	/*!< jump and link indexed base address */
#define AUX_LDI_BASE			(0x291)	/*!< load indexed base address */
#define AUX_EI_BASE			(0x292)	/*!< execute indexed base address */
/** @} */

/**
 * \name baseline auxiliary register set
 * @{
 */
/* to be added */
#define AUX_ERRET			(0x400)	/*!< exception return address */
#define AUX_ERBTA			(0x401)	/*!< BTA saved on exception entry */
#define AUX_ERSTATUS			(0x402)	/*!< STATUS32 saved on exception */
#define AUX_ECR				(0x403)	/*!< exception cause register */
#define AUX_EFA				(0x404) /*!< exception fault address */
#define AUX_BTA				(0x412)	/*!< branch target address */
/** @} */

/**
 * \name interrupt related auxiliary register
 * @{
 */
#define AUX_IRQ_CTRL			(0xe)	/*!< interrupt context saving control register */
#define AUX_INT_VECT_BASE		(0x25)	/*!< interrupt vector base register */
#define AUX_INT_VECT_BASE_S		(0x26)	/*!< secure interrupt vector based register */
#define AUX_IRQ_ACT			(0x43)	/*!< active interrupts register */
#define AUX_IRQ_CAUSE			(0x40a)	/*!< interrupt cause register */
#define AUX_IRQ_SELECT			(0x40b)	/*!< interrupt select register */
#define AUX_IRQ_PRIORITY		(0x206)	/*!< interrupt priority register */
#define AUX_IRQ_PRIORITY_BIT_S		(0x8)	/*!< S bit offset in interrupt priority register */
#define AUX_IRQ_ENABLE			(0x40c)	/*!< interrupt enable register */
#define AUX_IRQ_TRIGGER			(0x40d)	/*!< interrupt trigger: level or pulse */
#define AUX_IRQ_PENDING			(0x416)	/*!< interrupt pending register */
#define AUX_IRQ_PLUSE_CLR		(0x415)	/*!< interrupt pulse cancel register */
#define AUX_IRQ_STATUS			(0x40f)	/*!< interrupt status register */
#define AUX_IRQ_PRI_PENDING		(0x200)	/*!< interrupt priority pending register */
#define AUX_IRQ_HINT			(0x201)	/*!< software interrupt trigger */
/** @} */

/**
 * \name other auxiliary register
 * @{
 */
#define AUX_DMP_PERIPHERAL		(0x20a) /*!< peripheral memory region */
/** @} */

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __ASSEMBLY__
/* add type definition and function declaration here */
#endif	/* assembly */

#ifdef __cplusplus
}
#endif


#endif	/* _ARC_HAL_CORE_H_ */

 /**  @} */
