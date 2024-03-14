; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU decompression functions
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
; Decompress Nemesis compressed graphics data
; Format details: https://segaretro.org/Nemesis_compression
; ----------------------------------------------------------------------
; When writing to VDP memory, set the VDP command first before calling.
; Requires $200 bytes allocated in RAM for the code table.
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to source graphics data
;	a2.l - Pointer to destination buffer (RAM write only)
; ----------------------------------------------------------------------

NemDecToRAM:
	movem.l	d0-a5,-(sp)				; Save registers
	lea	NemDec_WriteRowToRAM(pc),a3		; Write to RAM
	bsr.s	NemDecMain				; Decompress data
	movem.l	(sp)+,d0-a5				; Restore registers
	rts
	
; ----------------------------------------------------------------------

NemDec:
	movem.l	d0-a5,-(sp)				; Save registers
	lea	NemDec_WriteRowToVDP(pc),a3		; Write to VRAM
	lea	VDP_DATA,a2				; VDP data port
	bsr.s	NemDecMain				; Decompress data
	movem.l	(sp)+,d0-a5				; Restore registers
	rts
	
; ----------------------------------------------------------------------

NemDecMain:
	lea	nemBuffer,a4				; Code table buffer
	
	move.w	(a1)+,d0				; Get number of tiles
	bpl.s	.NotXOR					; If XOR mode is not set, branch
	lea	$A(a3),a3				; Use XOR version of data writer
	
.NotXOR:
	lsl.w	#3,d0					; Get number of 8 pixel rows
	movea.w	d0,a5
	
	bsr.w	NemDec_BuildCodeTable			; Build code table
	
	moveq	#8,d3					; Reset pixel count
	moveq	#0,d2					; Clear XOR pixel row data
	moveq	#0,d4					; Clear pixel row data
	
	move.b	(a1)+,-(sp)				; Get first word
	move.w	(sp)+,d5
	move.b	(a1)+,d5
	moveq	#16,d6

; ----------------------------------------------------------------------

NemDec_GetCode:
	cmpi.w	#%1111110000000000,d5			; Are the high 6 bits set in the code?
	bcc.s	NemDec_GetInlinePixel			; If so, branch
	
	moveq	#0,d1					; Get code table entry index
	move.w	d5,-(sp)
	move.b	(sp)+,d1
	add.w	d1,d1
	
	moveq	#0,d0					; Advance bitstream past code
	move.b	(a4,d1.w),d0
	sub.w	d0,d6
	rol.w	d0,d5
	
	move.b	1(a4,d1.w),d1				; Get pixel value and repeat count
	
NemDec_StartPixelCopy:
	cmpi.w	#8,d6					; Should we get another byte?
	bhi.s	.NoRead					; If not, branch

	move.w	d6,d7					; Get number of bits read past byte
	subq.w	#8,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5
	addq.w	#8,d6

.NoRead:
	move.w	d1,d0					; Get pixel value
	andi.w	#$F,d1
	andi.w	#$70,d0					; Get repeat count
	lsr.w	#4,d0
	
NemDec_WritePixel:
	lsl.l	#4,d4					; Write pixel
	or.b	d1,d4
	
	subq.w	#1,d3					; Decrement number of pixels in row
	beq.s	.WriteRow				; If the row is fully written, branch

	dbf	d0,NemDec_WritePixel			; Loop until repeated pixels are written
	bra.s	NemDec_GetCode				; Process next code
	
.WriteRow:
	jmp	(a3)					; Write pixel row to memory

NemDec_NewPixelRow:
	moveq	#8,d3					; Reset pixel count
	moveq	#0,d4					; Reset pixel row data

	dbf	d0,NemDec_WritePixel			; Loop until repeated pixels are written
	bra.s	NemDec_GetCode				; Process next code

; ----------------------------------------------------------------------

NemDec_GetInlinePixel:
	subq.w	#6,d6					; Advance bitstream past code
	rol.w	#6,d5

	cmpi.w	#8,d6					; Should we get another byte?
	bhi.s	.NoRead					; If not, branch

	move.w	d6,d7					; Get number of bits read past byte
	subq.w	#8,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5
	addq.w	#8,d6

.NoRead:
	subq.w	#7,d6					; Get inline data
	rol.w	#7,d5
	
	move.w	d5,d1					; Start copying pixel from inline data
	bra.s	NemDec_StartPixelCopy
	
; ----------------------------------------------------------------------

NemDec_WriteRowToVDP:
	move.l	d4,(a2)					; Write pixel row
	subq.w	#1,a5					; Decrement number of pixel rows left
	move.w	a5,d7
	bne.s	NemDec_NewPixelRow			; If there's still pixel rows to write, branch
	rts

