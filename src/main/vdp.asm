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
; Set default VDP registers
; ------------------------------------------------------------------------------

SetDefaultVdpRegs:
	lea	DefaultVdpRegs(pc),a1				; Default VDP registers
	move.w	#$40*2,plane_stride				; Set plane stride to 64 tiles

; ------------------------------------------------------------------------------
; Set VDP registers
; ------------------------------------------------------------------------------
; PARAMETERS
;	a1.l - Pointer to VDP register table (0 terminated)
; ------------------------------------------------------------------------------

SetVdpRegisters:
	lea	vdp_reg_00,a2					; VDP register cache

.SetupRegs:
	move.w	(a1)+,d0					; Get register ID and value
	bpl.s	.End						; If we are at the end of the list, branch
	
	cmpi.w	#$9200,d0					; Should it be stored in the cache?
	bhi.s	.SetRegister					; If not, branch
	
	move.w	d0,-(sp)					; Set in cache
	move.b	(sp)+,d1
	andi.w	#$7F,d1
	add.w	d1,d1
	move.w	d0,(a2,d1.w)

.SetRegister:
	move.w	d0,VDP_CTRL					; Set register
	bra.s	.SetupRegs					; Loop

.End:
	rts

; ------------------------------------------------------------------------------

DefaultVdpRegs:
	dc.w	$8000|(%00000100)				; Disable H-BLANK interrupt
	dc.w	$8100|(%00100100)				; Enable V-BLANK interrupt
	dc.w	$8200|($C000/$400)				; Plane A address
	dc.w	$8300|($A000/$400)				; Window plane address
	dc.w	$8400|($E000/$2000)				; Plane B address
	dc.w	$8500|($B800/$200)				; Sprite data address
	dc.w	$8700|($00)					; Background color at first CRAM entry
	dc.w	$8A00|($00)					; H-BLANK interrupt every scanline
	dc.w	$8B00|(%00000000)				; Disable external interrupt
	dc.w	$8C00|(%10000001)				; H40 mode
	dc.w	$8D00|($BC00/$400)				; Horizontal scroll data address
	dc.w	$8F00|($02)					; Auto-increment by 2
	dc.w	$9000|($11)					; 64x64 plane
	dc.w	$9100|($00)					; Window X position at 0
	dc.w	$9200|($00)					; Window Y position at 0
	dc.w	0

; ------------------------------------------------------------------------------
; Wait for a DMA to finish
; ------------------------------------------------------------------------------

WaitVdpDma:
	move	VDP_CTRL,ccr					; Has the operation finished?
	bvs.s	WaitVdpDma					; If not, wait
	rts

; ------------------------------------------------------------------------------
; Set background color to black
; ------------------------------------------------------------------------------

SetBlackBackground:
	move.l	#$C0000000,VDP_CTRL				; Set first color to black
	move.w	#0,VDP_DATA
	rts

; ------------------------------------------------------------------------------
; Clear VDP memory
; ------------------------------------------------------------------------------

ClearVdp:
	bsr.s	SetBlackBackground				; Set background to black
	bsr.w	ClearVsram					; Clear VSRAM
	move.l	#$40000000,d0					; Clear VRAM
	move.w	#$10000-1,d1
	bra.s	ClearVramRegion

; ------------------------------------------------------------------------------
; Clear screen
; ------------------------------------------------------------------------------

ClearScreen:
	bsr.s	ClearSprites					; Clear sprites
	bsr.s	ClearPlaneA					; Clear plane A
	bsr.s	ClearPlaneB					; Clear plane B
	bra.s	ClearWindowPlane				; Clear window plane

; ------------------------------------------------------------------------------
; Clear sprites
; ------------------------------------------------------------------------------

ClearSprites:
	clr.l	sprites						; Clear first sprite slot
	move.l	#$78000002,VDP_CTRL
	move.l	#0,VDP_DATA
	rts
	
; ------------------------------------------------------------------------------
; Clear palette
; ------------------------------------------------------------------------------

ClearPalette:
	lea	palette,a0					; Clear palette buffer
	moveq	#$80/4-1,d0
	moveq	#0,d1
	
.ClearPalette:
	move.l	d1,(a0)+
	dbf	d0,.ClearPalette

; ------------------------------------------------------------------------------
; Clear CRAM
; ------------------------------------------------------------------------------

