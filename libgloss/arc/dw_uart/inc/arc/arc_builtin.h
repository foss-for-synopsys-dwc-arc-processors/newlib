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
 * \date 2014-06-12
 * \author Wayne Ren(Wei.Ren@synopsys.com)
--------------------------------------------- */

/**
 * \file
 * \ingroup ARC_HAL_BUILTIN
 * \brief header file of builtin and helper functions
 *
 * The Metaware toolchain and the GNU toolchain are supported. The details please go to see the file.
 */

/**
 * \addtogroup	ARC_HAL_BUILTIN
 * @{
 */

#ifndef _ARC_HAL_BUILTIN_H_
#define _ARC_HAL_BUILTIN_H_

#include <stdint.h>	/* C99 standard lib */
#include <limits.h>	/* C99 standard lib */
#include <stddef.h>	/* C99 standard lib */
#include <stdbool.h>	/* C99 standard lib */

#ifdef __cplusplus
extern "C" {
#endif

/*
 *  macro definitions of compiler extend function
 */
#ifndef __cplusplus				/* C++ supports inline */
#if __STDC_VERSION__ < 199901L			/* C99 supports inline */
#ifndef inline
#define inline	__inline__			/* inline function */
#endif
#endif /* __STDC_VERSION__ < 199901L */
#endif /* __cplusplus */

#ifndef Inline
#define Inline	static __inline__		/* inline function */
#endif

#ifndef __cplusplus				/* C++ supports asm */
#ifndef asm
#define asm	__asm__				/* inline asm */
#endif
#endif /* __cplusplus */

#ifndef Asm
#define Asm	__asm__ volatile		/* inline asm (no optimization) */
#endif

/**
 * \brief _arc_rarely (expr) evaluates expression expr and
 *	informs the compiler that the value is rarely true.
 */
#define _arc_rarely(a)				__builtin_expect((int)(a), 0)

Inline uint32_t _arc_clri(void) {
	register uint32_t v;
	__asm__ volatile ("clri %0" :"=r"(v));
	return v;

}

/*
 * The auxiliary register address is specified as a long immediate operand by caller.
 * e.g.
 *    write_aux_reg(0x69, some_val);
 * This generates the tightest code.
 */
#define write_aux_reg(reg_imm, val)	\
({					\
	Asm(		\
	"	sr   %0, [%1]	\n"	\
	:				\
	: "ir"(val), "r"(reg_imm));	\
})

/**
 * \name cache related helper function
 * @{
 */

/**
 * \brief go to main function with proper arguments
 * \param  argc argument count
 * \param  argv argument content array
 * \retval return value of main function
 */
Inline int32_t _arc_goto_main(int argc, char **argv) {
	int __ret;
	__asm__ volatile(
		"mov %%r0, %1\n"
		"mov %%r1, %2\n"
		"push_s %%blink\n"
		"jl main\n"
		"pop_s %%blink\n"
		"mov %0, %%r0"
		:"=r"(__ret): "r"(argc), "r"(argv));
	return (int)__ret;
}

#ifdef __cplusplus
}
#endif

/** @} */
#endif /* _ARC_HAL_BUILTIN_H_ */
/** @} */