NemDec_WriteXORRowToVDP:
	eor.l	d4,d2					; XOR previous pixel row with current pixel row
	move.l	d2,(a2)					; Write pixel row
	subq.w	#1,a5					; Decrement number of pixel rows left
	move.w	a5,d7
	bne.s	NemDec_NewPixelRow			; If there's still pixel rows to write, branch
	rts
	
; ----------------------------------------------------------------------

NemDec_WriteRowToRAM:
	move.l	d4,(a2)+				; Write pixel row
	subq.w	#1,a5					; Decrement number of pixel rows left
	move.w	a5,d7
	bne.s	NemDec_NewPixelRow			; If there's still pixel rows to write, branch
	rts

NemDec_WriteXORRowToRAM:
	eor.l	d4,d2					; XOR previous pixel row with current pixel row
	move.l	d2,(a2)+				; Write pixel row
	subq.w	#1,a5					; Decrement number of pixel rows left
	move.w	a5,d7
	rts
	
; ----------------------------------------------------------------------

NemDec_BuildCodeTable:
	move.b	(a1)+,d0				; Get byte
	bpl.s	.NotPaletteIndex			; If it's not a pixel value, branch
	
	cmpi.b	#$FF,d0					; Are we at the end?
	beq.s	.End					; If so, branch
	
	move.b	d0,d2					; Get pixel value
	bra.s	NemDec_BuildCodeTable			; Get next byte

.NotPaletteIndex:
	moveq	#$F,d1					; Mask out pixel value and code length
	and.w	d1,d2
	and.w	d0,d1
	
	ext.w	d0					; Form code table entry
	add.w	d0,d0
	or.w	.ShiftedCodes(pc,d0.w),d2
	
	subq.w	#8,d1					; Get shift value based on code length
	neg.w	d1
	
	move.b	(a1)+,d0				; Get code table index
	lsl.w	d1,d0
	add.w	d0,d0
	
	lea	(a4,d0.w),a0				; Get first code table entry
	move.b	.EntryCounts(pc,d1.w),d1		; Get entry count
	
.StoreCode:
	move.w	d2,(a0)+				; Store code table entry
	dbf	d1,.StoreCode				; Loop until finished
	
	bra.s	NemDec_BuildCodeTable			; Get next byte
		
.End:
	rts

; ----------------------------------------------------------------------

.EntryCounts:
	dc.b	(1<<0)-1, (1<<1)-1, (1<<2)-1, (1<<3)-1
	dc.b	(1<<4)-1, (1<<5)-1, (1<<6)-1, (1<<7)-1
	dc.b	(1<<8)-1
	even

.ShiftedCodes:
	dc.w	$000, $100, $200, $300, $400, $500, $600, $700
	dc.w	$800, $900, $A00, $B00, $C00, $D00, $E00, $F00
	dc.w	$010, $110, $210, $310, $410, $510, $610, $710
	dc.w	$810, $910, $A10, $B10, $C10, $D10, $E10, $F10
	dc.w	$020, $120, $220, $320, $420, $520, $620, $720
	dc.w	$820, $920, $A20, $B20, $C20, $D20, $E20, $F20
	dc.w	$030, $130, $230, $330, $430, $530, $630, $730
	dc.w	$830, $930, $A30, $B30, $C30, $D30, $E30, $F30
	dc.w	$040, $140, $240, $340, $440, $540, $640, $740
	dc.w	$840, $940, $A40, $B40, $C40, $D40, $E40, $F40
	dc.w	$050, $150, $250, $350, $450, $550, $650, $750
	dc.w	$850, $950, $A50, $B50, $C50, $D50, $E50, $F50
	dc.w	$060, $160, $260, $360, $460, $560, $660, $760
	dc.w	$860, $960, $A60, $B60, $C60, $D60, $E60, $F60
	dc.w	$070, $170, $270, $370, $470, $570, $670, $770
	dc.w	$870, $970, $A70, $B70, $C70, $D70, $E70, $F70

; ----------------------------------------------------------------------
; Decompress Enigma compressed tilemap data
; Format details: https://segaretro.org/Enigma_compression
; ----------------------------------------------------------------------
; PARAMETERS:
;	a1.l - Pointer to source tilemap data
;	a2.l - Pointer to destination buffer
;	d0.w - Base tile properties
; ----------------------------------------------------------------------
; RETURNS:
;	a1.l - Pointer to end of source tilemap data
;	a2.l - Pointer to end of destination buffer
; ----------------------------------------------------------------------

