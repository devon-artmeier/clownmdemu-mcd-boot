; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU VDP functions
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
; Set default VDP registers
; ----------------------------------------------------------------------

SetDefaultVdpRegs:
	lea	DefaultVdpRegs(pc),a1			; Default VDP registers
	move.w	#$40*2,vdpPlaneStride			; Set plane stride to 64 tiles

; ----------------------------------------------------------------------
; Set VDP registers
; ----------------------------------------------------------------------
; PARAMETERS
;	a1.l - Pointer to VDP register table (0 terminated)
; ----------------------------------------------------------------------

SetVdpRegisters:
	lea	vdpReg00,a2				; VDP register cache

.SetupRegs:
	move.w	(a1)+,d0				; Get register ID and value
	bpl.s	.End					; If we are at the end of the list, branch
	
	cmpi.w	#$9200,d0				; Should it be stored in the cache?
	bhi.s	.SetRegister				; If not, branch
	
	move.w	d0,-(sp)				; Set in cache
	move.b	(sp)+,d1
	andi.w	#$7F,d1
	add.w	d1,d1
	move.w	d0,(a2,d1.w)

.SetRegister:
	move.w	d0,VDP_CTRL				; Set register
	bra.s	.SetupRegs				; Loop

.End:
	rts

; ----------------------------------------------------------------------

DefaultVdpRegs:
	dc.w	$8000|(%00000100)			; Disable H-BLANK interrupt
	dc.w	$8100|(%00100100)			; Enable V-BLANK interrupt
	dc.w	$8200|($C000/$400)			; Plane A address
	dc.w	$8300|($A000/$400)			; Window plane address
	dc.w	$8400|($E000/$2000)			; Plane B address
	dc.w	$8500|($B800/$200)			; Sprite data address
	dc.w	$8700|($00)				; Background color at first CRAM entry
	dc.w	$8A00|($00)				; H-BLANK interrupt every scanline
	dc.w	$8B00|(%00000000)			; Disable external interrupt
	dc.w	$8C00|(%10000001)			; H40 mode
	dc.w	$8D00|($BC00/$400)			; Horizontal scroll data address
	dc.w	$8F00|($02)				; Auto-increment by 2
	dc.w	$9000|($11)				; 64x64 plane
	dc.w	$9100|($00)				; Window X position at 0
	dc.w	$9200|($00)				; Window Y position at 0
	dc.w	0

; ----------------------------------------------------------------------
; Wait for a DMA to finish
; ----------------------------------------------------------------------

WaitVdpDma:
	move	VDP_CTRL,ccr				; Has the operation finished?
	bvs.s	WaitVdpDma				; If not, wait
	rts

; ----------------------------------------------------------------------
; Set background color to black
; ----------------------------------------------------------------------

SetVdpBlackBackground:
	move.l	#$C0000000,VDP_CTRL			; Set first color to black
	move.w	#0,VDP_DATA
	rts

; ----------------------------------------------------------------------
; Clear VDP memory
; ----------------------------------------------------------------------

ClearVdpMemory:
	bsr.s	SetVdpBlackBackground			; Set background to black
	bsr.w	ClearVdpVScroll				; Clear vertical scroll table
	move.l	#$40000000,d0				; Clear VRAM
	move.w	#$10000-1,d1
	bra.s	ClearVdpVramRegion

; ----------------------------------------------------------------------
; Clear screen
; ----------------------------------------------------------------------

ClearVdpScreen:
	bsr.s	ClearVdpSprites				; Clear sprites
	bsr.s	ClearVdpPlaneA				; Clear plane A
	bsr.s	ClearVdpPlaneB				; Clear plane B
	bra.s	ClearVdpWindow				; Clear window plane

; ----------------------------------------------------------------------
; Clear sprites
; ----------------------------------------------------------------------

ClearVdpSprites:
	clr.l	sprites					; Clear first sprite slot
	move.l	#$78000002,VDP_CTRL
	move.l	#0,VDP_DATA
	rts
	
; ----------------------------------------------------------------------
; Clear palette
; ----------------------------------------------------------------------

ClearVdpPalette:
	lea	palette,a0				; Clear palette buffer
	moveq	#$80/4-1,d0
	moveq	#0,d1
	
.ClearPalette:
	move.l	d1,(a0)+
	dbf	d0,.ClearPalette
	
	move.l	#$C0000000,d0				; Clear palette
	moveq	#$80/2-1,d1
	bra.s	ClearVdpRegion

