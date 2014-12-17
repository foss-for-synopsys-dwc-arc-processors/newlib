;; *******************************************************************************************************************
;; -----------------
;; ARC start up file
;; -----------------
;; The startup code for the ARC family of processors does the following before transferring control to user defined
;; _main label :
;;		1. Set sp to __stack_top (link time variable)
;;		2. Set fp to zero
;;		3. Zero out the bss section (for uninitialized globals)
;; After returning from main, the processor is halted and the pipeline is flushed out
;;
;; For Arctangent-A4, we do not support passing arguments to "main".
;; For subsequent processors, we expect arc in r0 and argv in r1.
;; These are saved in r13 / r14 during the initialization code.
;; *******************************************************************************************************************

	.file	"crt0.S"
	.extern main

#if defined (__EM__) || defined (__HS__)
	.section .ivt, "a", @progbits
;; *******************************************************************************************************************
;// handler's name              type      number  name                    offset in IVT (hex/dec)
.word   __start             ;   exception   0   program entry point offset  0x0     0
.word   memory_error        ;   exception   1   memory_error        offset  0x4     4
.word   instruction_error   ;   exception   2   instruction_error   offset  0x8     8
.word   EV_MachineCheck     ;   exception   3   EV_MachineCheck     offset  0xC     12
.word   EV_TLBMissI         ;   exception   4   EV_TLBMissI         offset  0x10    16
.word   EV_TLBMissD         ;   exception   5   EV_TLBMissD         offset  0x14    20
.word   EV_ProtV            ;   exception   6   EV_ProtV            offset  0x18    24
.word   EV_PrivilegeV       ;   exception   7   EV_PrivilegeV       offset  0x1C    28
.word   EV_SWI              ;   exception   8   EV_SWI              offset  0x20    32
.word   EV_Trap             ;   exception   9   EV_Trap             offset  0x24    36
.word   EV_Extension        ;   exception   10  EV_Extension        offset  0x28    40
.word   EV_DivZero          ;   exception   11  EV_DivZero          offset  0x2C    44
.word   EV_DCError          ;   exception   12  EV_DCError          offset  0x30    48
.word   EV_Malignedr        ;   exception   13  EV_Maligned         offset  0x34    52
.word   _exit_halt          ;   exception   14  unused              offset  0x38    56
.word   _exit_halt          ;   exception   15  unused              offset  0x3C    60
.word   IRQ_Timer0          ;   IRQ         16  Timer 0             offset  0x40    64
.word   IRQ_Timer1          ;   IRQ         17  Timer 1             offset  0x44    68
.word   IRQ_18              ;   IRQ         18                      offset  0x48    72
.word   IRQ_19              ;   IRQ         19                      offset  0x4C    76
.word   IRQ_20              ;   IRQ         20                      offset  0x50    80
;; *******************************************************************************************************************

	.section .text.__startup, "ax", @progbits ;
#else
	.text
#endif

	.global	__start
	.type	__start, @function

#ifdef __ARC601__
;; Startup code for the ARC601 processor
__start:
	mov 	gp, @__SDATA_BEGIN__
	mov	sp, @__stack_top	; Point to top of stack
	mov	r5, 0			; Zero value
	mov_s 	r2, @__sbss_start	; r2 = start of the bss section
	sub 	r3, @_end, r2		; r3 = size of the bss section in bytes

	asr_s	r3, r3
	asr_s	r3, r3			; r3 = size of bss in words

.Lbss_loop:
	cmp	r3, 0xff		; Check for max lp_count
	mov.le	lp_count, r3
	mov.gt	lp_count, 0xff
	lpnz	2f			; Loop to zero bss
	st.ab	r5,[r2, 4] 		; Write word of zeros
	nop
2:
	sub.f	r3, r3, 0xff		; Decrement word count
	jp	.Lbss_loop

#else	/* __ARC601__ */

;; Startup code for the ARC600, ARC700 and ARCv2 processors
;; -----------------------------------------------------
;; NOTE:  The following restrictions apply on zero overhead loops (other restrictions are not pertinent to this code)
;;	  -  loop end should be 4 instruction words away from the lp_count setting instruction
;;	  -  loop body should have at least two instruction words
__start:
#if defined(__HS__)
	;; Allow unaligned accesses.
	lr    	r2, [0xA]
	bset	r2, r2, 19
	flag	r2
#endif
	mov 	gp, @__SDATA_BEGIN__
	mov_s 	r2, @__sbss_start	; r2 = start of the bss section
#if 1
	sub 	r3, @_end, r2		; r3 = size of the bss section in bytes
	asr.f 	lp_count, r3, 2		; set up the loop counter register to the size (in words) of the bss section
#else
	mov.f 	lp_count,(@_end-@__sbss_start)/4 ; bss size in words
