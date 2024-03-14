; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU memory functions
; ----------------------------------------------------------------------
; Copyright (c) 2024 Devon Artmeier
;
; Permission to use, copy, modify, and/or distribute this software
; for any purpose with or without fee is hereby granted.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
; WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIE
; WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
; AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
; DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
; PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER 
; TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
; PERFORMANCE OF THIS SOFTWARE.
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
; Clear memory region
; ----------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to memory region
;	d7.w - Length of memory region in longwords (minus 1)
; RETURNS
;	a6.l - Pointer to end of memory region
; ----------------------------------------------------------------------

ClearMemoryRegion:
	movea.l	a0,a6					; Get start of memory region
	moveq	#0,d6					; Fill with 0

.Clear:
	move.l	d6,(a6)+				; Clear memory region
	dbf	d7,.Clear				; Loop until finished
	rts
	
; ----------------------------------------------------------------------
; Clear large memory region
; ----------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to memory region
;	d5.w - Number of memory region blocks (minus 1)
;	d7.w - Length of 1st memory region block in longwords (minus 1)
; ----------------------------------------------------------------------

ClearLargeMemoryRegion:
	movem.l	d5/a0,-(sp)				; Save registers

.Clear:
	bsr.s	ClearMemoryRegion			; Clear memory region block
	movea.l	a6,a0					; Go to next block
	dbf	d5,.Clear				; Loop until finished

	movem.l	(sp)+,d5/a0				; Restore registers
	rts

; ----------------------------------------------------------------------
; Unknown copier and caller function
; ----------------------------------------------------------------------
; WARNING: The copy length is improperly split, which can lead to
; extra data being copied.
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - Length of copy in bytes
;	a0.l - Pointer to source data
;	a1.l - Pointer to destination buffer
;	a2.l - Pointer to function to call
; ----------------------------------------------------------------------

UnkCopyFunction:
	lsr.l	#2,d0					; Split copy length into blocks
	move.w	d0,d1					; d0 should have been decremented before splitting
	swap	d0					; instead of decrementing d1 after
	subq.w	#1,d1

.Copy:
	move.l	(a0)+,(a1)+				; Copy data
	dbf	d1,.Copy
	dbf	d0,.Copy

	jmp	(a2)					; Call function

; ----------------------------------------------------------------------