EniDec:
	movem.l	d0-d7/a3-a6,-(sp)			; Save registers
	movea.w	d0,a3					; Save base tile properties

	moveq	#0,d4					; Get number of tile bits
	move.b	(a1)+,d4
	move.b	(a1)+,d0				; Get tile flags
	lsl.b	#3,d0
	movea.w	d0,a4
	movea.w	(a1)+,a5				; Get incrementing tile
	adda.w	a3,a5
	movea.w	(a1)+,a6				; Get static tile
	adda.w	a3,a6

	move.w	(a1)+,d5				; Get first word
	moveq	#16,d6

; ----------------------------------------------------------------------

EniDec_GetCode:
	subq.w	#1,d6					; Does the next code involve using an inline tile?
	rol.w	#1,d5
	bcs.s	.InlineTileCode				; If so, branch

	subq.w	#1,d6					; Should we copy the static tile?
	rol.w	#1,d5
	bcs.s	.Mode01					; If so, branch

.Mode00:
	subq.w	#4,d6					; Get copy length
	rol.w	#4,d5
	move.w	d5,d0
	andi.w	#$F,d0
	
.Mode00Copy:
	move.w	a5,(a2)+				; Copy incrementing tile
	addq.w	#1,a5					; Increment
	dbf	d0,.Mode00Copy				; Loop until enough is copied
	bra.s	.NextCode				; Process next code

.Mode01:
	subq.w	#4,d6					; Get copy length
	rol.w	#4,d5
	move.w	d5,d0
	andi.w	#$F,d0
	
.Mode01Copy:
	move.w	a6,(a2)+				; Copy static tile
	dbf	d0,.Mode01Copy				; Loop until enough is copied
	
.NextCode:
	cmpi.w	#8,d6					; Should we get another byte?
	bhi.s	.NoRead					; If not, branch

	move.w	d6,d7					; Get number of bits read past byte
	subq.w	#8,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5
	addq.w	#8,d6

.NoRead:
	bra.s	EniDec_GetCode				; Process next code

.InlineTileCode:
	subq.w	#2,d6					; Get code
	rol.w	#2,d5
	move.w	d5,d1
	andi.w	#%11,d1
	
	subq.w	#4,d6					; Get copy length
	rol.w	#4,d5
	move.w	d5,d0
	andi.w	#$F,d0
	
	cmpi.w	#8,d6					; Should we get another byte?
	bhi.s	.NoRead2				; If not, branch

	move.w	d6,d7					; Get number of bits read past byte
	subq.w	#8,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5
	addq.w	#8,d6

.NoRead2:
	add.w	d1,d1					; Handle code
	jsr	.InlineCodes(pc,d1.w)
	
	bra.s	EniDec_GetCode				; Process next code

; ----------------------------------------------------------------------

.InlineCodes:
	bra.s	EniDec_InlineMode00
	bra.s	EniDec_InlineMode01
	bra.s	EniDec_InlineMode10
	
; ----------------------------------------------------------------------

EniDec_InlineMode11:
	cmpi.w	#$F,d0					; Are we at the end?
	beq.s	EniDec_Done				; If so, branch

.Copy:
	bsr.s	EniDec_GetInlineTile			; Get tile
	move.w	d1,(a2)+				; Store tile
	dbf	d0,.Copy				; Loop until enough is copied
	rts
	
; ----------------------------------------------------------------------

EniDec_Done:
	addq.w	#4,sp					; Discard return address
	
	subq.w	#1,a1					; Discard trailing byte
	cmpi.w	#16,d6					; Are there 2 trailing bytes?
	bne.s	.End					; If not, branch
	subq.w	#1,a1					; If so, discard the other byte
	
.End:
	movem.l	(sp)+,d0-d7/a3-a6			; Restore registers
	rts

; ----------------------------------------------------------------------

EniDec_InlineMode00:
	bsr.s	EniDec_GetInlineTile			; Get tile

.Copy:
	move.w	d1,(a2)+				; Copy tile
	dbf	d0,.Copy				; Loop until enough is copied
	rts
	
; ----------------------------------------------------------------------

EniDec_InlineMode01:
	bsr.s	EniDec_GetInlineTile			; Get tile

.Copy:
	move.w	d1,(a2)+				; Copy tile
	addq.w	#1,d1					; Increment
	dbf	d0,.Copy				; Loop until enough is copied
	rts
	
; ----------------------------------------------------------------------

EniDec_InlineMode10:
	bsr.s	EniDec_GetInlineTile			; Get tile

.Copy:
	move.w	d1,(a2)+				; Copy tile
	subq.w	#1,d1					; Decrement
	dbf	d0,.Copy				; Loop until enough is copied
	rts

; ----------------------------------------------------------------------

