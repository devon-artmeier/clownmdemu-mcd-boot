; ------------------------------------------------------------------------------
; Copyright (c) 2025 Devon Artmeier and Clownacy
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
; Initialize PCM
; ------------------------------------------------------------------------------

InitPcm:
	move.b	#%11111111,PCM_ON_OFF				; Disable every channel
	
	moveq	#16-1,d0					; Number of wave RAM banks
	moveq	#0,d1						; Value to fill with
	
.ClearWaveRam:
	move.b	d0,PCM_CTRL					; Set wave RAM bank

	lea	WAVE_RAM,a0					; Wave RAM bank data
	move.w	#$1000-1,d2					; Length of wave RAM bank

.ClearWaveRamBank:
	move.b	d1,(a0)+					; Clear wave RAM bank
	addq.w	#1,a0
	dbf	d2,.ClearWaveRamBank				; Loop until bank is cleared
	dbf	d0,.ClearWaveRam				; Loop until all banks are cleared
	
	moveq	#8-1,d0						; Number of channels
	
.ResetRegisters:
	move.b	d0,d2						; Set channel
	ori.b	#$40,d2
	move.b	d2,PCM_CTRL
	
	move.b	d1,PCM_VOLUME					; Reset volume
	move.b	d1,PCM_PAN					; Reset panning
	move.b	d1,PCM_FREQ_L					; Reset frequency
	move.b	d1,PCM_FREQ_H
	move.b	d1,PCM_LOOP_L					; Reset loop address
	move.b	d1,PCM_LOOP_H
	move.b	d1,PCM_START					; Reset start address
	
	dbf	d0,.ResetRegisters				; Loop until all registers are reset
	rts

; ------------------------------------------------------------------------------