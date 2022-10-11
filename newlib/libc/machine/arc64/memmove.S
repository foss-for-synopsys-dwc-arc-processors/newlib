#include <sys/asm.h>

; r0 void* dest
; r1 const void* src
; r2 size_t count

#if defined (__ARC64_ARCH64__)

ENTRY (memmove)
	; If the source plus count is greater than the destination
	; There is an overlap, and a backwards copy must be performed
	;add		r4, r1, r2
	LSRP.f	r12, r2, 5		; counter for 32-byte chunks
	
	; Dst is less than src, can safely perform normal memcpy
	BRLO.d		r0, r1, @.L_normal_memcpy
	addl		r4, r1, r2

	BRLO.d		r4, r0, @.L_normal_memcpy
	; Only relevant when not taking the branch, but might as well
	; use the delay slot (after the branch, this will be redone
	addl	r3, r0, r2

; Backwards search
; The only thing that changes between memcpy and memmove is copy direction
; in case the dest and src address memory locations overlap
; For a scratch implementation, have separate code for incremental and decremental copies	
	; Set both r0 and r1 to point to the end of eahc memory location
	addl	r1, r1, r2
	bmsk_s	r2, r2, 4

; Take care of the last 31 bytes
.L_B_write_31_bytes:
	bbit0.d	r2, 0, @1f
	lsr	r11, r2, 3
	ldb.aw	r4, [r1, -1]
	stb.aw	r4, [r3, -1]
1:
	bbit0.d	r2, 1, @1f
	xor	r11, r11, 3
	ldh.aw	r4, [r1, -2]
	sth.aw	r4, [r3, -2]
1:
	bbit0.d	r2, 2, @1f
	asl	r11, r11, 1
	ld.aw	r4, [r1, -4]
	st.aw	r4, [r3, -4]
1:
	bi	[r11]
	LD64.aw	r4, [r1, -8]
	ST64.aw	r4, [r3, -8]
	LD64.aw	r4, [r1, -8]
	ST64.aw	r4, [r3, -8]
	LD64.aw	r4, [r1, -8]
	ST64.aw	r4, [r3, -8]

; Do we have more than 32 bytes to take care of?
	jeq	[blink]

; Only take care of the 32 byte chunks at the end
.L_B_write_32_bytes:
	LD64.aw	r4, [r1, -8]
	LD64.aw	r6, [r1, -8]
	LD64.aw	r8, [r1, -8]
	LD64.aw	r10,[r1, -8]
	ST64.aw	r4, [r3, -8]
	ST64.aw	r6, [r3, -8]
	ST64.aw	r8, [r3, -8]
	dbnz.d	r12, @.L_B_write_32_bytes
	ST64.aw	r10, [r3, -8]

	j_s	[blink]


; Normal memcpy
.L_normal_memcpy:

	; Flags were set by LSRP.f, meaning it will jump if
	; there are no 32 byte chunks
	beq.d	@.L_F_write_31_bytes
	MOVP	r3, r0			; do not clobber the "dest"

.L_F_write_32_bytes:
	LD64.ab	r4, [r1, +8]
	LD64.ab	r6, [r1, +8]
	LD64.ab	r8, [r1, +8]
	LD64.ab	r10,[r1, +8]
	ST64.ab	r4, [r3, +8]
	ST64.ab	r6, [r3, +8]
	ST64.ab	r8, [r3, +8]
	dbnz.d	r12, @.L_F_write_32_bytes
	ST64.ab	r10, [r3, +8]
	bmsk_s	r2, r2, 4

.L_F_write_31_bytes:
	bbit0.d	r2, 2, @1f
	lsr	r12, r2, 3
	ld.ab	r4, [r1, 4]
	st.ab	r4, [r3, 4]
1:
	bbit0.d	r2, 1, @1f
	xor	r12, r12, 3
	ldh.ab	r4, [r1, 2]
	sth.ab	r4, [r3, 2]
1:
	bbit0.d	r2, 0, @1f
	asl	r12, r12, 1
	ldb.ab	r4, [r1, 1]
	stb.ab	r4, [r3, 1]
1:
	bi	[r12]
	LD64.ab	r4, [r1, 8]
	ST64.ab	r4, [r3, 8]
	LD64.ab	r4, [r1, 8]
	ST64.ab	r4, [r3, 8]
	LD64.ab	r4, [r1, 8]
	ST64.ab	r4, [r3, 8]

	j_s	[blink]



ENDFUNC (memmove)

#endif