EniDec_GetInlineTile:
	move.w	a4,d7					; Get tile flags
	move.w	a3,d3					; Get base tile properties

	add.b	d7,d7					; Is the priority flag set?
	bcc.s	.CheckPalette0				; If not, branch
	subq.w	#1,d6					; Does this tile have its priority flag set?
	rol.w	#1,d5
	bcc.s	.CheckPalette0				; If not, branch
	ori.w	#1<<15,d3				; Set priority flag in base tile properties

.CheckPalette0:
	add.b	d7,d7					; Is the high palette bit set?
	bcc.s	.CheckPalette1				; If not, branch
	subq.w	#1,d6					; Does this tile have its high palette bit set?
	rol.w	#1,d5
	bcc.s	.CheckPalette1				; If not, branch
	addi.w	#1<<14,d3				; Offset palette in base tile properties

.CheckPalette1:
	add.b	d7,d7					; Is the low palette bit set?
	bcc.s	.CheckYFlip				; If not, branch
	subq.w	#1,d6					; Does this tile have its low palette bit set?
	rol.w	#1,d5
	bcc.s	.CheckYFlip				; If not, branch
	addi.w	#1<<13,d3				; Offset palette in base tile properties

.CheckYFlip:
	add.b	d7,d7					; Is the Y flip flag set?
	bcc.s	.CheckXFlip				; If not, branch
	subq.w	#1,d6					; Does this tile have its Y flip bit set?
	rol.w	#1,d5
	bcc.s	.CheckXFlip				; If not, branch
	ori.w	#1<<12,d3				; Set Y flip flag in base tile properties

.CheckXFlip:
	add.b	d7,d7					; Is the X flip flag set?
	bcc.s	.GotFlags				; If not, branch
	subq.w	#1,d6					; Does this tile have its X flip bit set?
	rol.w	#1,d5
	bcc.s	.GotFlags				; If not, branch
	ori.w	#1<<11,d3				; Set X flip flag in base tile properties

.GotFlags:
	cmpi.w	#8,d6					; Should we get another byte?
	bhi.s	.NoRead					; If not, branch

	move.w	d6,d7					; Get number of bits read past byte
	subq.w	#8,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5
	addq.w	#8,d6

.NoRead:
	moveq	#0,d2					; Reset upper bits
	move.w	d4,d1					; Get number of bits in a tile ID
	cmpi.w	#8,d1					; Is it more than 8 bits?
	bls.s	.GetTileID				; If not, branch
	
	rol.w	#8,d5					; Get first 8 bits of tile ID
	move.b	d5,d2
	
	subq.w	#8,d1					; Get remaining number of bits
	lsl.w	d1,d2
	
	move.w	d6,d7					; Get number of bits read past byte
	subi.w	#16,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5

.GetTileID:
	sub.w	d1,d6					; Get tile ID bits
	rol.w	d1,d5
	
	move.w	d1,d7					; Apply mask and base tile properties
	add.w	d7,d7
	move.w	d5,d1
	and.w	.Masks-2(pc,d7.w),d1
	or.w	d2,d1
	add.w	d3,d1
	
	cmpi.w	#8,d6					; Should we get another byte?
	bhi.s	.NoRead2				; If not, branch

	move.w	d6,d7					; Get number of bits read past byte
	subq.w	#8,d7
	neg.w	d7
	
	ror.w	d7,d5					; Read another byte
	move.b	(a1)+,d5
	rol.w	d7,d5
	addq.w	#8,d6

.NoRead2:
	rts

; ----------------------------------------------------------------------

.Masks:
	dc.w	%0000000000000001
	dc.w	%0000000000000011
	dc.w	%0000000000000111
	dc.w	%0000000000001111
	dc.w	%0000000000011111
	dc.w	%0000000000111111
	dc.w	%0000000001111111
	dc.w	%0000000011111111
	dc.w	%0000000111111111
	dc.w	%0000001111111111
	dc.w	%0000011111111111
	dc.w	%0000111111111111
	dc.w	%0001111111111111
	dc.w	%0011111111111111
	dc.w	%0111111111111111
	dc.w	%1111111111111111
	
; ----------------------------------------------------------------------
; Decompressed Kosinski compressed data
; Format details: https://segaretro.org/Kosinski_compression
; ----------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to source data
;	a1.l - Pointer to destination buffer
; ----------------------------------------------------------------------
; RETURNS:
;	a0.l - Pointer to end of source data
;	a1.l - Pointer to end of destination buffer
; ----------------------------------------------------------------------

KosDec:
	movem.l	d0-d3/a2,-(sp)				; Save registers

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

