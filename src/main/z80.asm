; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU Z80 functions
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
; Initialize the Z80
; ----------------------------------------------------------------------

InitZ80:
	move	sr,-(sp)				; Disable interrupts
	move	#$2700,sr
	bsr.w	PrepareZ80Reset				; Prepare for Z80 reset

	lea	Z80_RAM,a0				; Load initialization code
	lea	.InitCode(pc),a1
	moveq	#.InitCodeEnd-.InitCode-1,d0

.LoadCode:
	move.b	(a1)+,(a0)+
	dbf	d0,.LoadCode

	move.w	#$2000-(.InitCodeEnd-.InitCode)-1,d0	; Clear the rest of Z80 RAM

.ClearRAM:
	move.b	#0,(a0)+
	dbf	d0,.ClearRAM
	
	bsr.w	ResetZ80				; Reset the Z80
	move	(sp)+,sr				; Restore interrupt settings
	rts

; ----------------------------------------------------------------------

.InitCode:
	dc.b	$F3					; di
	dc.b	$F3					; di
	dc.b	$ED, $56				; im 1
	dc.b	$31, $00, $20				; ld sp,2000h
	dc.b	$AF					; xor a
	dc.b	$47					; ld b,a
	dc.b	$4F					; ld c,a
	dc.b	$57					; ld d,a
	dc.b	$5F					; ld e,a
	dc.b	$67					; ld h,a
	dc.b	$6F					; ld l,a
	dc.b	$DD, $21, $00, $00			; ld ix,0
	dc.b	$FD, $21, $00, $00			; ld iy,0
	dc.b	$08					; ex af,af'
	dc.b	$D9					; exx
	dc.b	$AF					; xor a
	dc.b	$47					; ld b,a
	dc.b	$4F					; ld c,a
	dc.b	$57					; ld d,a
	dc.b	$5F					; ld e,a
	dc.b	$67					; ld h,a
	dc.b	$6F					; ld l,a
	dc.b	$08					; ex af,af'
	dc.b	$D9					; exx
	dc.b	$C3, $21, $00				; jp $
.InitCodeEnd:
	even

; ----------------------------------------------------------------------
; Stop the Z80
; ----------------------------------------------------------------------

StopZ80:
	move.w	#$100,Z80_BUS				; Stop the Z80

; ----------------------------------------------------------------------
; Wait for the Z80 to stop
; ----------------------------------------------------------------------

WaitZ80Stop:
	btst	#0,Z80_BUS				; Wait for the Z80 to stop
	bne.s	WaitZ80Stop
	rts

; ----------------------------------------------------------------------
; Prepare Z80 reset
; ----------------------------------------------------------------------

PrepareZ80Reset:
	move.w	#$100,Z80_BUS				; Stop the Z80
	move.w	#$100,Z80_RESET				; Set Z80 reset off
	bra.s	WaitZ80Stop				; Wait for the Z80 to stop

; ----------------------------------------------------------------------
; Reset the Z80
; ----------------------------------------------------------------------

ResetZ80:
	move.w	#0,Z80_RESET				; Set Z80 reset on
	ror.b	#8,d0
	move.w	#$100,Z80_RESET				; Set Z80 reset off
	
; ----------------------------------------------------------------------
; Start the Z80
; ----------------------------------------------------------------------

StartZ80:
	move.w	#0,Z80_BUS				; Start the Z80
	rts

; ----------------------------------------------------------------------