; ----------------------------------------------------------------------
; Clear vertical scroll table
; ----------------------------------------------------------------------

ClearVdpVScroll:
	move.l	#$40000010,d0				; Clear vertical scroll table
	moveq	#$50/2-1,d1

; ----------------------------------------------------------------------
; Clear region of VDP memory
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Number of words to clear (minus 1)
; ----------------------------------------------------------------------

ClearVdpRegion:
	moveq	#0,d2					; Fill with 0

; ----------------------------------------------------------------------
; Fill region of VDP memory
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Number of words to clear (minus 1)
;	d2.w - Value to fill with
; ----------------------------------------------------------------------

FillVdpRegion:
	move.l	d0,VDP_CTRL				; Set VDP command

.Fill:
	move.w	d2,VDP_DATA				; Fill
	dbf	d1,.Fill
	rts

; ----------------------------------------------------------------------
; Clear window plane
; ----------------------------------------------------------------------

ClearVdpWindow:
	move.l	#$60000002,d0				; Clear window plane
	move.w	#$E00-1,d1
	bra.w	ClearVdpVramRegion

; ----------------------------------------------------------------------
; Clear plane A
; ----------------------------------------------------------------------

ClearVdpPlaneA:
	move.l	#$40000003,d0				; Clear plane A
	move.w	#$2000-1,d1
	bra.s	ClearVdpVramRegion

; ----------------------------------------------------------------------
; Clear plane B
; ----------------------------------------------------------------------

ClearVdpPlaneB:
	move.l	#$60000003,d0				; Clear plane B
	move.w	#$2000-1,d1

; ----------------------------------------------------------------------
; Clear a region of VRAM
; ----------------------------------------------------------------------
; PARAMETERS
;	d0.l - VDP command
;	d1.w - Number of bytes to clear (minus 1)
; ----------------------------------------------------------------------

ClearVdpVramRegion:
	moveq	#0,d2					; Fill with 0

; ----------------------------------------------------------------------
; Fill a region of VRAM
; ----------------------------------------------------------------------
; PARAMETERS
;	d0.l - VDP command
;	d1.w - Number of bytes to clear (minus 1)
;	d2.b - Value to fill with
; ----------------------------------------------------------------------

FillVdpVramRegion:
	lea	VDP_CTRL,a6				; VDP control port

	move.w	#$8F01,(a6)				; Set auto-increment to 1
	move.w	vdpReg01,d3				; Enable DMA
	ori.b	#1<<4,d3
	move.w	d3,(a6)
	
	move.l	#$94009300,-(sp)			; Start operation
	movep.w	d1,1(sp)
	move.l	(sp)+,(a6)
	move.w	#$9780,(a6)
	ori.l	#$40000080,d0
	move.l	d0,(a6)
	move.w	d2,-4(a6)

	bsr.w	WaitVdpDma				; Wait for the operation to finish

	move.w	vdpReg01,(a6)				; Restore previous DMA enable setting
	move.w	#$8F02,(a6)				; Set auto-increment to 2
	rts

; ----------------------------------------------------------------------
; Copy a region of VRAM to another place in VRAM
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command for destination VRAM address
;	d1.w - Source VRAM address
;	d2.w - Number of bytes to copy
; ----------------------------------------------------------------------

CopyVdpVramRegion:
	lea	VDP_CTRL,a6				; VDP control port

	move.w	#$8F01,(a6)				; Set auto-increment to 1
	move.w	vdpReg01,d3				; Enable DMA
	ori.b	#1<<4,d3
	move.w	d3,(a6)
	
	move.l	#$94009300,-(sp)			; Prepare parameters
	move.l	#$96009500,-(sp)
	movep.w	d1,1(sp)
	movep.w	d2,5(sp)

	move.l	(sp)+,(a6)				; Start operation
	move.l	(sp)+,(a6)
	move.w	#$97C0,(a6)
	ori.w	#$C0,d0
	move.l	d0,(a6)

	bsr.w	WaitVdpDma				; Wait for the operation to finish

	move.w	vdpReg01,(a6)				; Restore previous DMA enable setting
	move.w	#$8F02,(a6)				; Set auto-increment to 2
	rts

; ----------------------------------------------------------------------
; DMA transfer from 68000 memory to VRAM
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Source address
;	d2.w - Number of words to copy
; ----------------------------------------------------------------------