ClearCram:
	move.l	#$C0000000,d0					; Clear CRAM
	moveq	#$80/2-1,d1
	bra.s	ClearVdpRegion

; ------------------------------------------------------------------------------
; Clear VSRAM
; ------------------------------------------------------------------------------

ClearVsram:
	move.l	#$40000010,d0					; Clear VSRAM
	moveq	#$50/2-1,d1

; ------------------------------------------------------------------------------
; Clear region of VDP memory
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Number of words to clear (minus 1)
; ------------------------------------------------------------------------------

ClearVdpRegion:
	moveq	#0,d2						; Fill with 0

; ------------------------------------------------------------------------------
; Fill region of VDP memory
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Number of words to clear (minus 1)
;	d2.w - Value to fill with
; ------------------------------------------------------------------------------

FillVdpRegion:
	move.l	d0,VDP_CTRL					; Set VDP command

.Fill:
	move.w	d2,VDP_DATA					; Fill
	dbf	d1,.Fill
	rts

; ------------------------------------------------------------------------------
; Clear window plane
; ------------------------------------------------------------------------------

ClearWindowPlane:
	move.l	#$60000002,d0					; Clear window plane
	move.w	#$E00-1,d1
	bra.w	ClearVramRegion

; ------------------------------------------------------------------------------
; Clear plane A
; ------------------------------------------------------------------------------

ClearPlaneA:
	move.l	#$40000003,d0					; Clear plane A
	move.w	#$2000-1,d1
	bra.s	ClearVramRegion

; ------------------------------------------------------------------------------
; Clear plane B
; ------------------------------------------------------------------------------

ClearPlaneB:
	move.l	#$60000003,d0					; Clear plane B
	move.w	#$2000-1,d1

; ------------------------------------------------------------------------------
; Clear a region of VRAM
; ------------------------------------------------------------------------------
; PARAMETERS
;	d0.l - VDP command
;	d1.w - Number of bytes to clear (minus 1)
; ------------------------------------------------------------------------------

ClearVramRegion:
	moveq	#0,d2						; Fill with 0

; ------------------------------------------------------------------------------
; Fill a region of VRAM
; ------------------------------------------------------------------------------
; PARAMETERS
;	d0.l - VDP command
;	d1.w - Number of bytes to clear (minus 1)
;	d2.b - Value to fill with
; ------------------------------------------------------------------------------

FillVramRegion:
	lea	VDP_CTRL,a6					; VDP control port

	move.w	#$8F01,(a6)					; Set auto-increment to 1
	move.w	vdp_reg_01,d3					; Enable DMA
	ori.b	#1<<4,d3
	move.w	d3,(a6)
	
	move.l	#$94009300,-(sp)				; Start operation
	movep.w	d1,1(sp)
	move.l	(sp)+,(a6)
	move.w	#$9780,(a6)
	ori.l	#$40000080,d0
	move.l	d0,(a6)
	move.w	d2,-4(a6)

	bsr.w	WaitVdpDma					; Wait for the operation to finish

	move.w	vdp_reg_01,(a6)					; Restore previous DMA enable setting
	move.w	#$8F02,(a6)					; Set auto-increment to 2
	rts

; ------------------------------------------------------------------------------
; Copy a region of VRAM to another place in VRAM
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command for destination VRAM address
;	d1.w - Source VRAM address
;	d2.w - Number of bytes to copy
; ------------------------------------------------------------------------------

CopyVramRegion:
	lea	VDP_CTRL,a6					; VDP control port

	move.w	#$8F01,(a6)					; Set auto-increment to 1
	move.w	vdp_reg_01,d3					; Enable DMA
	ori.b	#1<<4,d3
	move.w	d3,(a6)
	
	move.l	#$94009300,-(sp)				; Prepare parameters
	move.l	#$96009500,-(sp)
	movep.w	d1,1(sp)
	movep.w	d2,5(sp)

	move.l	(sp)+,(a6)					; Start operation
	move.l	(sp)+,(a6)
	move.w	#$97C0,(a6)
	ori.w	#$C0,d0
	move.l	d0,(a6)

	bsr.w	WaitVdpDma					; Wait for the operation to finish

	move.w	vdp_reg_01,(a6)					; Restore previous DMA enable setting
	move.w	#$8F02,(a6)					; Set auto-increment to 2
	rts

; ------------------------------------------------------------------------------
; DMA transfer from 68000 memory to VRAM
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Source address
;	d2.w - Number of words to copy
; ------------------------------------------------------------------------------

