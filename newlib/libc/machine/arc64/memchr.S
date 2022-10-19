#include <sys/asm.h>


; This code uses a magic technique, adapted from
; newlib/libc/machine/arc/strcpy.S (it is also present in many other files)
;
; This technique allows for detecting a NULL byte inside any given amount of
; bits by performing the following operation
; 		DETECTNULL(X) (((X) - 0x01010101) & ~(X) & 0x80808080)
;
; As we want to detect a particular byte Y, we can use this technique as such
; 		Z = Y | Y << 8 | Y << 16 | Y << 24
;
; This makes it so Z has Y at each byte alignment, meaning
;		Z = [ Y[3], Y[2], Y[1] Y[0], Y[3], Y[2], Y[1] Y[0], ... ]
; or
; 		Z = [ Y, Y, Y, Y ]
; Now by XORing Z and the target data (K), we ensure a NULL byte appears if our
; desired byte is present, and we can therefore detect it with:
;
; 		DETECTNULL( xor ( K, Z ) )
;
; Depending on how the magic numbers work, the NULL byte might be encoded in
; them.
; If so, we can perhaps be able to initially encode our target byte instead
; of the NULL byte, and skip the xor inside the loop
;
; But alas, one does not need to understand magic to be able to use it, so
; for not, the xor is used
;

; r0 void* ptr
; r1 int ch
; r2 size_t count

#if defined (__ARC64_ARCH32__)

ENTRY (memchr)
	LSRP.f	0, r2, 4			; counter for 16-byte chunks
	beq.d	@.L_start_1_byte_search

	; Filter for 1 byte
	bmsk	r1, r1, 7
	lsl8	r9, r1

	or	r9, r9, r1
	;; Setup two rightmost bytes
	;; Setup two leftmost bytes
	lsl16	r1, r9
	or	r1, r1, r9

	; r1 is now setup with the special 4 byte repetition of the target byte
	; We use r1 because we dont have any more registers free inside the main loop
	; r9 can be repurposed
	mov	r8, 0x01010101
	ror	r9, r8

	xor r3, r3, r3

.L_search_16_bytes:

#if defined (__ARC64_LL64__)

	ldd.ab	r4r5, [r0, +8]
	ldd.ab	r6r7, [r0, +8]

#else

	ld.ab	r4, [r0, +4]
	ld.ab	r5, [r0, +4]
	ld.ab	r6, [r0, +4]
	ld.ab	r7, [r0, +4]

#endif

	xor	r4, r4, r1
	xor	r5, r5, r1
	xor	r6, r6, r1
	xor	r7, r7, r1

	sub	r10, r4, r8
	sub	r11, r5, r8
	sub	r12, r6, r8
	sub	r13, r7, r8

	bic	r10, r10, r4
	bic	r11, r11, r5
	bic	r12, r12, r6
	bic	r13, r13, r7

	tst	r10, r9
	bset.ne	r3, r3, 4

	tst	r11, r9
	bset.ne	r3, r3, 3

	tst	r12, r9
	bset.ne	r3, r3, 2

	tst	r13, r9
	bset.ne	r3, r3, 1

	; Break if found
	brne.d	r3, 0, @.L_found_in_16B

	; Keep going we have more 16 byte chunks
	sub	r2, r2, 16

	brge	r2, 16, @.L_search_16_bytes

	; Reset byte repetition of r1 to 1 single byte
	bmsk	r1, r1, 7

.L_start_1_byte_search:
	; Check if r2 is 0
	breq.d	r2, 0, @.L_byte_not_found
	ldb.ab	r10, [r0, +1]

.L_search_1_byte:

	breq	r10, r1, @.L_found_byte

	dbnz.d	r2, @.L_search_1_byte
	ldb.ab	r10, [r0, +1]

; Byte not found
.L_byte_not_found:
	j.d	[blink]
	MOVP	r0, 0

.L_found_byte:
	j_s.d [blink]
	SUBP	r0, r0, 1

.L_found_in_16B:

	fls	r5, r3 ; [2]

; Select appropriate register to analyze [4]
	mov	r2, r13