VdpDma68kMemToVram:
	ori.l	#$40000080,d0				; VRAM DMA

; ----------------------------------------------------------------------
; DMA transfer from 68000 memory to VDP memory
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP DMA command
;	d1.l - Source address
;	d2.w - Number of words to copy
; ----------------------------------------------------------------------

VdpDma68kMemory:
	lea	VDP_CTRL,a6				; VDP control port

	move.w	vdpReg01,d3				; Enable DMA
	ori.b	#1<<4,d3
	move.w	d3,(a6)

	move	sr,-(sp)				; Disable interrupts
	move	#$2700,sr
	
	move.l	d0,-(sp)				; Prepare parameters
	move.l	#$96009500,-(sp)
	move.l	#$93009700,-(sp)
	move.w	#$9400,-(sp)
	asr.l	#1,d1
	movep.l	d1,3(sp)
	movep.w	d2,1(sp)
	
	move.l	(sp)+,(a6)				; Start operation
	move.l	(sp)+,(a6)
	move.l	(sp)+,(a6)
	
	bsr.w	StopZ80
	move.w	(sp)+,(a6)
	bsr.w	StartZ80

	move.w	vdpReg01,(a6)				; Restore previous DMA enable setting
	move	(sp)+,sr				; Restore interrupt settings
	rts
	
; ----------------------------------------------------------------------
; Update palette
; ----------------------------------------------------------------------

UpdateVdpPalette:
	bclr	#0,paletteUpdate			; Should we update the palette?
	beq.s	.End					; If not, branch
	
	move.l	#$C0000080,d0				; Copy palette buffer to CRAM
	move.l	#palette&$FFFFFF,d1
	moveq	#$80/2,d2
	bra.w	VdpDma68kMemory
	
.End:
	rts
	
; ----------------------------------------------------------------------
; Update sprite table
; ----------------------------------------------------------------------

UpdateVdpSprites:
	btst	#0,vblankFlags				; Should we update sprite data?
	beq.s	.End					; If not, branch
	
	move.l	#$78000082,d0				; Copy sprite table to VRAM
	move.l	#sprites&$FFFFFF,d1
	move.w	#$280/2,d2
	bra.w	VdpDma68kMemory
	
.End:
	rts

; ----------------------------------------------------------------------
; DMA transfer from Word RAM to VRAM
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Source address
;	d2.w - Number of words to copy
; ----------------------------------------------------------------------

VdpDmaWordRamToVram:
	move.l	a0,-(sp)				; Save a0
	movea.l	d1,a0					; Save source address for later
	
	move.w	#$8F02,VDP_CTRL				; Set auto-increment to 2
	
	addq.l	#2,d1					; Perform DMA operation
	bsr.w	VdpDma68kMemToVram
	
	andi.w	#~$80,d0				; Manually copy first longword to VRAM
	move.l	d0,(a6)
	move.l	(a0),-4(a6)

	move.w	vdpReg0F,(a6)				; Restore previous auto-increment setting
	movea.l	(sp)+,a0				; Restore a0
	rts

; ----------------------------------------------------------------------
; Draw tilemap
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	a1.l - Pointer to tilemap data
; ----------------------------------------------------------------------

DrawTilemap:
	lea	VDP_DATA,a5				; VDP data port
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	move.w	d1,d3					; Get tilemap width

.DrawRow:
	move.w	(a1)+,(a5)				; Draw tile
	dbf	d3,.DrawRow				; Loop until row is drawn
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	dbf	d2,.NewRow				; Loop until tilemap is drawn
	rts
	
; ----------------------------------------------------------------------
; Draw tilemap with byte tiles
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	d3.w - Base tile properties
;	a1.l - Pointer to tilemap data
; ----------------------------------------------------------------------

DrawByteTilemap:
	lea	VDP_DATA,a5				; VDP data port
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	move.w	d1,d4					; Get tilemap width

.DrawRow:
	move.b	(a1)+,d3				; Draw tile
	move.w	d3,(a5)
	dbf	d4,.DrawRow				; Loop until row is drawn
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	dbf	d2,.NewRow				; Loop until tilemap is drawn
	rts
	
; ----------------------------------------------------------------------
; Draw tilemap with sequential tile IDs
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	d3.w - Starting tile ID
; ----------------------------------------------------------------------