DmaToVram:
	ori.l	#$40000080,d0					; VRAM DMA

; ------------------------------------------------------------------------------
; DMA transfer from 68000 memory to VDP memory
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP DMA command
;	d1.l - Source address
;	d2.w - Number of words to copy
; ------------------------------------------------------------------------------

DmaToVdp:
	lea	VDP_CTRL,a6					; VDP control port

	move.w	vdp_reg_01,d3					; Enable DMA
	ori.b	#1<<4,d3
	move.w	d3,(a6)

	move	sr,-(sp)					; Disable interrupts
	move	#$2700,sr
	
	move.l	d0,-(sp)					; Prepare parameters
	move.l	#$96009500,-(sp)
	move.l	#$93009700,-(sp)
	move.w	#$9400,-(sp)
	asr.l	#1,d1
	movep.l	d1,3(sp)
	movep.w	d2,1(sp)
	
	move.l	(sp)+,(a6)					; Start operation
	move.l	(sp)+,(a6)
	move.l	(sp)+,(a6)
	
	bsr.w	StopZ80
	move.w	(sp)+,(a6)
	bsr.w	StartZ80

	move.w	vdp_reg_01,(a6)					; Restore previous DMA enable setting
	move	(sp)+,sr					; Restore interrupt settings
	rts
	
; ------------------------------------------------------------------------------
; Update CRAM
; ------------------------------------------------------------------------------

UpdateCram:
	bclr	#0,update_cram					; Should we update the palette?
	beq.s	.End						; If not, branch
	
	move.l	#$C0000080,d0					; Copy palette buffer to CRAM
	move.l	#palette&$FFFFFF,d1
	moveq	#$80/2,d2
	bra.w	DmaToVdp
	
.End:
	rts
	
; ------------------------------------------------------------------------------
; Update sprite table
; ------------------------------------------------------------------------------

UpdateSprites:
	btst	#0,vblank_flags					; Should we update sprite data?
	beq.s	.End						; If not, branch
	
	move.l	#$78000082,d0					; Copy sprite table to VRAM
	move.l	#sprites&$FFFFFF,d1
	move.w	#$280/2,d2
	bra.w	DmaToVdp
	
.End:
	rts

; ------------------------------------------------------------------------------
; DMA transfer from Word RAM to VRAM
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Source address
;	d2.w - Number of words to copy
; ------------------------------------------------------------------------------

DmaWordRamToVram:
	move.l	a0,-(sp)					; Save a0
	movea.l	d1,a0						; Save source address for later
	
	move.w	#$8F02,VDP_CTRL					; Set auto-increment to 2
	
	addq.l	#2,d1						; Perform DMA operation
	bsr.w	DmaToVram
	
	andi.w	#~$80,d0					; Manually copy first longword to VRAM
	move.l	d0,(a6)
	move.l	(a0),-4(a6)

	move.w	vdp_reg_0f,(a6)					; Restore previous auto-increment setting
	movea.l	(sp)+,a0					; Restore a0
	rts

; ------------------------------------------------------------------------------
; Draw tilemap
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	a1.l - Pointer to tilemap data
; ------------------------------------------------------------------------------

DrawTilemap:
	lea	VDP_DATA,a5					; VDP data port
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	move.w	d1,d3						; Get tilemap width

.DrawRow:
	move.w	(a1)+,(a5)					; Draw tile
	dbf	d3,.DrawRow					; Loop until row is drawn
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	dbf	d2,.NewRow					; Loop until tilemap is drawn
	rts
	
; ------------------------------------------------------------------------------
; Draw tilemap with byte tiles
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	d3.w - Base tile properties
;	a1.l - Pointer to tilemap data
; ------------------------------------------------------------------------------

DrawByteTilemap:
	lea	VDP_DATA,a5					; VDP data port
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	move.w	d1,d4						; Get tilemap width

.DrawRow:
	move.b	(a1)+,d3					; Draw tile
	move.w	d3,(a5)
	dbf	d4,.DrawRow					; Loop until row is drawn
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	dbf	d2,.NewRow					; Loop until tilemap is drawn
	rts
	
; ------------------------------------------------------------------------------
; Draw tilemap with sequential tile IDs
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	d3.w - Starting tile ID
; ------------------------------------------------------------------------------

DrawSequentialTilemap:
	lea	VDP_DATA,a5					; VDP data port
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	move.w	d1,d4						; Get tilemap width

