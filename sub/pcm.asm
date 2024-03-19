; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Sub CPU PCM functions
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
; Initialize PCM
; ----------------------------------------------------------------------

InitPCM:
	move.b	#$FF,PCM_ENABLE				; Disable every channel
	
	moveq	#16-1,d0				; Number of wave RAM banks
	moveq	#0,d1					; Value to fill with
	
.ClearWaveRAM:
	move.b	d0,PCM_CTRL				; Set wave RAM bank

	lea	PCM_WAVE,a0				; Wave RAM bank data
	move.w	#$1000-1,d2				; Length of wave RAM bank

.ClearWaveRAMBank:
	move.b	d1,(a0)+				; Clear wave RAM bank
	addq.w	#1,a0
	dbf	d2,.ClearWaveRAMBank			; Loop until bank is cleared
	dbf	d0,.ClearWaveRAM			; Loop until all banks are cleared
	
	moveq	#8-1,d0					; Number of channels
	
.ResetRegisters:
	move.b	d0,d2					; Set channel
	ori.b	#$40,d2
	move.b	d2,PCM_CTRL
	
	move.b	d1,PCM_ENV				; Reset volume
	move.b	d1,PCM_PAN				; Reset panning
	move.b	d1,PCM_FDL				; Reset frequency
	move.b	d1,PCM_FDH
	move.b	d1,PCM_LSL				; Reset loop address
	move.b	d1,PCM_LSH
	move.b	d1,PCM_ST				; Reset start address
	
	dbf	d0,.ResetRegisters			; Loop until all registers are reset
	rts

; ----------------------------------------------------------------------