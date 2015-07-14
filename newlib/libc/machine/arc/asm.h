#ifndef ARC_NEWLIB_ASM_H
#define ARC_NEWLIB_ASM_H

/* Copyright (C) 2007, 2008 Free Software Foundation, Inc.
   This file is free software; you can redistribute it and/or modify
   it under the same terms as a file of your choice in
   newlib/libc/string/{memcmp,memcpy,memset}.c or
   {strchr,strcmp,strcpy,strlen,strncpy}.c .  */

#define _ENTRY(name) \
	.text ` .balign 4 ` .globl name ` name:
#define FUNC(name)         .type name,@function
#define ENDFUNC0(name) .Lfe_##name: .size name,.Lfe_##name-name
#define ENDFUNC(name) ENDFUNC0(name)
#define ENTRY(name) _ENTRY(name) ` FUNC(name)

#define add_l	add
#define bcc_l	bcc
#define bclr_l	bclr
#define beq_l	beq
#define bic_l	bic
#define b_l	b
#define bne_l	bne
#define breq_l	breq
#define brne_l	brne
#define j_l	j
#define ldb_l	ldb
#define ld_l	ld
#define mov_l	mov
#define or_l	or
#define st_l	st
#define stb_l	stb
#define sub_l	sub
#define tst_l	tst
#define extb_l	extb

#define bcc_s	bhs_s

#endif /* ARC_NEWLIB_ASM_H */