DrawSequentialTilemap:
	lea	VDP_DATA,a5				; VDP data port
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	move.w	d1,d4					; Get tilemap width

.DrawRow:
	move.w	d3,(a5)					; Draw tile
	addq.w	#1,d3					; Next tile
	dbf	d4,.DrawRow				; Loop until row is drawn
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	dbf	d2,.NewRow				; Loop until tilemap is drawn
	rts

; ----------------------------------------------------------------------
; Partially draw tilemap
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap draw width (minus 1)
;	d2.w - Tilemap draw height (minus 1)
;	d3.w - Tilemap stride
; ----------------------------------------------------------------------

DrawPartialTilemap:
	lea	VDP_DATA,a5				; VDP data port
	sub.w	d1,d3					; Get skip value
	sub.w	d1,d3
	subq.w	#2,d3
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	move.w	d1,d4					; Get tilemap width

.DrawRow:
	move.w	(a1)+,(a5)				; Draw tile
	dbf	d4,.DrawRow				; Loop until row is drawn
	adda.w	d3,a1					; Skip to next row
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	dbf	d2,.NewRow				; Loop until tilemap is drawn
	rts
	
; ----------------------------------------------------------------------
; Fill plane region
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Fill width (minus 1)
;	d2.w - Fill height (minus 1)
;	d3.w - Fill value
; ----------------------------------------------------------------------

FillVdpPlaneRegion:
	lea	VDP_DATA,a5				; VDP data port
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	move.w	d1,d5					; Get region width

.DrawRow:
	move.w	d3,(a5)					; Draw tile
	dbf	d5,.DrawRow				; Loop until row is filled
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	dbf	d2,.NewRow				; Loop until region is filled
	rts

; ----------------------------------------------------------------------
; Draw tilemap for Mega CD generated graphics
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	d3.w - Starting tile ID
; ----------------------------------------------------------------------

DrawMcdGraphicsTilemap:
	lea	VDP_DATA,a5				; VDP data port
	move.w	d2,d6					; Get increment value
	addq.w	#1,d6
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	move.w	d1,d4					; Get region width
	move.w	d3,d5					; Get starting tile ID for row
	
.DrawRow:
	move.w	d5,(a5)					; Draw tile
	add.w	d6,d5					; Increment tile ID
	dbf	d4,.DrawRow				; Loop until row is filled
	addq.w	#1,d3					; Set starting tile ID for next row
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	dbf	d2,.NewRow				; Loop until region is filled
	rts

; ----------------------------------------------------------------------
; Enable display
; ----------------------------------------------------------------------

EnableVdpDisplay:
	bset	#6,vdpReg01+1				; Enable display
	move.w	vdpReg01,VDP_CTRL
	rts
	
; ----------------------------------------------------------------------
; Black out display
; ----------------------------------------------------------------------

BlackOutVdpDisplay:
	bsr.w	SetVdpBlackBackground			; Set background to black
	
; ----------------------------------------------------------------------
; Disable display
; ----------------------------------------------------------------------

DisableVdpDisplay:
	bclr	#6,vdpReg01+1				; Enable display
	move.w	vdpReg01,VDP_CTRL
	rts

; ----------------------------------------------------------------------
; Load palette data
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to palette data
; ----------------------------------------------------------------------

LoadVdpPaletteData:
	bset	#0,paletteUpdate			; Update palette

; ----------------------------------------------------------------------
; Load palette data (without updating)
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to palette data
; ----------------------------------------------------------------------

LoadVdpPaletteDataNoUpdate:
	move.l	a2,-(sp)				; Save a2
	
	lea	palette,a2				; Get palette buffer offset
	moveq	#0,d0
	move.b	(a1)+,d0
	adda.w	d0,a2
	
	move.b	(a1)+,d0				; Get palette length
	
.Load:
	move.w	(a1)+,(a2)+				; Copy palette data
	dbf	d0,.Load				; Loop until finished
	
	movea.l	(sp)+,a2				; Restore a2
	rts

; ----------------------------------------------------------------------
; Fade out palette
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.w  - Palette buffer offset
;	d1.w  - Number of colors to fade (minus 1)
; RETURNS:
;	eq/ne - Faded to black/Not yet faded to black
; ----------------------------------------------------------------------