; ----------------------------------------------------------------------

KosDec_GetCode:
	lsr.w	#1,d1					; Get code
	bcc.s	KosDec_Code0x				; If it's 0, branch

; ----------------------------------------------------------------------

KosDec_Code1:
	dbf	d0,.NoNewDesc				; Decrement bits left to process

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

.NoNewDesc:
	move.b	(a0)+,(a1)+				; Copy uncompressed byte
	bra.s	KosDec_GetCode				; Process next code

; ----------------------------------------------------------------------

KosDec_Code0x:
	dbf	d0,.NoNewDesc				; Decrement bits left to process

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

.NoNewDesc:
	moveq	#$FFFFFFFF,d2				; Copy offsets are always negative
	moveq	#0,d3					; Reset copy counter

	lsr.w	#1,d1					; Get 2nd code bit
	bcs.s	KosDec_Code01				; If the full code is 01, branch

; ----------------------------------------------------------------------

KosDec_Code00:
	dbf	d0,.NoNewDesc				; Decrement bits left to process

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

.NoNewDesc:
	lsr.w	#1,d1					; Get number of bytes to copy (first bit)
	addx.w	d3,d3
	dbf	d0,.NoNewDesc2				; Decrement bits left to process

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

.NoNewDesc2:
	lsr.w	#1,d1					; Get number of bytes to copy (second bit)
	addx.w	d3,d3
	dbf	d0,.NoNewDesc3				; Decrement bits left to process

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

.NoNewDesc3:
	move.b	(a0)+,d2				; Get copy offset

; ----------------------------------------------------------------------

KosDec_Copy:
	lea	(a1,d2.w),a2				; Get copy address
	move.b	(a2)+,(a1)+				; Copy a byte

.Copy:
	move.b	(a2)+,(a1)+				; Copy a byte
	dbf	d3,.Copy				; Loop until bytes are copied

	bra.w	KosDec_GetCode				; Process next code

; ----------------------------------------------------------------------

KosDec_Code01:
	dbf	d0,.NoNewDesc				; Decrement bits left to process

	move.b	(a0)+,-(sp)				; Read from data stream
	move.b	(a0)+,-(sp)
	move.w	(sp)+,d1
	move.b	(sp)+,d1
	moveq	#16-1,d0				; 16 bits to process

.NoNewDesc:
	move.b	(a0)+,-(sp)				; Get copy offset
	move.b	(a0)+,d2
	move.b	d2,d3
	lsl.w	#5,d2
	move.b	(sp)+,d2

	andi.w	#7,d3					; Get 3-bit copy count
	bne.s	KosDec_Copy				; If this is a 3-bit copy count, branch

	move.b	(a0)+,d3				; Get 8-bit copy count
	beq.s	.End					; If it's 0, we are done decompressing
	subq.b	#1,d3					; Is it 1?
	bne.s	KosDec_Copy				; If not, start copying
	
	bra.w	KosDec_GetCode				; Process next code

.End:
	movem.l	(sp)+,d0-d3/a2				; Restore registers
	rts

; ----------------------------------------------------------------------
; Decode 1BPP graphics into VRAM
; ----------------------------------------------------------------------
; PARAMETERS:
;	d0.l - VDP command
;	d1.l - Decode table
;	d2.w - Number of tiles
;	a1.l - Pointer to graphics data
; ----------------------------------------------------------------------

Decode1BPPGraphics:
	add.w	d2,d2					; Get number of pixel row groups
	add.w	d2,d2
	subq.w	#1,d2					; Decrement for DBF
	
	lea	VDP_DATA,a5				; VDP data port
	move.l	d0,4(a5)				; Set VDP command
	move.l	d1,-(sp)				; Save decode table onto the stack
	
.Decode:
	move.w	(a1)+,d1				; Get 2 pixel rows (16 pixels)
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),-(sp)
	move.w	(sp)+,d3
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),d3
	
	move.w	d3,(a5)					; Write decoded pixels
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),-(sp)
	move.w	(sp)+,d3
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),d3
	
	move.w	d3,(a5)					; Write decoded pixels
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),-(sp)
	move.w	(sp)+,d3
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),d3
	
	move.w	d3,(a5)					; Write decoded pixels
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),-(sp)
	move.w	(sp)+,d3
	
	rol.w	#2,d1					; Decode 2 pixels
	move.w	d1,d4
	andi.w	#3,d4
	move.b	(sp,d4.w),d3
	
	move.w	d3,(a5)					; Write decoded pixels
	
	dbf	d2,.Decode				; Loop until finished
	move.l	(sp)+,d1				; Deallocate the decode table
	rts

; ----------------------------------------------------------------------