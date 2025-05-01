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
; Get random number
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.w - Input seed
; RETURNS:
;	d0.l - Random number
; ------------------------------------------------------------------------------

Random:
	move.w	rng_seed,d1					; Update RNG seed
	muls.w	#$3619,d1
	addi.w	#$5D35,d1
	move.w	d1,rng_seed
	
	muls.w	d0,d1						; Generate random number
	swap	d0
	clr.w	d0
	add.l	d0,d0
	add.l	d1,d0
	swap	d0
	ext.l	d0
	rts

; ------------------------------------------------------------------------------
; Update random number generator seed
; ------------------------------------------------------------------------------

UpdateRngSeed:
	move.w	rng_seed,d0					; Update RNG seed
	muls.w	#$3619,d0
	addi.w	#$5D35,d0
	move.w	d0,rng_seed
	rts

; ------------------------------------------------------------------------------
; Convert byte to BCD format
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d1.b - Number to convert
; RETURNS:
;	d1.b - Converted number
; ------------------------------------------------------------------------------

ByteToBcd:
	move.w	d0,-(sp)					; Save d0
	
	andi.l	#$FF,d1						; Split digits
	divu.w	#10,d1
	move.w	d1,d0
	lsl.w	#4,d0
	swap	d1
	add.b	d0,d1
	
	move.w	(sp)+,d0					; Restore d0
	rts

; ------------------------------------------------------------------------------
; Convert word to BCD format
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d1.w - Number to convert
; RETURNS:
;	d1.w - Converted number
; ------------------------------------------------------------------------------

WordToBcd:
	move.w	d0,-(sp)					; Save d0
	
	andi.l	#$FFFF,d1					; Get 1st digit
	divu.w	#10,d1
	swap	d1
	move.w	d1,d0
	clr.w	d1
	swap	d1
	
	divu.w	#10,d1						; Get 2nd digit
	swap	d1
	lsl.w	#4,d1
	add.w	d1,d0
	clr.w	d1
	swap	d1
	
	divu.w	#10,d1						; Get 3rd digit
	swap	d1
	move.b	d1,-(sp)
	clr.b	1(sp)
	add.w	(sp)+,d0
	clr.w	d1
	swap	d1
	
	divu.w	#10,d1						; Get 4th digit
	swap	d1
	move.b	d1,-(sp)
	move.w	(sp)+,d1
	clr.b	d1
	lsl.w	#4,d1
	add.w	d1,d0
	
	move.w	d0,d1						; Get result
	move.w	(sp)+,d0					; Restore d0
	rts
	
; ------------------------------------------------------------------------------
; Add 2 minute:second timecodes together
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to timecode 1
;	a2.l - Pointer to end of timecode 2
; RETURNS:
;	a1.l - Pointer to resulting timecode
; ------------------------------------------------------------------------------

AddTimeCodes:
	addq.w	#2,a1						; Go to end of timecode 1

	abcd	-(a2),-(a1)					; Add seconds together
	bcs.s	.Overflow					; If there was an overflow, branch
	cmpi.b	#$60,(a1)					; Has the second value gone past 60?
	bcs.s	.AddMinutes					; If not, branch
	
	movem.l	d0-d1,-(sp)					; Fix seconds value
	move.b	(a1),d0
	moveq	#$40,d1
	abcd	d1,d0
	move.b	d0,(a1)
	movem.l	(sp)+,d0-d1
	bra.s	.AddMinutes
	
.Overflow:
	move	sr,-(sp)					; Fix seconds value
	addi.b	#$40,(a1)
	move	(sp)+,sr

.AddMinutes:
	abcd	-(a2),-(a1)					; Add minutes together
	rts

; ------------------------------------------------------------------------------
; Subtract minute:second:centisecond:xx timecode from another
; ------------------------------------------------------------------------------
; WARNING: There is a bug where the minuend value is allocated as
; a word value instead of a longword, which will mess with the
; calculation.
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - Timecode minuend
;	d1.l - Timecode subtrahend
; RETURNS:
;	d0.w - Resulting minute:second timecode
; ------------------------------------------------------------------------------

SubtractTimeCodes:
	lea	time_minuend,a0					; Setup subtraction
	lea	time_subtrahend,a1
	move.l	d0,(a0)+
	move.l	d1,(a1)+
	
	subq.w	#1,a0						; Skip over unused value
	subq.w	#1,a1
	
	move	#4,ccr						; Subtract centiseconds and seconds
	sbcd	-(a1),-(a0)
	sbcd	-(a1),-(a0)
	
	move	sr,-(sp)					; Was there an underflow?
	bcc.s	.SubtractMinutes				; If not, branch
	subi.b	#$40,(a0)					; Fix seconds value

.SubtractMinutes:
	move	(sp)+,sr					; Subtract minutes
	sbcd	-(a1),-(a0)
	
	move.w	(a0),d0						; Get resulting minute:second timecode
	rts

; ------------------------------------------------------------------------------