.DrawRow:
	move.w	d3,(a5)						; Draw tile
	addq.w	#1,d3						; Next tile
	dbf	d4,.DrawRow					; Loop until row is drawn
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	dbf	d2,.NewRow					; Loop until tilemap is drawn
	rts

; ------------------------------------------------------------------------------
; Partially draw tilemap
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap draw width (minus 1)
;	d2.w - Tilemap draw height (minus 1)
;	d3.w - Tilemap stride
; ------------------------------------------------------------------------------

DrawPartialTilemap:
	lea	VDP_DATA,a5					; VDP data port
	sub.w	d1,d3						; Get skip value
	sub.w	d1,d3
	subq.w	#2,d3
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	move.w	d1,d4						; Get tilemap width

.DrawRow:
	move.w	(a1)+,(a5)					; Draw tile
	dbf	d4,.DrawRow					; Loop until row is drawn
	adda.w	d3,a1						; Skip to next row
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	dbf	d2,.NewRow					; Loop until tilemap is drawn
	rts
	
; ------------------------------------------------------------------------------
; Fill plane region
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Fill width (minus 1)
;	d2.w - Fill height (minus 1)
;	d3.w - Fill value
; ------------------------------------------------------------------------------

FillPlaneRegion:
	lea	VDP_DATA,a5					; VDP data port
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	move.w	d1,d5						; Get region width

.DrawRow:
	move.w	d3,(a5)						; Draw tile
	dbf	d5,.DrawRow					; Loop until row is filled
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	dbf	d2,.NewRow					; Loop until region is filled
	rts

; ------------------------------------------------------------------------------
; Draw tilemap for Mega CD generated graphics
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.w - Tilemap width (minus 1)
;	d2.w - Tilemap height (minus 1)
;	d3.w - Starting tile ID
; ------------------------------------------------------------------------------

DrawMcdImageTilemap:
	lea	VDP_DATA,a5					; VDP data port
	move.w	d2,d6						; Get increment value
	addq.w	#1,d6
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	move.w	d1,d4						; Get region width
	move.w	d3,d5						; Get starting tile ID for row
	
.DrawRow:
	move.w	d5,(a5)						; Draw tile
	add.w	d6,d5						; Increment tile ID
	dbf	d4,.DrawRow					; Loop until row is filled
	addq.w	#1,d3						; Set starting tile ID for next row
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	dbf	d2,.NewRow					; Loop until region is filled
	rts

; ------------------------------------------------------------------------------
; Enable display
; ------------------------------------------------------------------------------

EnableDisplay:
	bset	#6,vdp_reg_01+1					; Enable display
	move.w	vdp_reg_01,VDP_CTRL
	rts
	
; ------------------------------------------------------------------------------
; Black out display
; ------------------------------------------------------------------------------

BlackOutDisplay:
	bsr.w	SetBlackBackground				; Set background to black
	
; ------------------------------------------------------------------------------
; Disable display
; ------------------------------------------------------------------------------

DisableDisplay:
	bclr	#6,vdp_reg_01+1					; Enable display
	move.w	vdp_reg_01,VDP_CTRL
	rts

; ------------------------------------------------------------------------------
; Load palette
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to palette data
; ------------------------------------------------------------------------------

LoadPalette:
	bset	#0,update_cram					; Update CRAM

; ------------------------------------------------------------------------------
; Load palette (without updating)
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to palette data
; ------------------------------------------------------------------------------

LoadPaletteNoUpdate:
	move.l	a2,-(sp)					; Save a2
	
	lea	palette,a2					; Get palette buffer offset
	moveq	#0,d0
	move.b	(a1)+,d0
	adda.w	d0,a2
	
	move.b	(a1)+,d0					; Get palette length
	
.Load:
	move.w	(a1)+,(a2)+					; Copy palette data
	dbf	d0,.Load					; Loop until finished
	
	movea.l	(sp)+,a2					; Restore a2
	rts

; ------------------------------------------------------------------------------
; Fade out palette
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.w  - Palette buffer offset
;	d1.w  - Number of colors to fade (minus 1)
; RETURNS:
;	eq/ne - Faded to black/Not yet faded to black
; ------------------------------------------------------------------------------

FadeOutPalette:
	movem.l	d0-d6/a0,-(sp)					; Save registers
	
	lea	palette,a0					; Get palette buffer offset
	adda.w	d0,a0
	
	moveq	#0,d0						; Clear faded flag
	
