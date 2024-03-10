; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU interrupt functions
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
; V-BLANK interrupt
; ----------------------------------------------------------------------

VBlankInt:
	bsr.w	TriggerSubIRQ2				; Trigger Sub CPU IRQ2
	rte

; ----------------------------------------------------------------------
; VSync with default flag settings
; ----------------------------------------------------------------------

DefaultVSync:
	ori	#$700,sr				; Disable interrupts
	moveq	#%11,d0					; Update CRAM and run user handler

; ----------------------------------------------------------------------
; VSync
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.b - Flags (must be nonzero)
; ----------------------------------------------------------------------

VSync:
	move.b	d0,vblankFlags				; Set flags
	andi	#~$700,sr				; Enable interrupts

.Wait:
	tst.b	vblankFlags				; Has the V-BLANK interrupt occurred?
	bne.s	.Wait					; If not, wait

	bra.w	UpdateRandomSeed			; Update RNG seed

; ----------------------------------------------------------------------
; Set V-BLANK interrupt handler
; ----------------------------------------------------------------------
; PARAMETERS
;	a1.l - Pointer to handler
; ----------------------------------------------------------------------

SetVBlankHandler:
	move.l	a1,VBLANK_INT+2
	rts
	
; ----------------------------------------------------------------------
; Enable and set up H-BLANK interrupt (in second half of Work RAM)
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.w - Pointer to handler (in second half of Work RAM)
; ----------------------------------------------------------------------

EnableWorkRAMHBlank:
	move.l	a1,HBLANK_INT+2				; Set handler
	move.w	a1,GA_HBLANK
	
	bset	#4,vdpReg00+1				; Enable H-BLANK interrupt
	move.w	vdpReg00,VDP_CTRL
	rts

; ----------------------------------------------------------------------
; Enable and set up H-BLANK interrupt
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to handler
; ----------------------------------------------------------------------

EnableHBlank:
	move.l	a1,HBLANK_INT+2				; Set handler
	move.w	#HBLANK_INT+2,GA_HBLANK
	
	bset	#4,vdpReg00+1				; Enable H-BLANK interrupt
	move.w	vdpReg00,VDP_CTRL
	rts

; ----------------------------------------------------------------------
; Disable H-BLANK interrupt
; ----------------------------------------------------------------------

DisableHBlank:
	bclr	#4,vdpReg00+1				; Disable H-BLANK interrupt
	move.w	vdpReg00,VDP_CTRL
	rts

; ----------------------------------------------------------------------
; Trigger Sub CPU's IRQ2
; ----------------------------------------------------------------------

TriggerSubIRQ2:
	bset	#0,GA_IRQ2				; Trigger Sub CPU's IRQ2
	rts

; ----------------------------------------------------------------------