FadeOutVdpPalette:
	movem.l	d0-d6/a0,-(sp)				; Save registers
	
	lea	palette,a0				; Get palette buffer offset
	adda.w	d0,a0
	
	moveq	#0,d0					; Clear faded flag
	
.FadeColors:
	moveq	#$E,d2					; Mask value
	moveq	#2,d3					; Decrement value
	moveq	#3-1,d4					; Number of channels
	move.w	(a0),d5					; Get color
	
.FadeChannels:
	move.w	d5,d6					; Mask channel value
	and.w	d2,d6
	beq.s	.NextChannel				; If it's already 0, branch
	sub.w	d3,d5					; Decrement channel value
	
.NextChannel:
	lsl.w	#4,d2					; Next channel
	lsl.w	#4,d3
	dbf	d4,.FadeChannels			; Loop until finished
	
	move.w	d5,(a0)+				; Store color value
	or.w	d5,d0					; Combine with faded flag
	dbf	d1,.FadeColors				; Loop until palette region is faded
	
	bset	#0,paletteUpdate			; Update palette
	tst.w	d0					; Set zero flag to faded flag

	movem.l	(sp)+,d0-d6/a0				; Restore registers
	rts

; ----------------------------------------------------------------------
; Set up palette fade in
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to palette data to fade into
; ----------------------------------------------------------------------

SetupVdpPaletteFadeIn:
	move.b	(a1)+,palFadeInOffset			; Set fade offset
	move.b	(a1)+,palFadeInLength			; Set fade length
	move.l	a1,palFadeInData			; Set fade palette data
	move.w	#$E,palFadeInIntensity			; Set fade intensity
	rts

; ----------------------------------------------------------------------
; Fade in palette
; ----------------------------------------------------------------------

FadeInVdpPalette:
	movem.l	d0-d6/a0-a1,-(sp)			; Save registers
	
	lea	palette,a0				; Get palette buffer offset
	moveq	#0,d0
	move.b	palFadeInOffset,d0
	adda.w	d0,a0
	
	movea.l	palFadeInData,a1			; Get palette fade data
	move.b	palFadeInLength,d0			; Get palette fade length
	
.FadeColors:
	moveq	#0,d1					; Color buffer
	move.w	palFadeInIntensity,d2			; Fade intensity
	moveq	#$E,d3					; Mask value
	moveq	#3-1,d4					; Number of channels
	move.w	(a1)+,d5				; Get color

.FadeChannels:
	move.w	d5,d6					; Mask channel value
	and.w	d3,d6
	sub.w	d2,d6					; Apply fade intensity
	bpl.s	.NextChannel				; If it's not 0, branch
	moveq	#0,d6					; Cap it at 0
	
.NextChannel:
	or.w	d6,d1					; Set channel value
	lsl.w	#4,d2					; Next channel
	lsl.w	#4,d3
	dbf	d4,.FadeChannels			; Loop until finished
	
	move.w	d1,(a0)+				; Store color
	dbf	d0,.FadeColors				; Loop until palette region is faded
	
	subq.w	#2,palFadeInIntensity			; Decrease the intensity
	bpl.s	.End					; If it hasn't underflown, branch
	clr.w	palFadeInIntensity			; Cap it at 0
	
.End:
	bset	#0,paletteUpdate			; Update palette
	
	movem.l	(sp)+,d0-d6/a0-a1			; Restore registers
	rts

; ----------------------------------------------------------------------
; Draw text
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	a1.l - Pointer to text data
; ----------------------------------------------------------------------

DrawText:
	move.w	fontTile,d1				; Get base font tile ID
	lea	VDP_DATA,a5				; VDP data port
	
.NewRow:
	move.l	d0,4(a5)				; Set VDP command
	
.DrawLine:
	moveq	#0,d2					; Get character
	move.b	(a1)+,d2
	bmi.s	.End					; If we are at the end, branch
	beq.s	.NewLine				; If it's a new line character, branch
	
	add.w	d1,d2					; Draw character
	move.w	d2,(a5)
	bra.s	.DrawLine
	
.NewLine:
	swap	d0					; Next row in plane
	add.w	vdpPlaneStride,d0
	swap	d0
	bra.s	.NewRow
	
.End:
	rts

; ----------------------------------------------------------------------
; Load font with default parameters into VRAM
; ----------------------------------------------------------------------

LoadFontDefault:
	move.l	#$44000000,d0				; Load into start of VRAM
	move.w	d0,fontTile
	move.l	#$00011011,d1				; Set up decode table to use colors 0 and 1