.FadeColors:
	moveq	#$E,d2						; Mask value
	moveq	#2,d3						; Decrement value
	moveq	#3-1,d4						; Number of channels
	move.w	(a0),d5						; Get color
	
.FadeChannels:
	move.w	d5,d6						; Mask channel value
	and.w	d2,d6
	beq.s	.NextChannel					; If it's already 0, branch
	sub.w	d3,d5						; Decrement channel value
	
.NextChannel:
	lsl.w	#4,d2						; Next channel
	lsl.w	#4,d3
	dbf	d4,.FadeChannels				; Loop until finished
	
	move.w	d5,(a0)+					; Store color value
	or.w	d5,d0						; Combine with faded flag
	dbf	d1,.FadeColors					; Loop until palette region is faded
	
	bset	#0,update_cram					; Update CRAM
	tst.w	d0						; Set zero flag to faded flag

	movem.l	(sp)+,d0-d6/a0					; Restore registers
	rts

; ------------------------------------------------------------------------------
; Set up palette fade in
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to palette data to fade into
; ------------------------------------------------------------------------------

SetupPaletteFadeIn:
	move.b	(a1)+,fade_in_offset				; Set fade offset
	move.b	(a1)+,fade_in_length				; Set fade length
	move.l	a1,fade_in_data					; Set fade palette data
	move.w	#$E,fade_in_intensity				; Set fade intensity
	rts

; ------------------------------------------------------------------------------
; Fade in palette
; ------------------------------------------------------------------------------

FadeInPalette:
	movem.l	d0-d6/a0-a1,-(sp)				; Save registers
	
	lea	palette,a0					; Get palette buffer offset
	moveq	#0,d0
	move.b	fade_in_offset,d0
	adda.w	d0,a0
	
	movea.l	fade_in_data,a1					; Get palette fade data
	move.b	fade_in_length,d0				; Get palette fade length
	
.FadeColors:
	moveq	#0,d1						; Color buffer
	move.w	fade_in_intensity,d2				; Fade intensity
	moveq	#$E,d3						; Mask value
	moveq	#3-1,d4						; Number of channels
	move.w	(a1)+,d5					; Get color

.FadeChannels:
	move.w	d5,d6						; Mask channel value
	and.w	d3,d6
	sub.w	d2,d6						; Apply fade intensity
	bpl.s	.NextChannel					; If it's not 0, branch
	moveq	#0,d6						; Cap it at 0
	
.NextChannel:
	or.w	d6,d1						; Set channel value
	lsl.w	#4,d2						; Next channel
	lsl.w	#4,d3
	dbf	d4,.FadeChannels				; Loop until finished
	
	move.w	d1,(a0)+					; Store color
	dbf	d0,.FadeColors					; Loop until palette region is faded
	
	subq.w	#2,fade_in_intensity				; Decrease the intensity
	bpl.s	.End						; If it hasn't underflown, branch
	clr.w	fade_in_intensity				; Cap it at 0
	
.End:
	bset	#0,update_cram					; Update CRAM
	
	movem.l	(sp)+,d0-d6/a0-a1				; Restore registers
	rts

; ------------------------------------------------------------------------------
; Draw text
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	a1.l - Pointer to text data
; ------------------------------------------------------------------------------

DrawText:
	move.w	font_tile,d1					; Get base font tile ID
	lea	VDP_DATA,a5					; VDP data port
	
.NewRow:
	move.l	d0,4(a5)					; Set VDP command
	
.DrawLine:
	moveq	#0,d2						; Get character
	move.b	(a1)+,d2
	bmi.s	.End						; If we are at the end, branch
	beq.s	.NewLine					; If it's a new line character, branch
	
	add.w	d1,d2						; Draw character
	move.w	d2,(a5)
	bra.s	.DrawLine
	
.NewLine:
	swap	d0						; Next row in plane
	add.w	plane_stride,d0
	swap	d0
	bra.s	.NewRow
	
.End:
	rts

; ------------------------------------------------------------------------------
; Load font with default parameters into VRAM
; ------------------------------------------------------------------------------

LoadFontDefault:
	move.l	#$44000000,d0					; Load into start of VRAM
	move.w	d0,font_tile
	move.l	#$00011011,d1					; Set up decode table to use colors 0 and 1

