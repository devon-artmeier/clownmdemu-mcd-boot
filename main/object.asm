; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU object functions
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
; Update objects
; ----------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to object slots
;	a1.l - Pointer to sprite data buffer
;	d0.w - Number of object slots (minus 1)
;	d1.w - Object slot size
; ----------------------------------------------------------------------

UpdateObjects:
	move.l	a1,-(sp)				; Save start of sprite data
	move.l	a1,objSpriteSlot			; Set sprite slot address
	move.w	#1,objSpriteLink			; Reset sprite link
	
.Update:
	movem.l	d0-d1,-(sp)				; Save registers
	
	move.w	(a0),d0					; Get object ID
	andi.w	#$7FFC,d0
	beq.s	.NextObject				; If there's no object in this slot, branch
	
	movea.l	objIndexTable,a1			; Run object code
	movea.l	(a1,d0.w),a1
	jsr	(a1)
	
	move.l	objXSpeed(a0),d0			; Move object
	add.l	d0,objX(a0)
	move.l	objYSpeed(a0),d0
	add.l	d0,objY(a0)
	
	tst.w	(a0)					; Has the object been deleted?
	beq.s	.NextObject				; If so, branch
	
	movea.l	objSpriteSlot,a2			; Draw object
	move.w	objSpriteLink,d6
	bsr.s	DrawObjectSprite
	move.l	a2,objSpriteSlot
	move.w	d6,objSpriteLink
	
.NextObject:
	movem.l	(sp)+,d0-d1				; Restore registers
	adda.w	d1,a0					; Next object slot
	dbf	d0,.Update				; Loop until all objects are updated
	
	movea.l	objSpriteSlot,a2			; Get current sprite slot
	cmpa.l	(sp)+,a2				; Have any sprites been drawn?
	beq.s	.NoSprites				; If not, branch
	clr.b	-5(a2)					; Set link value in last sprite
	rts
	
.NoSprites:
	clr.l	(a2)					; Reset first sprite slot
	rts

; ----------------------------------------------------------------------
; Draw object sprite
; ----------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to object slot
;	a2.l - Pointer to sprite data slot
;	d6.w - Sprite link value
; ----------------------------------------------------------------------
; RETURNS:
;	a2.l - Pointer to next sprite data slot
;	d6.w - Updated sprite link value
; ----------------------------------------------------------------------

DrawObjectSprite:
	btst	#1,objSprFlags(a0)			; Should this object be drawn?
	bne.s	.End					; If not, branch
	
	movea.l	objSprite(a0),a1			; Get sprite data
	
	moveq	#0,d1					; Get number of sprite pieces
	move.b	(a1)+,d1
	
	move.b	(a1)+,objSprFlip(a0)			; Get flag that is affected by flipping
	tst.b	objSprFlags(a0)
	bpl.s	.GetPosition
	addq.b	#1,objSprFlip(a0)
	
.GetPosition:
	move.w	objY(a0),d2				; Get Y position
	move.w	objX(a0),d3				; Get X position
	
.DrawSprite:
	move.b	(a1)+,d0				; Get piece Y position
	ext.w	d0
	add.w	d2,d0
	
	cmpi.w	#128-32,d0				; Is the object offscreen?
	bcs.s	.SkipSprite				; If so, branch
	cmpi.w	#224+32+128,d0
	bhi.s	.SkipSprite				; If so, branch
	
	move.w	d0,(a2)+				; Set piece Y position
	
	move.b	(a1)+,(a2)+				; Set piece size
	move.b	d6,(a2)+				; Set piece link
	
	move.b	(a1)+,d0				; Set piece tile
	or.b	objSprTile(a0),d0
	move.b	d0,(a2)+
	move.b	(a1)+,(a2)+
	
	move.b	(a1)+,d0				; Get piece X position
	tst.b	objSprFlags(a0)				; Is the object's sprite flipped?
	bpl.s	.CheckX					; If not, branch
	bchg	#3,-2(a2)				; Flip tile
	move.b	(a1),d0					; Get flipped piece X position
	
.CheckX:
	addq.w	#1,a1					; Skip over flipped piece X position
	ext.w	d0					; Add object X position
	add.w	d3,d0
	
	cmpi.w	#128-32,d0				; Is the object offscreen?
	bcs.s	.DiscardSprite				; If so, branch
	cmpi.w	#320+32+128,d0
	bhi.s	.DiscardSprite				; If so, branch
	
	move.w	d0,(a2)+				; Set piece X position
	
	addq.b	#1,d6					; Next sprite link
	dbf	d1,.DrawSprite				; Loop until sprite is drawn
	rts

.SkipSprite:
	addq.w	#5,a1					; Skip sprite piece
	dbf	d1,.DrawSprite				; Loop until sprite is drawn
	rts

.DiscardSprite:
	subq.w	#6,a2					; Discard of sprite piece
	dbf	d1,.DrawSprite				; Loop until sprite is drawn

.End:
	rts

; ----------------------------------------------------------------------