; ----------------------------------------------------------------------
; Load font into VRAM
; ----------------------------------------------------------------------
; The base font tile ID should be set before calling this.
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Decode table
; ----------------------------------------------------------------------

LoadFont:
	lea	Art1bpp_Font,a1				; Font data
	move.w	#(Art1bpp_FontEnd-Art1bpp_Font)/8,d2	; Number of tiles
	bra.w	Decode1bppGraphics			; Decode graphics data

; ----------------------------------------------------------------------
; Flush Word RAM DMA queue
; ----------------------------------------------------------------------

FlushVdpDmaQueue:
	move.w	(a1)+,d2				; Get DMA length
	beq.s	.End					; If we are at the end, branch
	
	move.l	(a1)+,d0				; Do DMA operation
	move.l	(a1)+,d1
	bsr.w	VdpDmaWordRamToVram
	
	bra.s	FlushVdpDmaQueue			; Process next entry
	
.End:
	rts

; ----------------------------------------------------------------------
; Flush short Word RAM DMA queue
; ----------------------------------------------------------------------
; WARNING: Only the first entry is properly processed, the rest get
; treated as regular sized DMA queue entries
; ----------------------------------------------------------------------

FlushShortVdpDmaQueue:
	move.l	a1,d3					; Get base address
	move.w	(a1)+,d2				; Get DMA length
	beq.s	.End					; If we are at the end, branch
	
	move.l	(a1)+,d0				; Get DMA command
	moveq	#0,d1					; Get source address
	move.w	(a1)+,d1
	add.l	d3,d1
	bsr.w	VdpDmaWordRamToVram
	
	bra.s	FlushVdpDmaQueue			; Process next entry (should be FlushShortDMAQueue)

.End:
	rts

; ----------------------------------------------------------------------
; Font
; ----------------------------------------------------------------------