; ------------------------------------------------------------------------------
; Load font into VRAM
; ------------------------------------------------------------------------------
; The base font tile ID should be set before calling this.
; ------------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Decode table
; ------------------------------------------------------------------------------

LoadFont:
	lea	FontArt,a1					; Font data
	move.w	#(FontArtEnd-FontArt)/8,d2			; Number of tiles
	bra.w	Decode1bppArt					; Decode graphics data

; ------------------------------------------------------------------------------
; Flush Word RAM DMA queue
; ------------------------------------------------------------------------------

FlushDmaQueue:
	move.w	(a1)+,d2					; Get DMA length
	beq.s	.End						; If we are at the end, branch
	
	move.l	(a1)+,d0					; Do DMA operation
	move.l	(a1)+,d1
	bsr.w	DmaWordRamToVram
	
	bra.s	FlushDmaQueue					; Process next entry
	
.End:
	rts

; ------------------------------------------------------------------------------
; Flush short Word RAM DMA queue
; ------------------------------------------------------------------------------
; WARNING: Only the first entry is properly processed, the rest get
; treated as regular sized DMA queue entries
; ------------------------------------------------------------------------------

FlushShortDmaQueue:
	move.l	a1,d3						; Get base address
	move.w	(a1)+,d2					; Get DMA length
	beq.s	.End						; If we are at the end, branch
	
	move.l	(a1)+,d0					; Get DMA command
	moveq	#0,d1						; Get source address
	move.w	(a1)+,d1
	add.l	d3,d1
	bsr.w	DmaWordRamToVram
	
	bra.s	FlushDmaQueue					; Process next entry (should be FlushShortDmaQueue)

.End:
	rts

; ------------------------------------------------------------------------------
; Font
; ------------------------------------------------------------------------------