#endif
#if defined (__A6__)
	lpnz 	@.Lend_zbss		; loop to zero out the bss. Enter loop only if lp_count != 0
	add 	r3, pcl, 20
	sr 	r3, [2]			; LP_END
	mov 	sp, @__stack_top	; initialize stack pointer, and this instruction has 2 words
	mov_s 	r3, 0
	st.ab 	r3, [r2, 4]		; zero out the word
.Lend_zbss:
#else
	mov 	sp, @__stack_top	; initialize stack pointer, and this instruction has 2 words
	mov_s 	r3,0
	lpnz 	@.Lend_zbss		; loop to zero out the bss. Enter loop only if lp_count != 0
	st.ab 	r3,[r2, 4]		; zero out the word
	nop
.Lend_zbss:
#endif

;; ifdef __ARC601__
#endif

;;; Some  targets use the .init and .fini sections
;;; to create constructors and destructors, and for these
;;; targets we need to call the _init function and arrange
;;; for _fini to be called at program exit.
	mov_s	r13, r0
	mov_s	r14, r1
	; calling atexit drags in malloc, so instead poke the function
	; address directly into the reent structure
	ld	r1, [gp, @_impure_ptr@sda]
	mov_s	r0, @_fini
	add	r1, r1, 0x14c		; &_GLOBAL_REENT->atexit0
	st	r1, [r1, -4]		; _GLOBAL_REENT->atexit
	st_s	r0, [r1, 8]		; _GLOBAL_REENT->atexit0._fns[0]
	mov_s	r0, 1
	st_s	r0, [r1, 4]		; _GLOBAL_REENT->atexit0._ind
;;; branch to _init
#if defined (__EM__) || defined (__HS__)
	jl	@_init
#else
	bl	@_init
#endif
	mov_s	r0, r13
	mov_s	r1, r14
;;; branch to main
#if defined (__EM__) || defined (__HS__)
	mov	fp,0
	jl	@main
#else
	bl.d	@main
	mov	fp, 0			; initialize frame pointer
#endif
	; r0 contains exit code
	; we used to jump to exit_halt here, but that is wrong:
	; we have to run destructors and other things registered with atexit.
	j	@exit

#if defined (__EM__) || defined (__HS__)
;;; ARCv2 default interrupt routines, defined as weak symbols.
.weak   memory_error
.weak   instruction_error
.weak   EV_MachineCheck
.weak   EV_TLBMissI
.weak   EV_TLBMissD
.weak   EV_ProtV
.weak   EV_PrivilegeV
.weak   EV_SWI
.weak   EV_Trap
.weak   EV_Extension
.weak   EV_DivZero
.weak   EV_DCError
.weak   EV_Malignedr
.weak   IRQ_Timer0
.weak   IRQ_Timer1
.weak   IRQ_18
.weak   IRQ_19
.weak   IRQ_20

.balign 4
memory_error        :
	b.d     .Lloop_halt
	mov	r0, 0x101
.balign 4
instruction_error   :
	b.d     .Lloop_halt
	mov	r0, 0x102
.balign 4
EV_MachineCheck     :
	b.d     .Lloop_halt
	mov	r0, 0x103
.balign 4
EV_TLBMissI         :
	b.d     .Lloop_halt
	mov	r0, 0x104
.balign 4
EV_TLBMissD         :
	b.d     .Lloop_halt
	mov	r0, 0x105
.balign 4
EV_ProtV            :
	b.d     .Lloop_halt
	mov	r0, 0x106
.balign 4
EV_PrivilegeV       :
	b.d     .Lloop_halt
	mov	r0, 0x108
.balign 4
EV_SWI              :
	b.d     .Lloop_halt
	mov	r0, 0x109
.balign 4
EV_Trap             :
	b.d     .Lloop_halt
	mov	r0, 0x10A
.balign 4
EV_Extension        :
	b.d     .Lloop_halt
	mov	r0, 0x10B
.balign 4
EV_DivZero          :
	b.d     .Lloop_halt
	mov	r0, 0x10C
.balign 4
EV_DCError          :
	b.d     .Lloop_halt
	mov	r0, 0x10D
.balign 4
EV_Malignedr        :
	b.d     .Lloop_halt
	mov	r0, 0x10E
.balign 4
IRQ_Timer0          :
IRQ_Timer1          :
IRQ_18              :
IRQ_19              :
IRQ_20              :
.Lloop_halt:
	; r0 contains exit code
	flag	0x01
	nop
	b	.Lloop_halt
	nop
#endif

	.section .text._exit_halt,"ax",@progbits
	.global	 _exit_halt
	.type	 _exit_halt, @function

_exit_halt:
	; r0 contains exit code
	flag	0x01
	nop
	nop
	nop
	b	@_exit_halt
	nop