; Point r13 to first NULL byte containing double word [3]
	sub2	r0, r0, r5


	asr.f	r3, r3, 3
	mov.c	r2, r12

	asr.f	r3, r3, 1
	mov.c	r2, r11

	asr.f	r3, r3, 1
	mov.c	r2, r10

	and	r2, r2, r9 ; [5]

	ffs	r2, r2 ; [6]

	xbfu 	r2, r2, 0b0111000011 ; [7]

	add	r0, r0, r2 ; [8]
	
	j	[blink]

ENDFUNC (memchr)

#else

ENTRY (memchr)
	lsrl.f	0, r2, 5			; counter for 32-byte chunks
	beq.d	@.L_start_1_byte_search

	; Filter for 1 byte
	bmsk	r1, r1, 7
	lsl8	r9, r1

	or	r9, r9, r1
	;; Setup two rightmost bytes
	;; Setup two leftmost bytes
	lsl16	r1, r9
	or	r1, r1, r9

	vpack2wl	r1, r1, r1

	; r1 is now setup with the special 4 byte repetition of the target byte
	; We use r1 because we dont have any more registers free inside the main loop
	; r9 can be repurposed
	vpack2wl	r8, NULL_32DT_1, NULL_32DT_1
	asll	r9, r8, 7

	xorl	r3, r3, r3

.L_search_32_bytes:

; Using 128-bit memory operations
#if defined (__ARC64_M128__)
	
	lddl.ab	r4r5, [r0, +16]
	lddl.ab	r6r7, [r0, +16]

; The 64-bit crunching implementation.
#elif defined (__ARC64_ARCH64__)
	
	ldl.ab	r4, [r0, +8]
	ldl.ab	r5, [r0, +8]
	ldl.ab	r6, [r0, +8]
	ldl.ab	r7, [r0, +8]

#else
	# error Unknown configuration
#endif

	xorl	r4, r4, r1
	xorl	r5, r5, r1
	xorl	r6, r6, r1
	xorl	r7, r7, r1

	subl	r10, r4, r8
	subl	r11, r5, r8
	subl	r12, r6, r8
	subl	r13, r7, r8

	bicl	r10, r10, r4
	bicl	r11, r11, r5
	bicl	r12, r12, r6
	bicl	r13, r13, r7

	tstl	r10, r9
	bset.ne	r3, r3, 4

	tstl	r11, r9
	bset.ne	r3, r3, 3

	tstl	r12, r9
	bset.ne	r3, r3, 2

	tstl	r13, r9
	bset.ne	r3, r3, 1

	; Break if found
	brne.d	r3, 0, @.L_found_in_32B

	; Keep going we have more 16 byte chunks
	subl	r2, r2, 32
	brge	r2, 32,	@.L_search_32_bytes

	; Reset byte repetition of r1 to 1 single byte
	bmskl	r1, r1, 7

.L_start_1_byte_search:
	; Check if r2 is 0
	breq.d	r2, 0, @.L_byte_not_found
	ldb.ab	r10, [r0, +1]
	
.L_search_1_byte:

	breq	r10, r1, @.L_found_byte

	dbnz.d	r2, @.L_search_1_byte
	ldb.ab	r10, [r0, +1]

; Byte not found
.L_byte_not_found:
	j.d	[blink]
	movl	r0, 0

.L_found_byte:
	j_s.d [blink]
	subl	r0, r0, 1

.L_found_in_32B:

	fls	r5, r3 ; [2]

; Select appropriate register to analyze [4]
	movl	r2, r13

; Point r13 to first NULL byte containing double word [3]
	sub3l	r0, r0, r5

	asr.f	r3, r3, 3
	movl.c	r2, r12

	asr.f	r3, r3, 1
	movl.c	r2, r11

	asr.f	r3, r3, 1
	movl.c	r2, r10

	andl	r2, r2, r9 ; [5]

	ffsl	r2, r2 ; [6]

	xbful 	r2, r2, 0b0111000011 ; [7]

	addl	r0, r0, r2 ; [8]
	
	j	[blink]

ENDFUNC (memchr)
#endif