FontArt:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $18, $18
	dc.b	$00, $18, $00, $00, $36, $36, $00, $00, $00, $00, $00, $00
	dc.b	$36, $7F, $36, $6C, $FE, $6C, $00, $00, $10, $7E, $D0, $7C
	dc.b	$16, $FC, $10, $00, $C6, $CC, $18, $30, $66, $C6, $00, $00
	dc.b	$38, $6C, $78, $DE, $CC, $76, $00, $00, $18, $18, $00, $00
	dc.b	$00, $00, $00, $00, $0C, $18, $18, $18, $18, $0C, $00, $00
	dc.b	$30, $18, $18, $18, $18, $30, $00, $00, $18, $7E, $3C, $7E
	dc.b	$18, $00, $00, $00, $00, $18, $18, $7E, $18, $18, $00, $00
	dc.b	$00, $00, $00, $00, $00, $18, $30, $00, $00, $00, $00, $7E
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $00, $00
	dc.b	$0C, $0C, $18, $18, $30, $30, $00, $00, $3C, $66, $6E, $76
	dc.b	$66, $3C, $00, $00, $18, $38, $58, $18, $18, $7E, $00, $00
	dc.b	$3C, $66, $0C, $18, $30, $7E, $00, $00, $3C, $66, $1C, $06
	dc.b	$66, $3C, $00, $00, $1C, $3C, $6C, $7E, $0C, $0C, $00, $00
	dc.b	$7E, $60, $7C, $06, $06, $7C, $00, $00, $3E, $60, $7C, $66
	dc.b	$66, $3C, $00, $00, $7E, $06, $0C, $18, $30, $30, $00, $00
	dc.b	$3C, $66, $3C, $66, $66, $3C, $00, $00, $3C, $66, $3E, $06
	dc.b	$66, $3C, $00, $00, $18, $18, $00, $00, $18, $18, $00, $00
	dc.b	$00, $18, $18, $00, $00, $18, $30, $00, $00, $0C, $18, $30
	dc.b	$18, $0C, $00, $00, $00, $7E, $00, $00, $7E, $00, $00, $00
	dc.b	$00, $30, $18, $0C, $18, $30, $00, $00, $3C, $66, $0C, $18
	dc.b	$00, $18, $00, $00, $7C, $82, $9A, $AA, $9E, $80, $7E, $00
	dc.b	$3C, $66, $7E, $66, $66, $66, $00, $00, $7C, $66, $7C, $66
	dc.b	$66, $7C, $00, $00, $3C, $66, $60, $60, $66, $3C, $00, $00
	dc.b	$7C, $66, $66, $66, $66, $7C, $00, $00, $7E, $60, $7C, $60
	dc.b	$60, $7E, $00, $00, $7E, $60, $7C, $60, $60, $60, $00, $00
	dc.b	$3E, $60, $6E, $66, $66, $3E, $00, $00, $66, $66, $7E, $66
	dc.b	$66, $66, $00, $00, $7E, $18, $18, $18, $18, $7E, $00, $00
	dc.b	$7E, $18, $18, $18, $58, $30, $00, $00, $66, $6C, $78, $78
	dc.b	$6C, $66, $00, $00, $60, $60, $60, $60, $60, $7E, $00, $00
	dc.b	$63, $77, $6B, $63, $63, $63, $00, $00, $66, $66, $76, $7E
	dc.b	$6E, $66, $00, $00, $3C, $66, $66, $66, $66, $3C, $00, $00
	dc.b	$7C, $66, $66, $7C, $60, $60, $00, $00, $3C, $66, $66, $66
	dc.b	$6E, $3F, $00, $00, $7C, $66, $66, $7C, $66, $66, $00, $00
	dc.b	$3E, $60, $3C, $06, $06, $7C, $00, $00, $7E, $18, $18, $18
	dc.b	$18, $18, $00, $00, $66, $66, $66, $66, $66, $3C, $00, $00
	dc.b	$66, $66, $2C, $2C, $18, $18, $00, $00, $63, $63, $63, $6B
	dc.b	$77, $63, $00, $00, $66, $3C, $18, $18, $3C, $66, $00, $00
	dc.b	$66, $66, $3C, $18, $18, $18, $00, $00, $7E, $0C, $18, $30
	dc.b	$60, $7E, $00, $00, $1C, $18, $18, $18, $18, $1C, $00, $00
	dc.b	$CC, $78, $FC, $30, $FC, $30, $00, $00, $38, $18, $18, $18
	dc.b	$18, $38, $00, $00, $18, $3C, $66, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $7E, $00, $00, $30, $18, $00, $00
	dc.b	$00, $00, $00, $00, $00, $3E, $66, $66, $66, $3E, $00, $00
	dc.b	$60, $60, $7C, $66, $66, $7C, $00, $00, $00, $3E, $60, $60
	dc.b	$60, $3E, $00, $00, $06, $06, $3E, $66, $66, $3E, $00, $00
	dc.b	$00, $3C, $66, $7E, $60, $3E, $00, $00, $3C, $66, $F8, $60
	dc.b	$60, $60, $00, $00, $00, $3E, $66, $66, $66, $3E, $46, $3C
	dc.b	$60, $60, $7C, $66, $66, $66, $00, $00, $18, $00, $18, $18
	dc.b	$18, $18, $00, $00, $06, $00, $06, $06, $06, $66, $3C, $00
	dc.b	$60, $66, $6C, $78, $6C, $66, $00, $00, $60, $60, $60, $60
	dc.b	$66, $3C, $00, $00, $00, $36, $6B, $6B, $6B, $6B, $00, $00
	dc.b	$00, $3C, $66, $66, $66, $66, $00, $00, $00, $3C, $66, $66
	dc.b	$66, $3C, $00, $00, $00, $3C, $66, $66, $66, $7C, $60, $60
	dc.b	$00, $3C, $66, $66, $66, $3E, $06, $06, $00, $3C, $66, $60
	dc.b	$60, $60, $00, $00, $00, $3E, $60, $3C, $06, $7C, $00, $00
	dc.b	$60, $60, $F8, $60, $66, $3C, $00, $00, $00, $66, $66, $66
	dc.b	$66, $3C, $00, $00, $00, $66, $66, $2C, $2C, $18, $00, $00
	dc.b	$00, $6B, $6B, $6B, $6B, $36, $00, $00, $00, $66, $3C, $18
	dc.b	$3C, $66, $00, $00, $00, $66, $66, $66, $66, $3E, $46, $3C
	dc.b	$00, $7E, $0C, $18, $30, $7E, $00, $00, $0C, $18, $38, $18
	dc.b	$18, $0C, $00, $00, $18, $18, $18, $18, $18, $18, $00, $00
	dc.b	$30, $18, $1C, $18, $18, $30, $00, $00, $00, $00, $66, $D6
	dc.b	$CC, $00, $00, $00, $7C, $82, $BA, $A2, $BA, $82, $7C, $00
FontArtEnd:

; ------------------------------------------------------------------------------