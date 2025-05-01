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
; Default V-BLANK interrupt
; ------------------------------------------------------------------------------

VBlankIrq:
	movem.l	d0-a6,-(sp)					; Save registers
	bsr.w	TriggerMcdSubIrq2				; Trigger Sub CPU IRQ2
	
	tst.b	vblank_updates_off				; Are updates disabled?
	bne.s	.NoUpdates
	
	bsr.w	UpdateCram					; Update CRAM
	
	btst	#1,vblank_flags					; Is the user handler enabled?
	beq.s	.NoUpdates					; If not, branch
	jsr	user_vblank					; Run user handler
	
	addq.b	#1,vblank_user_count				; Increment counter
	
.NoUpdates:
	bsr.w	ReadControllers					; Read controllers
	
	clr.b	vblank_flags					; Clear V-BLANK handler flags
	movem.l	(sp)+,d0-a6					; Restore registers
	rte

; ------------------------------------------------------------------------------
; VSync with default flag settings
; ------------------------------------------------------------------------------

DefaultVSync:
	ori	#$700,sr					; Disable interrupts
	moveq	#%11,d0						; Update CRAM and run user handler

; ------------------------------------------------------------------------------
; VSync
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.b - Flags (must be nonzero)
; ------------------------------------------------------------------------------

VSync:
	move.b	d0,vblank_flags					; Set flags
	andi	#~$700,sr					; Enable interrupts

.Wait:
	tst.b	vblank_flags					; Has the V-BLANK interrupt occurred?
	bne.s	.Wait						; If not, wait

	bra.w	UpdateRngSeed					; Update RNG seed

; ------------------------------------------------------------------------------
; Delay for a number of frames
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d1.w - Number of frames to delay (minus 1)
; ------------------------------------------------------------------------------

Delay:
	bsr.s	DefaultVSync					; VSync
	dbf	d1,Delay					; Loop until finished
	rts

; ------------------------------------------------------------------------------
; Set V-BLANK interrupt handler
; ------------------------------------------------------------------------------
; PARAMETERS
;	a1.l - Pointer to handler
; ------------------------------------------------------------------------------

SetVBlankHandler:
	move.l	a1,_LEVEL6+2					; Set handler
	rts
	
; ------------------------------------------------------------------------------
; Enable and set up H-BLANK interrupt (in second half of Work RAM)
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a1.w - Pointer to handler (in second half of Work RAM)
; ------------------------------------------------------------------------------

EnableWorkRamHBlank:
	move.l	a1,_LEVEL4+2					; Set handler
	move.w	a1,MCD_HBLANK
	
	bset	#4,vdp_reg_00+1					; Enable H-BLANK interrupt
	move.w	vdp_reg_00,VDP_CTRL
	rts

; ------------------------------------------------------------------------------
; Enable and set up H-BLANK interrupt
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to handler
; ------------------------------------------------------------------------------

EnableHBlank:
	move.l	a1,_LEVEL4+2					; Set handler
	move.w	#_LEVEL4+2,MCD_HBLANK
	
	bset	#4,vdp_reg_00+1					; Enable H-BLANK interrupt
	move.w	vdp_reg_00,VDP_CTRL
	rts

; ------------------------------------------------------------------------------
; Disable H-BLANK interrupt
; ------------------------------------------------------------------------------

DisableHBlank:
	bclr	#4,vdp_reg_00+1					; Disable H-BLANK interrupt
	move.w	vdp_reg_00,VDP_CTRL
	rts

; ------------------------------------------------------------------------------
; Trigger Sub CPU's IRQ2
; ------------------------------------------------------------------------------

TriggerMcdSubIrq2:
	bset	#0,MCD_IRQ2					; Trigger Sub CPU's IRQ2
	rts

; ------------------------------------------------------------------------------