Art1bpp_Font:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $10, $10, $10, $10
	dc.b	$00, $10, $00, $00, $28, $28, $00, $00, $00, $00, $00, $00
	dc.b	$14, $7E, $28, $28, $FC, $50, $00, $00, $10, $3C, $50, $38
	dc.b	$14, $78, $10, $00, $C4, $C8, $10, $20, $4C, $8C, $00, $00
	dc.b	$10, $28, $30, $54, $48, $34, $00, $00, $10, $10, $00, $00
	dc.b	$00, $00, $00, $00, $08, $10, $10, $10, $10, $08, $00, $00
	dc.b	$20, $10, $10, $10, $10, $20, $00, $00, $10, $54, $38, $54
	dc.b	$10, $00, $00, $00, $00, $10, $10, $7C, $10, $10, $00, $00
	dc.b	$00, $00, $00, $00, $00, $10, $20, $00, $00, $00, $00, $7C
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $00, $00
	dc.b	$08, $08, $10, $10, $20, $20, $00, $00, $38, $44, $54, $54
	dc.b	$44, $38, $00, $00, $10, $30, $50, $10, $10, $7C, $00, $00
	dc.b	$38, $44, $08, $10, $20, $7C, $00, $00, $38, $44, $18, $04
	dc.b	$44, $38, $00, $00, $18, $28, $48, $7C, $08, $08, $00, $00
	dc.b	$7C, $40, $78, $04, $04, $78, $00, $00, $3C, $40, $78, $44
	dc.b	$44, $38, $00, $00, $7C, $04, $08, $10, $20, $20, $00, $00
	dc.b	$38, $44, $38, $44, $44, $38, $00, $00, $38, $44, $3C, $04
	dc.b	$44, $38, $00, $00, $00, $10, $00, $00, $00, $10, $00, $00
	dc.b	$00, $10, $00, $00, $00, $10, $20, $00, $00, $08, $10, $20
	dc.b	$10, $08, $00, $00, $00, $7C, $00, $00, $7C, $00, $00, $00
	dc.b	$00, $20, $10, $08, $10, $20, $00, $00, $38, $44, $08, $10
	dc.b	$00, $10, $00, $00, $7C, $82, $9A, $AA, $9E, $80, $7E, $00
	dc.b	$38, $44, $7C, $44, $44, $44, $00, $00, $78, $44, $78, $44
	dc.b	$44, $78, $00, $00, $38, $44, $40, $40, $44, $38, $00, $00
	dc.b	$78, $44, $44, $44, $44, $78, $00, $00, $7C, $40, $78, $40
	dc.b	$40, $7C, $00, $00, $7C, $40, $78, $40, $40, $40, $00, $00
	dc.b	$3C, $40, $5C, $44, $44, $3C, $00, $00, $44, $44, $7C, $44
	dc.b	$44, $44, $00, $00, $7C, $10, $10, $10, $10, $7C, $00, $00
	dc.b	$7C, $10, $10, $10, $50, $20, $00, $00, $44, $48, $50, $70
	dc.b	$48, $44, $00, $00, $40, $40, $40, $40, $40, $7C, $00, $00
	dc.b	$82, $C6, $AA, $92, $82, $82, $00, $00, $44, $64, $74, $5C
	dc.b	$4C, $44, $00, $00, $38, $44, $44, $44, $44, $38, $00, $00
	dc.b	$78, $44, $44, $78, $40, $40, $00, $00, $38, $44, $44, $44
	dc.b	$4C, $3E, $00, $00, $78, $44, $44, $78, $44, $44, $00, $00
	dc.b	$3C, $40, $38, $04, $04, $78, $00, $00, $7C, $10, $10, $10
	dc.b	$10, $10, $00, $00, $44, $44, $44, $44, $44, $38, $00, $00
	dc.b	$44, $44, $28, $28, $10, $10, $00, $00, $82, $82, $92, $AA
	dc.b	$C6, $82, $00, $00, $44, $28, $10, $10, $28, $44, $00, $00
	dc.b	$44, $28, $10, $10, $10, $10, $00, $00, $7C, $08, $10, $20
	dc.b	$40, $7C, $00, $00, $18, $10, $10, $10, $10, $18, $00, $00
	dc.b	$88, $50, $F8, $20, $F8, $20, $00, $00, $30, $10, $10, $10
	dc.b	$10, $30, $00, $00, $10, $28, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $7C, $00, $00, $20, $10, $00, $00
	dc.b	$00, $00, $00, $00, $00, $3C, $44, $44, $44, $3C, $00, $00
	dc.b	$40, $40, $78, $44, $44, $78, $00, $00, $00, $3C, $40, $40
	dc.b	$40, $3C, $00, $00, $04, $04, $3C, $44, $44, $3C, $00, $00
	dc.b	$00, $38, $44, $7C, $40, $3C, $00, $00, $38, $44, $F0, $40
	dc.b	$40, $40, $00, $00, $00, $3C, $44, $44, $44, $3C, $44, $38
	dc.b	$40, $40, $78, $44, $44, $44, $00, $00, $10, $00, $10, $10
	dc.b	$10, $10, $00, $00, $04, $00, $04, $04, $04, $44, $38, $00
	dc.b	$40, $44, $48, $70, $48, $44, $00, $00, $40, $40, $40, $40
	dc.b	$44, $38, $00, $00, $00, $6C, $92, $92, $92, $92, $00, $00
	dc.b	$00, $38, $44, $44, $44, $44, $00, $00, $00, $38, $44, $44
	dc.b	$44, $38, $00, $00, $00, $38, $44, $44, $44, $78, $40, $40
	dc.b	$00, $38, $44, $44, $44, $3C, $04, $04, $00, $38, $44, $40
	dc.b	$40, $40, $00, $00, $00, $3C, $40, $38, $04, $78, $00, $00
	dc.b	$40, $40, $F0, $40, $44, $38, $00, $00, $00, $44, $44, $44
	dc.b	$44, $38, $00, $00, $00, $44, $44, $28, $28, $10, $00, $00
	dc.b	$00, $92, $92, $92, $92, $6C, $00, $00, $00, $44, $28, $10
	dc.b	$28, $44, $00, $00, $00, $44, $44, $44, $44, $3C, $44, $38
	dc.b	$00, $7C, $08, $10, $20, $7C, $00, $00, $08, $10, $30, $10
	dc.b	$10, $08, $00, $00, $10, $10, $10, $10, $10, $10, $00, $00
	dc.b	$20, $10, $18, $10, $10, $20, $00, $00, $00, $00, $24, $54
	dc.b	$48, $00, $00, $00, $7C, $82, $BA, $A2, $BA, $82, $7C, $00
Art1bpp_FontEnd:

; ----------------------------------------------------------------------