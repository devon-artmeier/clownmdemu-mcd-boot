; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU controller functions
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
; Initialize controllers
; ----------------------------------------------------------------------

InitControllers:
	bsr.w	StopZ80					; Stop the Z80
	
	moveq	#$40,d0					; Initialize controller ports
	move.b	d0,IO_CTRL_1
	move.b	d0,IO_CTRL_2
	move.b	d0,IO_CTRL_3
	
	bra.w	StartZ80				; Start the Z80
	
; ----------------------------------------------------------------------
; Read controllers
; ----------------------------------------------------------------------

ReadControllers:
	movem.l	d0-d1,-(sp)				; Save registers
	bsr.w	StopZ80					; Stop the Z80
	
	lea	ctrlHoldP1,a5				; Read player 1 controller
	lea	IO_DATA_1,a6
	bsr.s	.Read
	
	addq.w	#2,a6					; Read player 2 controller
	bsr.s	.Read

	bsr.w	StartZ80				; Start the Z80
	movem.l	(sp)+,d0-d1				; Restore registers
	rts
	
; ----------------------------------------------------------------------

.Read:
	move.b	#0,(a6)					; Get start and A buttons
	moveq	#$C0>>2,d0
	nop
	and.b	(a6),d0
	
	move.b	#$40,(a6)				; Get directional pad, B, and C buttons
	add.b	d0,d0
	add.b	d0,d0
	moveq	#$3F,d1
	and.b	(a6),d1
	
	or.b	d1,d0					; Combine button data
	not.b	d0
	
	move.b	(a5),d1					; Get tapped buttons
	eor.b	d0,d1
	and.b	d0,d1
	
	move.b	d0,(a5)+				; Store button data
	move.b	d1,(a5)+
	rts

; ----------------------------------------------------------------------
; Get controller ID
; Courtesy of Plutiedev: https://plutiedev.com/peripheral-id
; ----------------------------------------------------------------------
; PARAMETERS:
;	a6.l - Pointer to I/O data port
; RETURNS:
;	d7.b - Controller ID
; ----------------------------------------------------------------------

GetControllerId:
	move.l	d0,-(sp)				; Save d0
	bsr.w	StopZ80					; Stop the Z80
	
	move.b	#$40,6(a6)				; Set pin direction
	
	move.b	#$40,(a6)				; Get bits 2 and 3
	or.l	d0,d0
	moveq	#$F,d7
	and.b	(a6),d7
	move.b	.Bits23(pc,d7.w),d7
	
	move.b	#0,(a6)					; Combine bits 0 and 1
	or.l	d0,d0
	moveq	#$F,d0
	and.b	(a6),d0
	or.b	.Bits01(pc,d0.w),d7
	
	bsr.w	StartZ80				; Start the Z80
	move.l	(sp)+,d0				; Restore d0
	rts
	
; ----------------------------------------------------------------------

.Bits23:
	dc.b	%0000, %0100, %0100, %0100
	dc.b	%1000, %1100, %1100, %1100
	dc.b	%1000, %1100, %1100, %1100
	dc.b	%1000, %1100, %1100, %1100
    
.Bits01:
	dc.b	%0000, %0001, %0001, %0001
	dc.b	%0010, %0011, %0011, %0011
	dc.b	%0010, %0011, %0011, %0011
	dc.b	%0010, %0011, %0011, %0011

; ----------------------------------------------------------------------
; Update a controller's directional pad timer
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.w - 0 for player 1, 1 for player 2
;	a1.l - Pointer to store button bits when the timer has reset
; ----------------------------------------------------------------------

UpdateDpadTimer:
	move.l	a0,-(sp)				; Save a0
	
	clr.b	(a1)					; Clear timed directional pad bits
	
	lea	ctrlHoldP1,a0				; Get directional pad bits
	adda.w	d0,a0
	adda.w	d0,a0
	move.w	(a0),d1
	andi.w	#$F0F,d1
	
	lea	ctrlTimerP1,a0				; Get pointer to timer
	adda.w	d0,a0
	
	tst.b	d1					; Has the directional pad just been pressed?
	bne.s	.Tapped					; If so, branch
	tst.w	d1					; Is the directional pad being held down?
	beq.s	.End					; If not, branch
	
	subq.b	#1,(a0)					; Decrement timer
	bpl.s	.End					; If it hasn't run out, branch
	move.b	#6-1,(a0)				; Reset timer
	bra.s	.SetTimedBits
	
.Tapped:
	move.b	#21-1,(a0)				; Set initial timer value
	
.SetTimedBits:
	move.w	d1,-(sp)				; Save timed directional pad bits
	move.b	(sp)+,(a1)
	
.End:
	movea.l	(sp)+,a0				; Restore a0
	rts

; ----------------------------------------------------------------------