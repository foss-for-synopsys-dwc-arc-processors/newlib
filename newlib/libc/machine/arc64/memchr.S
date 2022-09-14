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

ENTRY (memchr)
	; If any input is aligned to 1 or 2 bytes, search 1 byte at a time
	; Possible optimization: only search 1 byte at a time until the first
	; 4 byte alignment is reached
	bmsk.f	0,		r0,		1
	bne.d	.L_search_1byte_chunks

	LSRP.f	r12,	r2,		2				; counter for 4-byte chunks
	beq.d	@.L_search_1byte_chunks	; Less than 32 bits, go 1 byte at a time

; Bootstrap magic byte detector

	; First we need a 32 bit number that has the target byte repeated 4 times
	;; Get first two bytes ready
	MOVP	r9,		r1
	LSL8	r9,		r9
	OR		r9,		r9,		r1
	;; Setup two rightmost bytes
	MOVP	r10,	r9
	;; Setup two leftmost bytes
	LSL16	r9,		r9
	OR		r10,	r10,	r9

	; r10 is now setup with the special 4 byte repetition of r1
	; r9 can be repurposed
	mov		r8,		0x01010101
	ror		r9,		r8						; Further magic byte detector setup


; Handle 4 byte chunks
.L_search4byte_chunk:
	; Load next 4 bytes
	ld.ab	r11,	[r0, +4]
	
	; Force the read 4 byte value to have a NULL byte if chr is present
	xor		r13,	r11,	r10
	; Look for the NULL byte
	sub		r2,		r13,	r8
	bic		r2,		r2,		r13
	tst		r2,		r9

	; Found byte!
	bne		@.L_found_inside_4bytes

	; Still have 4 byte chunks to find!
	dbnz	r12,	@.L_search4byte_chunk

	; Nothing found, no more 4 byte chunks
	bmsk_s	r2,		r2,		2
	j		@.L_search_1byte_chunks

; Backtrack 4 bytes and let 1 byte search do its' thing
.L_found_inside_4bytes:
	SUBP	r0,		r0,		4

; Load next byte and enter loop
.L_search_1byte_chunks:
	ldb		r10,	[r0]
	cmp		r10,	r1

; Check if matching byte was found
; iterate read next byte until it is found, or end of data
.L_search_next_1byte_chunk:

	beq.d	@.L_return_ptr
	ldb.aw	r10,	[r0, +1]

	dbnz.d	r2,		@.L_search_next_1byte_chunk
	cmp		r10,	r1

	
; Byte was not found, return NULL
.L_return_nullptr:
	MOVP	r0,		0
	j_s	[blink]

; Byte was found in r0 - 1
.L_return_ptr:
	SUBP	r0,		r0,		1
	j_s	[blink]




;	MOVP	r12, r2
;
;	beq.d	@.L_search_32byte_chunks
;	LD64	r8, [r0]
;
;.L_search_32byte_chunks:
;
;	cmp		r8, r1
;	beq		@.L_return_ptr
	
;	dbnz.d	r12, @.L_return_nullptr
;	ST64.aw	r10, [r0, +8]

; Exits the loop when either r12 is 0 (end of array) or char is found


ENDFUNC (memchr)

