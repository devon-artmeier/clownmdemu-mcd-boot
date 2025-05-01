; ------------------------------------------------------------------------------
; Copyright (c) 2025 Devon Artmeier
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
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Mega Drive interrupt
; ------------------------------------------------------------------------------

MegaDriveIrq:
	movem.l	d0-a6,-(sp)					; Save registers

	movea.w	#0,a5						; Clear a5
	bsr.w	_USERCALL2					; Run system program interrupt
	bclr	#0,vsync_flag					; Clear VSync flag
	
	movem.l	(sp)+,d0-a6					; Restore registers
	rte

; ------------------------------------------------------------------------------
; VSync
; ------------------------------------------------------------------------------

VSync:
	bset	#0,vsync_flag					; Set VSync flag

.Wait:
	btst	#0,vsync_flag					; Has a V-BLANK interrupt occured?
	bne.s	.Wait						; If not, wait
	rts

; ------------------------------------------------------------------------------