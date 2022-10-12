#include <sys/asm.h>

; r0 void* ptr
; r1 int ch
; r2 size_t count

ENTRY (memchr)
	; Clear flags

	ldb		r10, [r0]
	cmp		r10, r1

.L_search_1byte_chunks:

	beq.d		@.L_return_ptr
	ldb.aw	r10, [r0, +1]

	dbnz.d	r2, @.L_search_1byte_chunks
	cmp		r10, r1


; Returns NULL if char is not found
.L_return_nullptr:
	MOVP	r0, 0
	j_s	[blink]

; Returns the current value of r0
.L_return_ptr:
	SUBP	r0, r0, 1
	j_s	[blink]

ENDFUNC (memchr)

