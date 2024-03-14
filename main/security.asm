; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU security block functions
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
; Security block animation
; ----------------------------------------------------------------------

SecurityAnimation:
	move.l	a1,-(sp)				; Save a1
	bsr.w	SetDefaultVDPRegs			; Set VDP registers
	bsr.w	ClearVDPMemory				; Clear VDP memory
	bsr.w	ClearSprites				; Clear sprites
	bsr.w	LoadFontDefault				; Load font
	move.l	(sp)+,a1				; Restore a1
	
	move.l	VBLANK_INT+2,-(sp)			; Save V-BLANK handler
	move.w	VBLANK_INT,-(sp)
	
	lea	WORK_RAM,a0				; Get security block type
	bsr.w	CheckSecurityBlock
	move.w	d0,-(sp)
	bmi.s	SecurityInvalidDisc			; If it's invalid, branch
	
	move	#$2700,sr				; Set V-BLANK handler
	move.w	#$4EF9,VBLANK_INT
	move.l	#VBlank_Security,VBLANK_INT+2
	
	move.w	(sp),d1					; Check region
	move.l	a1,-(sp)
	bsr.w	SecurityCheckRegion
	move.l	(sp)+,a1

	move.w	(sp),d0					; Run animation based on type
	add.w	d0,d0
	add.w	d0,d0
	jsr	.Animations(pc,d0.w)
	
	addq.w	#2,sp					; Deallocate security block type
	move.w	(sp)+,VBLANK_INT			; Restore V-BLANK handler
	move.l	(sp)+,VBLANK_INT+2
	rts
	
; ----------------------------------------------------------------------

.Animations:
	bra.w	SecurityAnimJapan
	bra.w	SecurityAnimUSAEurope
	bra.w	SecurityAnimUSAEurope
	
; ----------------------------------------------------------------------
; Invalid disc error message
; ----------------------------------------------------------------------

SecurityInvalidDisc:
	lea	.ErrorString(pc),a1			; Draw error string
	move.l	#$458E0003,d0
	bsr.w	DrawText

	move.l	#$EE00000,palette			; Set palette
	bset	#0,cramUpdate
	
	bsr.w	EnableDisplay				; Enable display

.Hang:
	bsr.w	DefaultVSync				; VSync
	bra.s	.Hang					; Loop indefinitely

; ----------------------------------------------------------------------

.ErrorString:
	dc.b	"          ERROR", 0, 0
	dc.b	"THE INSERTED DISC IS NOT A", 0
	dc.b	"   VALID MEGA CD DISC.", -1
	even
	
; ----------------------------------------------------------------------
; Check the region before displaying the animation
; ----------------------------------------------------------------------
; PARAMETERS:
;	d1.b - Security block type
;	       0 = Japan
;	       1 = USA
;	       2 = Europe
; ----------------------------------------------------------------------

SecurityCheckRegion:
	bsr.w	StopZ80					; Get the console's PAL settings
	move.b	VERSION,d0
	andi.b	#$40,d0
	bsr.w	StartZ80

	ext.w	d1					; Does it match the expected setting?
	cmp.b	.Expected(pc,d1.w),d0
	bne.s	.NoMatch				; If not, branch
	rts

; ----------------------------------------------------------------------

.Expected:
	dc.b	$00					; Japan
	dc.b	$00					; USA
	dc.b	$40					; Europe
	even

; ----------------------------------------------------------------------

.NoMatch:
	add.w	d1,d1					; Draw warning text
	add.w	d1,d1
	movea.l	.WarningStrings(pc,d1.w),a1
	move.l	#$45880003,d0
	bsr.w	DrawText

	move.l	#$EE00000,palette			; Set palette
	bset	#0,cramUpdate
	
	bsr.w	EnableDisplay				; Enable display

	move.w	#(60*8)-1,d2				; Wait for several seconds

.Wait:
	bsr.w	DefaultVSync				; VSync
	dbf	d2,.Wait				; Loop until finished

	clr.w	palette					; Black out screen
	bsr.w	BlackOutDisplay
	
	move	#$2700,sr				; Disable interrupts
	bra.w	ClearScreen				; Clear screen

; ----------------------------------------------------------------------

.WarningStrings:
	dc.l	.NTSCOnPAL				; Japan
	dc.l	.NTSCOnPAL				; USA
	dc.l	.PALOnNTSC				; Europe

.NTSCOnPAL:
	dc.b	"            WARNING", 0, 0
	dc.b	" THIS IS AN NTSC DISC RUNNING", 0
	dc.b	"ON A PAL SYSTEM! THINGS MAY NOT", 0
	dc.b	"       WORK AS EXPECTED.", -1
.PALOnNTSC:
	dc.b	"            WARNING", 0, 0
	dc.b	"  THIS IS A PAL DISC RUNNING", 0
	dc.b	" ON AN NTSC SYSTEM. THINGS MAY", 0
	dc.b	"     NOT WORK AS EXPECTED.", -1
	even

; ----------------------------------------------------------------------
; Japanese security block animation
; ----------------------------------------------------------------------

SecurityAnimJapan:
	bsr.w	LoadPalette				; Load palette from security block

	move.l	#$60000000,d0				; Load SEGA graphics from security block
	move.l	#$00022022,d1
	moveq	#$1B,d2
	bsr.w	Decode1BPPGraphics

	move.l	#$42060003,d0				; Draw text from security block
	bsr.w	DrawText

	move.l	#$479E0003,d0				; Draw SEGA tilemap from security block
	moveq	#9-1,d1
	moveq	#3-1,d2
	move.w	#$100,d3
	bsr.w	DrawSequentialTilemap
	
	moveq	#0,d1					; Initialize the sound driver
	bsr.w	InitSecuritySound

	bsr.w	EnableDisplay				; Enable display
	
	moveq	#60-1,d1				; Hold for a second
	bsr.w	Delay
	
	bsr.w	PlaySecurityJingle			; Play the jingle

	moveq	#0,d2					; Reset frame counter
	lea	.PalCycleTimes(pc),a0			; Palette cycle times
	lea	.PalCycleData(pc),a1			; Palette cycle data
	moveq	#0,d3					; Reset next palette cycle frame 

.PalCycle:
	lea	palette,a2				; Update palette
	move.l	(a1)+,(a2)+
	move.w	(a1)+,(a2)+
	bset	#0,cramUpdate
	
	move.w	(a0)+,d1				; Get number of frames to delay
	bmi.s	.End					; If we are at the end, branch
	bsr.w	Delay					; Delay for a number of frames
	bra.s	.PalCycle				; Loop

.End:
	rts
	
; ----------------------------------------------------------------------

.PalCycleTimes:
	dc.w	2-1, 2-1, 2-1, 2-1
	dc.w	2-1, 2-1, 2-1, 2-1
	dc.w	2-1, 5-1, 3-1, 3-1
	dc.w	4-1, 4-1, 4-1, 2-1
	dc.w	2-1, 2-1, 2-1, 2-1
	dc.w	2-1, 2-1, 2-1, 2-1
	dc.w	2-1, 35-1, 84-1
	dc.w	-1

.PalCycleData:
	dc.w	$EEE, $000, $E00
	dc.w	$CCC, $000, $E00
	dc.w	$AAA, $000, $E00
	dc.w	$888, $000, $E00
	dc.w	$666, $000, $E00
	dc.w	$444, $000, $E00
	dc.w	$222, $EEE, $E00
	dc.w	$000, $EEE, $E00
	dc.w	$000, $EEE, $EEA
	dc.w	$000, $EEE, $EE8
	dc.w	$000, $EEE, $EE6
	dc.w	$000, $EEE, $EC0
	dc.w	$000, $EEE, $EA0
	dc.w	$000, $EEE, $E80
	dc.w	$000, $EEE, $E60
	dc.w	$000, $EEE, $E40
	dc.w	$000, $EEE, $E00
	dc.w	$000, $EEE, $E20
	dc.w	$000, $EEE, $E40
	dc.w	$000, $EEE, $E60
	dc.w	$000, $EEE, $E80
	dc.w	$000, $EEE, $EA0
	dc.w	$000, $EEE, $EC0
	dc.w	$000, $EEE, $EE6
	dc.w	$000, $EEE, $EE8
	dc.w	$000, $EEE, $EEA
	dc.w	$000, $EEE, $E60

; ----------------------------------------------------------------------
; USA security block animation
; ----------------------------------------------------------------------

SecurityAnimUSAEurope:
	move.l	a1,-(sp)				; Load sparkle graphics data
	lea	SecuritySparkleData(pc),a1
	bsr.w	LoadPalette
	move.l	#$40200000,VDP_CTRL
	bsr.w	NemDec
	movea.l	(sp)+,a1
	
	bsr.w	LoadPalette				; Load palette from security block

	move.l	#$60000000,VDP_CTRL			; Load SEGA graphics from security block
	bsr.w	NemDec
	adda.w	#$1D0,a1				; Load Sonic graphics from security block
	bsr.w	NemDec
	
	adda.w	#$206,a1				; Load SEGA tilemap from security block
	move.w	#$6100,d0
	lea	decompBuffer,a2
	bsr.w	EniDec
	
	move.w	#$613F,d0				; Load Sonic tilemaps from security block
	bsr.w	EniDec
	
	move.l	#$4B0C0003,d0				; Draw text from security block
	bsr.w	DrawText
	
	moveq	#1,d1					; Initialize the sound driver
	bsr.w	InitSecuritySound
	
	lea	decompBuffer,a1				; Draw SEGA tilemap
	move.l	#$451A0003,d0
	moveq	#$12-1,d1
	moveq	#6-1,d2
	bsr.w	DrawTilemap
	
	bsr.w	DrawSonicFrame1				; Draw Sonic
	bsr.w	EnableDisplay				; Enable display
	
	lea	objects,a0				; Clear object slots
	move.w	#(objLength*OBJECT_SLOTS)/4-1,d0
	moveq	#0,d1
	
.ClearObjects:
	move.l	d1,(a0)+
	dbf	d0,.ClearObjects
	
	move.l	#SecurityObjIndex-4,objIndexTable	; Set object index table
	bsr.w	SpawnSecuritySparkles			; Spawn objects
	
	moveq	#60-1,d1				; Hold for a second
	bsr.w	Delay
	
	moveq	#57-1,d4				; Run for 57 frames
	moveq	#0,d5					; Reset animation counter
	
.AnimateSonic:
	bsr.w	DefaultVSync				; VSync
	lea	DrawSonicFrame1(pc),a0			; Animate and draw Sonic
	addi.b	#$1A,d5
	bmi.s	.DrawSonic
	lea	DrawSonicFrame2(pc),a0
	
.DrawSonic:
	jsr	(a0)
	dbf	d4,.AnimateSonic			; Loop until animation is finished

	bsr.w	PlaySecurityJingle			; Play jingle
	
	lea	objects+(objLength*64),a0		; Update sparkles that go offscreen
	moveq	#16-1,d0
	moveq	#4-1,d5
	bsr.w	SecurityUpdateObjects
	
	lea	objects,a0				; Update all sparkles
	moveq	#OBJECT_SLOTS-1,d0
	move.w	#245-1,d5
	bra.w	SecurityUpdateObjects

; ----------------------------------------------------------------------
; Check if a valid security block is present
; ----------------------------------------------------------------------
; PARAMETERS
;	a0.l - Pointer to security block
; ----------------------------------------------------------------------
; RETURNS:
;	d0.b  - Security block type
;	        -1 = Invalid
;	         0 = Japan
;	         1 = USA
;	         2 = Europe
;	pl/mi - Valid/Invalid
; ----------------------------------------------------------------------

CheckSecurityBlock:
	move.l	a1,-(sp)				; Save a1

	moveq	#0,d0					; Check Japanese security block
	lea	SecurityJapan(pc),a1
	move.w	#(SecurityJapanEnd-SecurityJapan)/2-1,d1
	bsr.s	.Check
	beq.s	.End					; Branch if there was a match
	
	moveq	#1,d0					; Check USA security block
	lea	SecurityUSA(pc),a1
	move.w	#(SecurityUSAEnd-SecurityUSA)/2-1,d1
	bsr.s	.Check
	beq.s	.End					; Branch if there was a match
	
	moveq	#2,d0					; Check European security block
	lea	SecurityEurope(pc),a1
	move.w	#(SecurityEuropeEnd-SecurityEurope)/2-1,d1
	bsr.s	.Check
	beq.s	.End					; Branch if there was a match

	moveq	#-1,d0					; No match

.End:
	movea.l	(sp)+,a1				; Restore a1
	tst.b	d0					; Check security block type
	rts

; ----------------------------------------------------------------------

.Check:
	movea.l	a0,a2					; Get security block to check

.CheckLoop:
	cmpm.w	(a2)+,(a1)+				; Compare data
	dbne	d1,.CheckLoop				; Loop until finished if the data is the same
	rts

; ----------------------------------------------------------------------
; V-BLANK handler
; ----------------------------------------------------------------------

VBlank_Security:
	movem.l	d0-a6,-(sp)				; Save registers

	bsr.w	TriggerSubIRQ2				; Trigger Sub CPU IRQ2
	bsr.w	UpdateCRAM				; Update CRAM
	bsr.w	UpdateSpriteVRAM			; Update sprite data in VRAM

	clr.b	vblankFlags				; Clear V-BLANK handler flags
	movem.l	(sp)+,d0-a6				; Restore registers
	rte

; ----------------------------------------------------------------------
; Initialize the sound driver
; ----------------------------------------------------------------------
; PARAMETERS:
;	d1.w - 0 if Japanese, nonzero if non-Japanese
;	a1.l - Pointer to jingle data (if non-Japanese)
; ----------------------------------------------------------------------

InitSecuritySound:
	move	sr,-(sp)				; Disable interrupts
	move	#$2700,sr
	bsr.w	PrepareZ80Reset				; Prepare for Z80 reset

	lea	Z80_RAM,a0				; Load driver
	lea	SecuritySound(pc),a2
	move.w	#(SecuritySoundEnd-SecuritySound)-1,d0

.LoadDriver:
	move.b	(a2)+,(a0)+
	dbf	d0,.LoadDriver
	
	tst.w	d1					; Are we loading the Japanese sound data?
	bne.s	.USAEurope				; If not, branch

	lea	Z80_RAM+$1100,a0			; Load sound data
	move.w	#(SecurityJapanSoundEnd-SecurityJapanSound)-1,d0

.LoadJapanData:
	move.b	(a2)+,(a0)+
	dbf	d0,.LoadJapanData
	
.Done:
	bsr.w	ResetZ80				; Reset the Z80
	move	(sp)+,sr				; Restore interrupt settings
	rts

; ----------------------------------------------------------------------

.USAEurope:
	lea	Z80_RAM+$1100,a0			; Load sound data from security block
	move.w	#$E0-1,d0

.LoadUSAEuropeData:
	move.b	(a1)+,(a0)+
	dbf	d0,.LoadUSAEuropeData

	lea	Z80_RAM+4,a0				; Apply patches
	move.b	#$C3,(a0)+
	move.b	#$9C,(a0)+
	move.b	#$0F,(a0)+
	lea	Z80_RAM+$38,a0
	move.b	#$C3,(a0)+
	move.b	#$81,(a0)+
	move.b	#$0F,(a0)+

	bra.s	.Done					; Finish off

; ----------------------------------------------------------------------
; Play the jingle
; ----------------------------------------------------------------------

PlaySecurityJingle:
	move	sr,-(sp)				; Disable interrupts
	move	#$2700,sr
	
	bsr.w	StopZ80					; Set sound ID
	move.b	#$81,Z80_RAM+$1C0A
	bsr.w	StartZ80
	
	move	(sp)+,sr				; Restore interrupt settings
	rts

; ----------------------------------------------------------------------
; Draw Sonic frame
; ----------------------------------------------------------------------

DrawSonicFrame1:
	lea	decompBuffer+$D8,a1			; Draw frame 1
	move.l	#$45900003,d0
	moveq	#3-1,d1
	moveq	#5-1,d2
	bra.w	DrawTilemap

; ----------------------------------------------------------------------

DrawSonicFrame2:
	lea	decompBuffer+$F6,a1			; Draw frame 2
	move.l	#$45900003,d0
	moveq	#3-1,d1
	moveq	#5-1,d2
	bra.w	DrawTilemap

; ----------------------------------------------------------------------
; Update objects
; ----------------------------------------------------------------------
; PARAMETERS:
;	d5.w - Number of frames to run (minus 1)
;	a0.l - Pointer to object slots
;	d0.w - Number of object slots
; ----------------------------------------------------------------------

SecurityUpdateObjects:
	movem.l	d0/a0,-(sp)				; Save registers
	
.UpdateObjects:
	bsr.w	DefaultVSync				; VSync
	
	move.l	(sp),d0					; Update objects
	movea.l	4(sp),a0
	lea	sprites,a1
	moveq	#objLength,d1
	bsr.w	UpdateObjects
	
	dbf	d5,.UpdateObjects			; Loop until finished
	movem.l	(sp)+,d0/a0				; Restore registers
	rts

; ----------------------------------------------------------------------
; Object index
; ----------------------------------------------------------------------

SecurityObjIndex:
	dc.l	ObjSecuritySparkle			; Sparkle

; ----------------------------------------------------------------------
; Spawn sparkles
; ----------------------------------------------------------------------

SpawnSecuritySparkles:
	lea	objects,a0				; Object slots
	moveq	#(.SpawnDataEnd-.SpawnData)/6-1,d1	; Number of objects
	lea	.SpawnData(pc),a1			; Spawn data
	
.Spawn:
	move.w	#4,(a0)					; Set object ID
	move.w	#83+128,objX(a0)			; Set X position
	move.w	#107+128,objY(a0)			; Set Y position
	cmpi.b	#16-1,d1				; Does this sparkle go offscreen?
	bls.s	.SetData				; If so, branch
	move.w	#100+128,objY(a0)			; Set other Y position

.SetData:
	moveq	#0,d0					; Set Y speed
	move.w	(a1)+,d0
	add.l	d0,d0
	add.l	d0,d0
	neg.l	d0
	move.l	d0,objYSpeed(a0)
	
	move.w	(a1)+,objMoveTime(a0)			; Set movement timer
	
	moveq	#0,d0					; Set X speed
	move.w	(a1)+,d0
	add.l	d0,d0
	subi.l	#$E00,d0
	move.l	d0,objXSpeed(a0)
	
	move.w	d1,d0					; Set animation timer
	andi.w	#$3C,d0
	asr.w	#2,d0
	move.b	d0,objAnimTime(a0)
	
	move.w	d1,d0					; Set animation frame
	andi.w	#3,d0
	move.b	d0,objAnimFrame(a0)
	
	clr.b	objSprTile(a0)				; Reset palette line
	move.b	d1,objPalCycle(a0)			; Set palette cycle offset
	
	lea	objLength(a0),a0			; Next object
	dbf	d1,.Spawn				; Loop until finished
	rts

; ----------------------------------------------------------------------

.SpawnData:
	dc.w	$8000, $90, $B8E
	dc.w	$7800, $8A, $137A
	dc.w	$9000, $A0, $1733
	dc.w	$8400, $94, $2000
	dc.w	$7400, $87, $2AAA
	dc.w	$8000, $90, $2F1C
	dc.w	$7000, $85, $3AB4
	dc.w	$8C00, $9C, $389D
	dc.w	$6C00, $81, $4C67
	dc.w	$8400, $94, $4983
	dc.w	$7400, $88, $5787
	dc.w	$7C00, $8D, $5BB0
	dc.w	$8C00, $9C, $596F
	dc.w	$7000, $84, $7174
	dc.w	$7C00, $8D, $7179
	dc.w	$8000, $91, $7568
	dc.w	$8800, $98, $76BC
	dc.w	$7800, $8A, $8A33
	dc.w	$8400, $93, $88B5
	dc.w	$9000, $A0, $8400
	dc.w	$8000, $90, $99C7
	dc.w	$8400, $84, $7A2E
	dc.w	$7000, $69, $1999
	dc.w	$8000, $75, $1FB9
	dc.w	$8400, $7B, $2681
	dc.w	$7800, $6C, $3555
	dc.w	$7800, $6E, $3DAC
	dc.w	$7C00, $72, $447D
	dc.w	$7400, $6A, $5352
	dc.w	$8C00, $82, $4BD0
	dc.w	$7000, $66, $6AAA
	dc.w	$9000, $85, $5980
	dc.w	$8000, $76, $6D8F
	dc.w	$8800, $7E, $6EBA
	dc.w	$9400, $8A, $6C85
	dc.w	$8400, $7A, $853E
	dc.w	$7000, $66, $A6E6
	dc.w	$8C00, $82, $8AD4
	dc.w	$8000, $76, $A1A0
	dc.w	$7000, $66, $C505
	dc.w	$9000, $86, $9D9C
	dc.w	$8400, $84, $9E0F
	dc.w	$7800, $88, $C3C
	dc.w	$7400, $83, $109C
	dc.w	$9000, $99, $D62
	dc.w	$7C00, $83, $1290
	dc.w	$7000, $76, $F2F
	dc.w	$8800, $88, $12D2
	dc.w	$8C00, $89, $E03
	dc.w	$8400, $86, $131A
	dc.w	$9400, $8E, $1039
	dc.w	$8400, $7E, $9B6D
	dc.w	$8C00, $8B, $9442
	dc.w	$9000, $92, $8D26
	dc.w	$9400, $97, $8A2C
	dc.w	$7C00, $83, $A521
	dc.w	$7400, $80, $A600
	dc.w	$7800, $86, $A540
	dc.w	$6C00, $7F, $AC58
	dc.w	$7000, $80, $B100
	dc.w	$9400, $88, $35A5
	dc.w	$9000, $84, $564D
	dc.w	$7800, $72, $90D7
	dc.w	$8800, $7E, $ABAE
	dc.w	$8800, $BE, $17E4
	dc.w	$9400, $BE, $1C71
	dc.w	$7800, $BE, $2969
	dc.w	$7000, $BE, $9999
	dc.w	$8400, $BE, $349A
	dc.w	$6C00, $BE, $4489
	dc.w	$8000, $BE, $4481
	dc.w	$7400, $BE, $50D7
	dc.w	$9000, $BE, $84DC
	dc.w	$7C00, $BE, $5C16
	dc.w	$8C00, $BE, $59C4
	dc.w	$7400, $BE, $6FA3
	dc.w	$7C00, $BE, $722F
	dc.w	$8C00, $BE, $959C
	dc.w	$8400, $BE, $7ABD
	dc.w	$8000, $BE, $8568
.SpawnDataEnd:

; ----------------------------------------------------------------------
; Sparkle object
; ----------------------------------------------------------------------

ObjSecuritySparkle:
	tst.w	objMoveTime(a0)				; Are we moving?
	beq.s	.PalCycle				; If not, branch
	
	addi.l	#$800,objYSpeed(a0)			; Apply gravity
	subq.w	#1,objMoveTime(a0)			; Decrement movement timer
	bne.s	.PalCycle				; If it hasn't run out, branch
	
	clr.l	objXSpeed(a0)				; If so, stop moving
	clr.l	objYSpeed(a0)
	
.PalCycle:
	addq.b	#8,objPalCycle(a0)			; Increment palette cycle offset
	move.b	objPalCycle(a0),d0			; Get palette line
	andi.b	#$60,d0
	cmpi.b	#$60,d0					; Is it set to line 3?
	bne.s	.SetPalLine				; If not, branch
	moveq	#0,d0					; If so, go back to line 0
	
.SetPalLine:
	move.b	d0,objSprTile(a0)			; Set palette line
	
	lea	.Animation(pc),a1			; Animation data
	subq.b	#1,objAnimTime(a0)			; Decrement animation timer
	bpl.s	.CheckFrame				; If it hasn't run out, branch
	move.b	1(a1),objAnimTime(a0)			; Reset animation timer
	addq.b	#1,objAnimFrame(a0)			; Next frame
	
.CheckFrame:
	moveq	#0,d0					; Get frame
	move.b	objAnimFrame(a0),d0
	cmp.b	(a1),d0					; Are we at the end of the animation?
	bcs.s	.SetFrame				; If not, branch
	moveq	#0,d0					; Reset animation
	move.b	d0,objAnimFrame(a0)
	
.SetFrame:
	add.w	d0,d0					; Set frame
	add.w	d0,d0
	move.l	2(a1,d0.w),objSprite(a0)
	rts

; ----------------------------------------------------------------------

.Animation:
	dc.b	(.FramesEnd-.Frames)/4
	dc.b	8
.Frames:
	dc.l	.Frame0
	dc.l	.Frame1
	dc.l	.Frame2
	dc.l	.Frame3
.FramesEnd:

.Frame0:
	dc.b	0, 0
	dc.b	$F8, 0, 0, 1, 0, $FC

.Frame1:
	dc.b	0, 0
	dc.b	$F8, 0, 0, 2, 0, $FC

.Frame2:
	dc.b	0, 0
	dc.b	$F8, 0, 0, 3, 0, $FC

.Frame3:
	dc.b	0, 0
	dc.b	$F8, 0, 0, 4, 0, $FC

; ----------------------------------------------------------------------
; Sparkle data
; ----------------------------------------------------------------------

SecuritySparkleData:
	dc.b	0, (.PaletteEnd-.Palette)/2-1
.Palette:
	dc.w	$000, $EE8, $000, $EE4, $EE0, $EC0, $000, $000
	dc.w	$000, $000, $000, $000, $000, $000, $000, $000
	dc.w	$000, $EC0, $000, $EE0, $EC0, $EA0, $000, $000
	dc.w	$000, $000, $000, $000, $000, $000, $000, $000
	dc.w	$000, $E80, $000, $EC0, $EA0, $E80, $000, $000
	dc.w	$000, $000, $000, $000, $000, $000, $000, $000
.PaletteEnd:

.Graphics:
	dc.b	$00, $04, $80, $54, $0E, $71, $00, $83, $02, $02, $84, $03
	dc.b	$06, $FF, $1F, $A0, $FC, $08, $1D, $BF, $01, $BA, $ED, $F8
	dc.b	$0C, $0F, $F0, $5D, $6B, $A0, $3F, $81, $F8, $50, $FE, $00
	even
	
; ----------------------------------------------------------------------
; Japan security block
; ----------------------------------------------------------------------

SecurityJapan:
	dc.b	$21, $FC, $00, $00, $02, $80, $FD, $02, $4B, $F9, $00, $A1
	dc.b	$20, $01, $08, $D5, $00, $01, $67, $FA, $33, $FA, $01, $3E
	dc.b	$00, $02, $05, $28, $08, $95, $00, $01, $66, $FA, $43, $FA
	dc.b	$00, $0A, $4E, $B8, $03, $64, $60, $00, $01, $2A, $00, $02
	dc.b	$0E, $EE, $00, $00, $0E, $00, $00, $1F, $3F, $7F, $F8, $F7
	dc.b	$EF, $EF, $00, $FE, $FE, $FE, $00, $FE, $FE, $FE, $00, $1F
	dc.b	$3F, $7F, $FC, $FB, $F7, $F7, $00, $FF, $FF, $FF, $00, $FF
	dc.b	$FF, $FF, $00, $0F, $1F, $3F, $7C, $7B, $77, $77, $00, $FF
	dc.b	$FF, $FF, $00, $FF, $FF, $FF, $00, $80, $80, $80, $01, $81
	dc.b	$83, $83, $00, $7C, $FE, $FE, $FF, $EF, $D7, $D7, $00, $00
	dc.b	$00, $00, $00, $00, $80, $80, $EE, $EF, $F7, $F8, $7F, $3F
	dc.b	$1F, $00, $00, $F8, $FC, $3E, $DE, $EE, $EE, $6E, $F6, $F7
	dc.b	$F7, $F0, $F7, $F7, $F7, $F6, $00, $FE, $FE, $00, $FE, $FE
	dc.b	$FE, $00, $77, $77, $77, $77, $77, $77, $77, $77, $00, $7F
	dc.b	$7F, $03, $7B, $7B, $7B, $3B, $03, $87, $87, $8F, $8F, $8F
	dc.b	$9F, $9E, $D7, $BB, $BB, $BB, $7D, $7D, $6D, $EE, $80, $C0
	dc.b	$C0, $E0, $E0, $E0, $F0, $F0, $FF, $FF, $FF, $00, $FF, $FF
	dc.b	$FF, $00, $EE, $EE, $DE, $3E, $FC, $F8, $F0, $00, $F7, $F7
	dc.b	$FB, $FC, $7F, $3F, $1F, $00, $FF, $FF, $FF, $00, $FF, $FF
	dc.b	$FF, $00, $77, $77, $7B, $7C, $3F, $1F, $0F, $00, $FB, $FB
	dc.b	$FB, $03, $FF, $FF, $FF, $00, $9E, $BE, $BD, $FD, $FB, $FB
	dc.b	$FB, $00, $CE, $FE, $FF, $80, $BF, $3F, $3F, $00, $F8, $F8
	dc.b	$7C, $7C, $FE, $FE, $FE, $00, $50, $52, $4F, $44, $55, $43
	dc.b	$45, $44, $20, $42, $59, $20, $4F, $52, $20, $55, $4E, $44
	dc.b	$45, $52, $20, $4C, $49, $43, $45, $4E, $43, $45, $20, $46
	dc.b	$52, $4F, $4D, $00, $00, $4B, $41, $42, $55, $53, $48, $49
	dc.b	$4B, $49, $20, $4B, $41, $49, $53, $48, $41, $20, $53, $45
	dc.b	$47, $41, $20, $45, $4E, $54, $45, $52, $50, $52, $49, $53
	dc.b	$45, $53, $2E, $FF, $60, $06
SecurityJapanEnd:

; ----------------------------------------------------------------------
; USA security block
; ----------------------------------------------------------------------

SecurityUSA:
	dc.b	$43, $FA, $00, $0A, $4E, $B8, $03, $64, $60, $00, $05, $7A
	dc.b	$60, $0F, $00, $00, $00, $00, $0C, $22, $0E, $44, $0E, $66
	dc.b	$0E, $88, $0E, $EE, $0A, $AA, $08, $88, $04, $44, $08, $AE
	dc.b	$04, $6A, $00, $0E, $00, $08, $00, $04, $0E, $20, $80, $3F
	dc.b	$80, $05, $18, $15, $1B, $26, $39, $36, $38, $45, $17, $54
	dc.b	$08, $64, $09, $72, $00, $83, $05, $16, $86, $03, $03, $16
	dc.b	$3A, $89, $03, $02, $15, $19, $26, $3B, $48, $F8, $58, $FA
	dc.b	$67, $7B, $75, $1A, $8A, $04, $0A, $8F, $07, $78, $17, $79
	dc.b	$37, $7A, $FF, $00, $23, $AE, $3A, $CF, $2F, $37, $7E, $80
	dc.b	$3F, $ED, $A3, $FF, $E0, $0E, $FD, $71, $D6, $79, $79, $DB
	dc.b	$DB, $F4, $00, $C2, $58, $00, $5F, $AB, $BB, $2B, $BF, $C2
	dc.b	$F8, $00, $C7, $F5, $B0, $FE, $9A, $85, $FF, $F0, $3F, $8D
	dc.b	$BF, $D3, $63, $A0, $BB, $E1, $81, $C3, $E5, $ED, $DF, $AB
	dc.b	$BD, $BB, $BC, $78, $5F, $AF, $C3, $45, $DA, $00, $BE, $61
	dc.b	$01, $BD, $7D, $61, $42, $00, $9D, $68, $17, $85, $0D, $10
	dc.b	$80, $2E, $B1, $FD, $F6, $00, $03, $E5, $FE, $17, $CF, $2E
	dc.b	$D5, $15, $77, $69, $AB, $BB, $4D, $5D, $DA, $15, $00, $18
	dc.b	$CD, $D6, $D5, $F3, $CF, $9C, $79, $7E, $11, $B7, $C3, $00
	dc.b	$38, $64, $B0, $03, $97, $FD, $F6, $00, $02, $84, $11, $98
	dc.b	$C8, $00, $69, $1D, $88, $46, $43, $5F, $00, $1D, $84, $66
	dc.b	$50, $0B, $F9, $EF, $C1, $2C, $21, $DA, $6A, $EE, $DB, $F4
	dc.b	$A8, $C5, $A6, $80, $8A, $9B, $62, $96, $D5, $2C, $59, $6D
	dc.b	$58, $C5, $45, $59, $70, $AC, $0A, $17, $FF, $C6, $13, $67
	dc.b	$14, $59, $DF, $C7, $E1, $58, $00, $17, $7F, $EF, $01, $A2
	dc.b	$5A, $96, $B8, $7E, $55, $D4, $6B, $7F, $40, $01, $F5, $BD
	dc.b	$42, $10, $4A, $25, $02, $09, $44, $EB, $40, $17, $EC, $F8
	dc.b	$E7, $E0, $00, $58, $44, $A9, $40, $10, $8C, $66, $10, $04
	dc.b	$A7, $FA, $F4, $43, $B4, $D1, $77, $69, $A3, $95, $E5, $72
	dc.b	$A2, $A6, $C8, $BD, $4D, $91, $7A, $9A, $40, $05, $FF, $35
	dc.b	$1F, $93, $BA, $EB, $F5, $E6, $EC, $E2, $82, $CE, $28, $E3
	dc.b	$D6, $3A, $F1, $FB, $6E, $56, $3D, $80, $0A, $75, $A0, $00
	dc.b	$CC, $64, $02, $EA, $16, $15, $F2, $00, $22, $54, $20, $02
	dc.b	$50, $B8, $D7, $3A, $00, $21, $0A, $32, $02, $14, $66, $3B
	dc.b	$BF, $60, $04, $20, $00, $21, $35, $53, $57, $76, $9A, $22
	dc.b	$D3, $44, $2E, $51, $15, $36, $45, $EA, $6C, $88, $B6, $6B
	dc.b	$8B, $6E, $DC, $7E, $E4, $00, $8A, $5E, $78, $A2, $CE, $28
	dc.b	$2C, $E2, $8C, $7B, $DF, $B0, $03, $1E, $CD, $00, $1A, $8D
	dc.b	$00, $1B, $D6, $89, $44, $27, $74, $F8, $CB, $DF, $7D, $71
	dc.b	$9F, $E7, $80, $D4, $B5, $2F, $31, $D7, $6F, $D7, $66, $11
	dc.b	$2D, $4B, $52, $F3, $1D, $67, $0F, $D7, $EE, $40, $08, $D6
	dc.b	$80, $03, $4A, $D8, $F8, $C5, $97, $08, $AB, $D6, $2C, $B8
	dc.b	$B1, $0B, $9F, $DC, $F3, $EE, $D3, $40, $06, $B1, $FE, $60
	dc.b	$B3, $8A, $2C, $E2, $A3, $30, $80, $14, $80, $03, $01, $14
	dc.b	$04, $25, $0E, $35, $18, $45, $13, $56, $39, $67, $79, $75
	dc.b	$14, $81, $03, $00, $16, $2F, $27, $78, $82, $04, $05, $16
	dc.b	$36, $83, $05, $0C, $16, $37, $28, $F9, $84, $05, $15, $17
	dc.b	$7B, $85, $05, $16, $86, $05, $0D, $16, $3A, $87, $05, $0F
	dc.b	$17, $76, $88, $05, $10, $18, $FA, $89, $06, $2E, $8A, $06
	dc.b	$32, $18, $F8, $8B, $05, $11, $17, $7A, $8C, $06, $38, $8D
	dc.b	$05, $1A, $8E, $06, $33, $17, $77, $8F, $05, $12, $FF, $A5
	dc.b	$28, $9B, $26, $F8, $5A, $F6, $70, $6A, $07, $3C, $DE, $E0
	dc.b	$6F, $21, $19, $5B, $56, $D5, $77, $FC, $FF, $EE, $EF, $CF
	dc.b	$A0, $49, $7F, $04, $C8, $60, $10, $EF, $07, $BD, $FF, $D4
	dc.b	$F5, $4F, $99, $F8, $DF, $9B, $D9, $3D, $98, $ED, $A6, $37
	dc.b	$9E, $E6, $D5, $B5, $6C, $58, $59, $FB, $14, $6A, $3C, $8C
	dc.b	$55, $18, $43, $10, $79, $DD, $CC, $E5, $7B, $9B, $B4, $6B
	dc.b	$6C, $F5, $6E, $21, $61, $F2, $1E, $8C, $73, $1B, $8E, $D4
	dc.b	$A3, $84, $DB, $8E, $CC, $20, $FE, $D5, $AC, $D8, $F8, $3B
	dc.b	$CE, $F4, $13, $0A, $9B, $65, $5D, $93, $6C, $F9, $A9, $CD
	dc.b	$D6, $AF, $78, $22, $BF, $5F, $99, $1F, $09, $1C, $BD, $4D
	dc.b	$A3, $9D, $35, $F7, $E3, $F3, $BD, $3B, $D6, $9A, $F4, $89
	dc.b	$E8, $38, $1D, $3B, $AE, $06, $47, $EB, $F5, $95, $9F, $BB
	dc.b	$0B, $8B, $07, $E5, $7F, $33, $F3, $D4, $12, $2C, $B7, $68
	dc.b	$78, $83, $50, $41, $ED, $F3, $98, $8E, $B8, $5D, $28, $8E
	dc.b	$5E, $26, $0E, $72, $05, $4E, $64, $67, $67, $4B, $BD, $B0
	dc.b	$25, $97, $EC, $8E, $AC, $B3, $BF, $98, $AF, $C7, $AF, $84
	dc.b	$CB, $86, $10, $8F, $39, $85, $20, $88, $77, $0A, $D2, $DC
	dc.b	$DD, $74, $91, $A2, $50, $2A, $E7, $C0, $C2, $EC, $69, $F9
	dc.b	$C7, $F5, $51, $BA, $D1, $BB, $0F, $32, $89, $BE, $00, $B0
	dc.b	$BE, $17, $03, $B9, $90, $46, $04, $E9, $77, $3B, $04, $63
	dc.b	$95, $2E, $31, $73, $DB, $15, $B9, $CA, $8B, $3F, $D1, $52
	dc.b	$94, $A5, $3C, $FE, $75, $ED, $5C, $0C, $86, $5C, $C9, $AE
	dc.b	$D0, $B3, $66, $C6, $B2, $09, $F9, $DD, $86, $49, $7F, $3F
	dc.b	$DC, $5F, $77, $63, $2B, $CC, $1A, $92, $D7, $03, $BB, $D3
	dc.b	$F3, $F9, $89, $5D, $A1, $97, $AF, $86, $11, $1F, $E8, $C4
	dc.b	$65, $81, $C3, $DB, $FB, $CD, $52, $94, $A6, $A9, $4F, $3A
	dc.b	$F3, $5F, $D2, $FB, $DC, $7C, $87, $A3, $1C, $C6, $E3, $B5
	dc.b	$1C, $29, $36, $E3, $B3, $08, $3F, $B5, $6B, $36, $3E, $0E
	dc.b	$F3, $BD, $04, $C2, $D6, $DF, $D2, $4D, $A7, $24, $5A, $63
	dc.b	$3A, $FD, $45, $5B, $FA, $CA, $A6, $49, $EE, $C2, $E9, $5F
	dc.b	$F9, $5F, $CC, $B2, $43, $A8, $24, $6E, $1D, $A1, $79, $C9
	dc.b	$A8, $20, $F0, $5F, $36, $9E, $17, $88, $5C, $D9, $47, $24
	dc.b	$AC, $C4, $B0, $A7, $B8, $9E, $61, $EB, $8C, $E4, $9F, $A2
	dc.b	$22, $3C, $D7, $CF, $D6, $51, $AA, $E9, $70, $F3, $25, $37
	dc.b	$C0, $16, $17, $C2, $E0, $77, $32, $08, $C0, $9D, $2E, $E7
	dc.b	$60, $8C, $72, $A5, $C6, $2E, $00, $00, $06, $03, $00, $00
	dc.b	$00, $01, $05, $10, $12, $C2, $04, $88, $50, $11, $04, $80
	dc.b	$14, $05, $10, $9A, $21, $54, $42, $60, $05, $05, $01, $34
	dc.b	$38, $11, $40, $51, $11, $81, $14, $04, $01, $10, $20, $C5
	dc.b	$05, $01, $5C, $58, $02, $20, $40, $1F, $02, $00, $88, $10
	dc.b	$07, $C3, $80, $C8, $04, $01, $A1, $38, $B4, $94, $01, $00
	dc.b	$AC, $58, $0E, $20, $40, $1A, $13, $93, $B1, $A9, $A8, $1C
	dc.b	$5D, $8D, $42, $E2, $68, $6C, $0F, $F0, $05, $00, $00, $00
	dc.b	$00, $00, $39, $0A, $41, $06, $01, $81, $80, $90, $29, $AF
	dc.b	$F8, $50, $52, $4F, $44, $55, $43, $45, $44, $20, $42, $59
	dc.b	$20, $4F, $52, $20, $55, $4E, $44, $45, $52, $20, $4C, $49
	dc.b	$43, $45, $4E, $53, $45, $00, $00, $20, $46, $52, $4F, $4D
	dc.b	$20, $53, $45, $47, $41, $20, $45, $4E, $54, $45, $52, $50
	dc.b	$52, $49, $53, $45, $53, $2C, $20, $4C, $54, $44, $2E, $FF
	dc.b	$14, $11, $08, $0D, $17, $11, $00, $0D, $14, $11, $14, $11
	dc.b	$90, $00, $00, $00, $00, $1C, $14, $11, $80, $80, $80, $1D
	dc.b	$11, $00, $00, $00, $00, $AE, $11, $07, $00, $01, $00, $AD
	dc.b	$11, $00, $00, $3F, $11, $00, $0B, $48, $11, $00, $0B, $66
	dc.b	$11, $00, $0B, $84, $11, $00, $0B, $93, $11, $00, $0B, $A2
	dc.b	$11, $00, $0B, $EF, $01, $E0, $80, $80, $0A, $C9, $0C, $F2
	dc.b	$80, $05, $80, $39, $80, $05, $80, $0C, $EF, $00, $F0, $0A
	dc.b	$01, $02, $08, $A9, $1F, $80, $01, $A5, $40, $E7, $A5, $02
	dc.b	$F7, $00, $08, $5D, $11, $F2, $80, $05, $80, $39, $80, $05
	dc.b	$80, $0C, $EF, $00, $F0, $0A, $01, $02, $08, $B8, $1F, $80
	dc.b	$01, $B5, $40, $E7, $B5, $02, $F7, $00, $08, $7B, $11, $F2
	dc.b	$EF, $01, $E0, $80, $80, $05, $C4, $0C, $E0, $40, $80, $05
	dc.b	$C4, $39, $F2, $EF, $01, $E0, $80, $80, $0A, $80, $07, $E0
	dc.b	$40, $80, $0A, $C9, $34, $F2, $EF, $01, $E0, $80, $C1, $12
	dc.b	$E0, $40, $C1, $3F, $F2, $F2, $32, $01, $01, $01, $01, $3F
	dc.b	$1F, $1F, $1F, $19, $06, $04, $07, $08, $05, $05, $04, $19
	dc.b	$19, $19, $19, $11, $89, $18, $87, $04, $37, $72, $77, $49
	dc.b	$1F, $1F, $1F, $1F, $07, $0A, $07, $0D, $00, $0B, $00, $0B
	dc.b	$1F, $0F, $1F, $0F, $23, $80, $23, $80
SecurityUSAEnd:

; ----------------------------------------------------------------------
; European security block
; ----------------------------------------------------------------------

SecurityEurope:
	dc.b	$43, $FA, $00, $0A, $4E, $B8, $03, $64, $60, $00, $05, $64
	dc.b	$60, $0F, $00, $00, $00, $00, $0C, $22, $0E, $44, $0E, $66
	dc.b	$0E, $88, $0E, $EE, $0A, $AA, $08, $88, $04, $44, $08, $AE
	dc.b	$04, $6A, $00, $0E, $00, $08, $00, $04, $0E, $20, $80, $3F
	dc.b	$80, $05, $18, $15, $1B, $26, $39, $36, $38, $45, $17, $54
	dc.b	$08, $64, $09, $72, $00, $83, $05, $16, $86, $03, $03, $16
	dc.b	$3A, $89, $03, $02, $15, $19, $26, $3B, $48, $F8, $58, $FA
	dc.b	$67, $7B, $75, $1A, $8A, $04, $0A, $8F, $07, $78, $17, $79
	dc.b	$37, $7A, $FF, $00, $23, $AE, $3A, $CF, $2F, $37, $7E, $80
	dc.b	$3F, $ED, $A3, $FF, $E0, $0E, $FD, $71, $D6, $79, $79, $DB
	dc.b	$DB, $F4, $00, $C2, $58, $00, $5F, $AB, $BB, $2B, $BF, $C2
	dc.b	$F8, $00, $C7, $F5, $B0, $FE, $9A, $85, $FF, $F0, $3F, $8D
	dc.b	$BF, $D3, $63, $A0, $BB, $E1, $81, $C3, $E5, $ED, $DF, $AB
	dc.b	$BD, $BB, $BC, $78, $5F, $AF, $C3, $45, $DA, $00, $BE, $61
	dc.b	$01, $BD, $7D, $61, $42, $00, $9D, $68, $17, $85, $0D, $10
	dc.b	$80, $2E, $B1, $FD, $F6, $00, $03, $E5, $FE, $17, $CF, $2E
	dc.b	$D5, $15, $77, $69, $AB, $BB, $4D, $5D, $DA, $15, $00, $18
	dc.b	$CD, $D6, $D5, $F3, $CF, $9C, $79, $7E, $11, $B7, $C3, $00
	dc.b	$38, $64, $B0, $03, $97, $FD, $F6, $00, $02, $84, $11, $98
	dc.b	$C8, $00, $69, $1D, $88, $46, $43, $5F, $00, $1D, $84, $66
	dc.b	$50, $0B, $F9, $EF, $C1, $2C, $21, $DA, $6A, $EE, $DB, $F4
	dc.b	$A8, $C5, $A6, $80, $8A, $9B, $62, $96, $D5, $2C, $59, $6D
	dc.b	$58, $C5, $45, $59, $70, $AC, $0A, $17, $FF, $C6, $13, $67
	dc.b	$14, $59, $DF, $C7, $E1, $58, $00, $17, $7F, $EF, $01, $A2
	dc.b	$5A, $96, $B8, $7E, $55, $D4, $6B, $7F, $40, $01, $F5, $BD
	dc.b	$42, $10, $4A, $25, $02, $09, $44, $EB, $40, $17, $EC, $F8
	dc.b	$E7, $E0, $00, $58, $44, $A9, $40, $10, $8C, $66, $10, $04
	dc.b	$A7, $FA, $F4, $43, $B4, $D1, $77, $69, $A3, $95, $E5, $72
	dc.b	$A2, $A6, $C8, $BD, $4D, $91, $7A, $9A, $40, $05, $FF, $35
	dc.b	$1F, $93, $BA, $EB, $F5, $E6, $EC, $E2, $82, $CE, $28, $E3
	dc.b	$D6, $3A, $F1, $FB, $6E, $56, $3D, $80, $0A, $75, $A0, $00
	dc.b	$CC, $64, $02, $EA, $16, $15, $F2, $00, $22, $54, $20, $02
	dc.b	$50, $B8, $D7, $3A, $00, $21, $0A, $32, $02, $14, $66, $3B
	dc.b	$BF, $60, $04, $20, $00, $21, $35, $53, $57, $76, $9A, $22
	dc.b	$D3, $44, $2E, $51, $15, $36, $45, $EA, $6C, $88, $B6, $6B
	dc.b	$8B, $6E, $DC, $7E, $E4, $00, $8A, $5E, $78, $A2, $CE, $28
	dc.b	$2C, $E2, $8C, $7B, $DF, $B0, $03, $1E, $CD, $00, $1A, $8D
	dc.b	$00, $1B, $D6, $89, $44, $27, $74, $F8, $CB, $DF, $7D, $71
	dc.b	$9F, $E7, $80, $D4, $B5, $2F, $31, $D7, $6F, $D7, $66, $11
	dc.b	$2D, $4B, $52, $F3, $1D, $67, $0F, $D7, $EE, $40, $08, $D6
	dc.b	$80, $03, $4A, $D8, $F8, $C5, $97, $08, $AB, $D6, $2C, $B8
	dc.b	$B1, $0B, $9F, $DC, $F3, $EE, $D3, $40, $06, $B1, $FE, $60
	dc.b	$B3, $8A, $2C, $E2, $A3, $30, $80, $14, $80, $03, $01, $14
	dc.b	$04, $25, $0E, $35, $18, $45, $13, $56, $39, $67, $79, $75
	dc.b	$14, $81, $03, $00, $16, $2F, $27, $78, $82, $04, $05, $16
	dc.b	$36, $83, $05, $0C, $16, $37, $28, $F9, $84, $05, $15, $17
	dc.b	$7B, $85, $05, $16, $86, $05, $0D, $16, $3A, $87, $05, $0F
	dc.b	$17, $76, $88, $05, $10, $18, $FA, $89, $06, $2E, $8A, $06
	dc.b	$32, $18, $F8, $8B, $05, $11, $17, $7A, $8C, $06, $38, $8D
	dc.b	$05, $1A, $8E, $06, $33, $17, $77, $8F, $05, $12, $FF, $A5
	dc.b	$28, $9B, $26, $F8, $5A, $F6, $70, $6A, $07, $3C, $DE, $E0
	dc.b	$6F, $21, $19, $5B, $56, $D5, $77, $FC, $FF, $EE, $EF, $CF
	dc.b	$A0, $49, $7F, $04, $C8, $60, $10, $EF, $07, $BD, $FF, $D4
	dc.b	$F5, $4F, $99, $F8, $DF, $9B, $D9, $3D, $98, $ED, $A6, $37
	dc.b	$9E, $E6, $D5, $B5, $6C, $58, $59, $FB, $14, $6A, $3C, $8C
	dc.b	$55, $18, $43, $10, $79, $DD, $CC, $E5, $7B, $9B, $B4, $6B
	dc.b	$6C, $F5, $6E, $21, $61, $F2, $1E, $8C, $73, $1B, $8E, $D4
	dc.b	$A3, $84, $DB, $8E, $CC, $20, $FE, $D5, $AC, $D8, $F8, $3B
	dc.b	$CE, $F4, $13, $0A, $9B, $65, $5D, $93, $6C, $F9, $A9, $CD
	dc.b	$D6, $AF, $78, $22, $BF, $5F, $99, $1F, $09, $1C, $BD, $4D
	dc.b	$A3, $9D, $35, $F7, $E3, $F3, $BD, $3B, $D6, $9A, $F4, $89
	dc.b	$E8, $38, $1D, $3B, $AE, $06, $47, $EB, $F5, $95, $9F, $BB
	dc.b	$0B, $8B, $07, $E5, $7F, $33, $F3, $D4, $12, $2C, $B7, $68
	dc.b	$78, $83, $50, $41, $ED, $F3, $98, $8E, $B8, $5D, $28, $8E
	dc.b	$5E, $26, $0E, $72, $05, $4E, $64, $67, $67, $4B, $BD, $B0
	dc.b	$25, $97, $EC, $8E, $AC, $B3, $BF, $98, $AF, $C7, $AF, $84
	dc.b	$CB, $86, $10, $8F, $39, $85, $20, $88, $77, $0A, $D2, $DC
	dc.b	$DD, $74, $91, $A2, $50, $2A, $E7, $C0, $C2, $EC, $69, $F9
	dc.b	$C7, $F5, $51, $BA, $D1, $BB, $0F, $32, $89, $BE, $00, $B0
	dc.b	$BE, $17, $03, $B9, $90, $46, $04, $E9, $77, $3B, $04, $63
	dc.b	$95, $2E, $31, $73, $DB, $15, $B9, $CA, $8B, $3F, $D1, $52
	dc.b	$94, $A5, $3C, $FE, $75, $ED, $5C, $0C, $86, $5C, $C9, $AE
	dc.b	$D0, $B3, $66, $C6, $B2, $09, $F9, $DD, $86, $49, $7F, $3F
	dc.b	$DC, $5F, $77, $63, $2B, $CC, $1A, $92, $D7, $03, $BB, $D3
	dc.b	$F3, $F9, $89, $5D, $A1, $97, $AF, $86, $11, $1F, $E8, $C4
	dc.b	$65, $81, $C3, $DB, $FB, $CD, $52, $94, $A6, $A9, $4F, $3A
	dc.b	$F3, $5F, $D2, $FB, $DC, $7C, $87, $A3, $1C, $C6, $E3, $B5
	dc.b	$1C, $29, $36, $E3, $B3, $08, $3F, $B5, $6B, $36, $3E, $0E
	dc.b	$F3, $BD, $04, $C2, $D6, $DF, $D2, $4D, $A7, $24, $5A, $63
	dc.b	$3A, $FD, $45, $5B, $FA, $CA, $A6, $49, $EE, $C2, $E9, $5F
	dc.b	$F9, $5F, $CC, $B2, $43, $A8, $24, $6E, $1D, $A1, $79, $C9
	dc.b	$A8, $20, $F0, $5F, $36, $9E, $17, $88, $5C, $D9, $47, $24
	dc.b	$AC, $C4, $B0, $A7, $B8, $9E, $61, $EB, $8C, $E4, $9F, $A2
	dc.b	$22, $3C, $D7, $CF, $D6, $51, $AA, $E9, $70, $F3, $25, $37
	dc.b	$C0, $16, $17, $C2, $E0, $77, $32, $08, $C0, $9D, $2E, $E7
	dc.b	$60, $8C, $72, $A5, $C6, $2E, $00, $00, $06, $03, $00, $00
	dc.b	$00, $01, $05, $10, $12, $C2, $04, $88, $50, $11, $04, $80
	dc.b	$14, $05, $10, $9A, $21, $54, $42, $60, $05, $05, $01, $34
	dc.b	$38, $11, $40, $51, $11, $81, $14, $04, $01, $10, $20, $C5
	dc.b	$05, $01, $5C, $58, $02, $20, $40, $1F, $02, $00, $88, $10
	dc.b	$07, $C3, $80, $C8, $04, $01, $A1, $38, $B4, $94, $01, $00
	dc.b	$AC, $58, $0E, $20, $40, $1A, $13, $93, $B1, $A9, $A8, $1C
	dc.b	$5D, $8D, $42, $E2, $68, $6C, $0F, $F0, $05, $00, $00, $00
	dc.b	$00, $00, $39, $0A, $41, $06, $01, $81, $80, $90, $29, $AF
	dc.b	$F8, $50, $52, $4F, $44, $55, $43, $45, $44, $20, $42, $59
	dc.b	$20, $4F, $52, $20, $55, $4E, $44, $45, $52, $20, $4C, $49
	dc.b	$43, $45, $4E, $53, $45, $00, $00, $20, $46, $52, $4F, $4D
	dc.b	$20, $53, $45, $47, $41, $20, $45, $4E, $54, $45, $52, $50
	dc.b	$52, $49, $53, $45, $53, $2C, $20, $4C, $54, $44, $2E, $FF
	dc.b	$14, $11, $08, $0D, $17, $11, $00, $0D, $14, $11, $14, $11
	dc.b	$90, $00, $00, $00, $00, $1C, $14, $11, $80, $80, $80, $1D
	dc.b	$11, $00, $00, $00, $00, $98, $11, $07, $00, $01, $00, $97
	dc.b	$11, $00, $00, $3F, $11, $00, $0B, $48, $11, $00, $0B, $60
	dc.b	$11, $00, $0B, $70, $11, $00, $0B, $7F, $11, $00, $0B, $8C
	dc.b	$11, $00, $0B, $EF, $01, $E0, $80, $80, $08, $C9, $0A, $F2
	dc.b	$80, $41, $EF, $00, $F0, $0A, $01, $02, $08, $A9, $19, $80
	dc.b	$01, $A5, $35, $E7, $A5, $02, $F7, $00, $04, $57, $11, $F2
	dc.b	$80, $41, $EF, $00, $F0, $0A, $01, $02, $08, $B8, $19, $80
	dc.b	$01, $B5, $42, $F2, $EF, $01, $E0, $80, $80, $04, $C4, $0A
	dc.b	$E0, $40, $80, $04, $C4, $2F, $F2, $EF, $01, $E0, $80, $80
	dc.b	$0E, $E0, $40, $80, $08, $C9, $2B, $F2, $EF, $01, $E0, $80
	dc.b	$C1, $0F, $E0, $40, $C1, $34, $F2, $F2, $32, $01, $01, $01
	dc.b	$01, $3F, $1F, $1F, $1F, $19, $06, $04, $07, $08, $05, $05
	dc.b	$04, $19, $19, $19, $19, $11, $89, $18, $87, $04, $37, $72
	dc.b	$77, $49, $1F, $1F, $1F, $1F, $07, $0A, $07, $0D, $00, $0B
	dc.b	$00, $0B, $1F, $0F, $1F, $0F, $23, $80, $23, $80
SecurityEuropeEnd:

; ----------------------------------------------------------------------
; Sound driver
; ----------------------------------------------------------------------

SecuritySound:
	dc.b	$F3, $F3, $ED, $56, $18, $5D, $00, $00, $3A, $00, $40, $CB
	dc.b	$7F, $20, $F9, $C9, $DD, $CB, $01, $7E, $C0, $C3, $58, $04
	dc.b	$C3, $66, $04, $00, $00, $00, $00, $00, $2A, $02, $1C, $06
	dc.b	$00, $C3, $32, $04, $4F, $06, $00, $09, $09, $00, $00, $00
	dc.b	$7E, $23, $66, $6F, $C9, $00, $00, $00, $F3, $F5, $C5, $D5
	dc.b	$E5, $21, $FF, $1F, $7E, $B7, $28, $03, $35, $18, $17, $3E
	dc.b	$80, $32, $07, $1C, $0E, $00, $3E, $25, $DF, $0E, $92, $3E
	dc.b	$24, $DF, $0E, $1F, $3E, $27, $DF, $CD, $A3, $00, $E1, $D1
	dc.b	$C1, $F1, $C9, $21, $00, $11, $22, $02, $1C, $31, $FD, $1F
	dc.b	$3E, $03, $32, $FF, $1F, $FB, $3A, $FF, $1F, $B7, $C2, $71
	dc.b	$00, $CD, $A5, $07, $CD, $CA, $06, $21, $00, $11, $22, $02
	dc.b	$1C, $FB, $CD, $3D, $08, $3A, $07, $1C, $B7, $28, $F7, $CD
	dc.b	$3D, $08, $3A, $00, $40, $CB, $47, $28, $ED, $AF, $32, $07
	dc.b	$1C, $CD, $A3, $00, $FB, $18, $E3, $CD, $DD, $06, $CD, $24
	dc.b	$08, $CD, $59, $07, $CD, $C4, $04, $CD, $C9, $00, $AF, $32
	dc.b	$19, $1C, $DD, $21, $40, $1C, $DD, $CB, $00, $7E, $C4, $39
	dc.b	$09, $06, $09, $DD, $21, $70, $1C, $18, $19, $3E, $01, $32
	dc.b	$19, $1C, $DD, $21, $80, $1E, $06, $06, $CD, $E2, $00, $3E
	dc.b	$80, $32, $19, $1C, $06, $02, $DD, $21, $20, $1E, $C5, $DD
	dc.b	$CB, $00, $7E, $C4, $F3, $00, $11, $30, $00, $DD, $19, $C1
	dc.b	$10, $F0, $C9, $DD, $CB, $01, $7E, $C2, $BC, $0E, $CD, $BE
	dc.b	$02, $20, $17, $CD, $90, $01, $DD, $CB, $00, $66, $C0, $CD
	dc.b	$F5, $02, $CD, $EC, $03, $CD, $20, $03, $CD, $38, $01, $C3
	dc.b	$C5, $03, $CD, $A8, $02, $DD, $CB, $00, $66, $C0, $CD, $C6
	dc.b	$02, $DD, $7E, $1E, $B7, $28, $06, $DD, $35, $1E, $CA, $DC
	dc.b	$03, $CD, $EC, $03, $DD, $CB, $00, $76, $C0, $CD, $20, $03
	dc.b	$DD, $CB, $00, $56, $C0, $DD, $CB, $00, $46, $C2, $4D, $01
	dc.b	$3E, $A4, $4C, $D7, $3E, $A0, $4D, $D7, $C9, $DD, $7E, $01
	dc.b	$FE, $02, $20, $F0, $CD, $80, $01, $D9, $21, $7C, $01, $06
	dc.b	$04, $7E, $F5, $23, $D9, $EB, $4E, $23, $46, $23, $EB, $DD
	dc.b	$6E, $0D, $DD, $66, $0E, $09, $F1, $F5, $4C, $DF, $F1, $D6
	dc.b	$04, $4D, $DF, $D9, $10, $E3, $D9, $C9, $AD, $AE, $AC, $A6
	dc.b	$11, $2A, $1C, $3A, $19, $1C, $B7, $C8, $11, $1A, $1C, $F0
	dc.b	$11, $22, $1C, $C9, $DD, $5E, $03, $DD, $56, $04, $DD, $CB
	dc.b	$00, $8E, $DD, $CB, $00, $A6, $1A, $13, $FE, $E0, $D2, $2F
	dc.b	$0B, $08, $CD, $DC, $03, $CD, $62, $02, $08, $DD, $CB, $00
	dc.b	$5E, $C2, $0A, $02, $B7, $F2, $30, $02, $D6, $81, $F2, $C2
	dc.b	$01, $CD, $63, $0F, $18, $2E, $DD, $86, $05, $21, $97, $08
	dc.b	$F5, $EF, $F1, $DD, $CB, $01, $7E, $20, $19, $D5, $16, $08
	dc.b	$1E, $0C, $08, $AF, $08, $93, $38, $05, $08, $82, $18, $F8
	dc.b	$08, $83, $21, $21, $09, $EF, $08, $B4, $67, $D1, $DD, $75
	dc.b	$0D, $DD, $74, $0E, $DD, $CB, $00, $6E, $20, $0D, $1A, $B7
	dc.b	$F2, $2F, $02, $DD, $7E, $0C, $DD, $77, $0B, $18, $33, $1A
	dc.b	$13, $DD, $77, $10, $18, $24, $67, $1A, $13, $6F, $B4, $28
	dc.b	$0C, $DD, $7E, $05, $06, $00, $B7, $F2, $1B, $02, $05, $4F
	dc.b	$09, $DD, $75, $0D, $DD, $74, $0E, $DD, $CB, $00, $6E, $28
	dc.b	$05, $1A, $13, $DD, $77, $10, $1A, $13, $CD, $58, $02, $DD
	dc.b	$77, $0C, $DD, $73, $03, $DD, $72, $04, $DD, $7E, $0C, $DD
	dc.b	$77, $0B, $DD, $CB, $00, $4E, $C0, $AF, $DD, $77, $25, $DD
	dc.b	$77, $22, $DD, $77, $17, $DD, $7E, $1F, $DD, $77, $1E, $C9
	dc.b	$DD, $46, $02, $05, $C8, $4F, $81, $10, $FD, $C9, $DD, $7E
	dc.b	$11, $3D, $F8, $20, $3B, $DD, $CB, $00, $4E, $C0, $DD, $35
	dc.b	$16, $C0, $D9, $DD, $7E, $15, $DD, $77, $16, $DD, $7E, $12
	dc.b	$21, $B0, $02, $EF, $DD, $5E, $13, $DD, $34, $13, $DD, $7E
	dc.b	$14, $3D, $BB, $20, $0E, $DD, $35, $13, $DD, $7E, $11, $FE
	dc.b	$02, $28, $04, $DD, $36, $13, $00, $16, $00, $19, $EB, $CD
	dc.b	$27, $0D, $D9, $C9, $AF, $DD, $77, $13, $DD, $7E, $11, $D6
	dc.b	$02, $F8, $18, $BE, $B8, $02, $B9, $02, $BA, $02, $BB, $02
	dc.b	$C0, $80, $C0, $40, $80, $C0, $DD, $7E, $0B, $3D, $DD, $77
	dc.b	$0B, $C9, $DD, $7E, $18, $B7, $C8, $F8, $3D, $0E, $0A, $E7
	dc.b	$EF, $CD, $32, $0F, $DD, $66, $1D, $DD, $6E, $1C, $11, $97
	dc.b	$04, $06, $04, $DD, $4E, $19, $F5, $CB, $29, $C5, $30, $06
	dc.b	$86, $E6, $7F, $4F, $1A, $D7, $C1, $13, $23, $F1, $10, $EE
	dc.b	$C9, $DD, $CB, $07, $7E, $C8, $DD, $CB, $00, $4E, $C0, $DD
	dc.b	$5E, $20, $DD, $56, $21, $DD, $E5, $E1, $06, $00, $0E, $24
	dc.b	$09, $EB, $ED, $A0, $ED, $A0, $ED, $A0, $7E, $CB, $3F, $12
	dc.b	$AF, $DD, $77, $22, $DD, $77, $23, $C9, $DD, $7E, $07, $B7
	dc.b	$C8, $FE, $80, $20, $48, $DD, $35, $24, $C0, $DD, $34, $24
	dc.b	$E5, $DD, $6E, $22, $DD, $66, $23, $DD, $35, $25, $20, $20
	dc.b	$DD, $5E, $20, $DD, $56, $21, $D5, $FD, $E1, $FD, $7E, $01
	dc.b	$DD, $77, $25, $DD, $7E, $26, $4F, $E6, $80, $07, $ED, $44
	dc.b	$47, $09, $DD, $75, $22, $DD, $74, $23, $C1, $09, $DD, $35
	dc.b	$27, $C0, $FD, $7E, $03, $DD, $77, $27, $DD, $7E, $26, $ED
	dc.b	$44, $DD, $77, $26, $C9, $3D, $EB, $0E, $08, $E7, $EF, $18
	dc.b	$03, $DD, $77, $25, $E5, $DD, $4E, $25, $CD, $37, $04, $E1
	dc.b	$CB, $7F, $CA, $B6, $03, $FE, $82, $28, $12, $FE, $80, $28
	dc.b	$12, $FE, $84, $28, $11, $26, $FF, $30, $1F, $DD, $CB, $00
	dc.b	$F6, $E1, $C9, $03, $0A, $18, $D6, $AF, $18, $D3, $03, $0A
	dc.b	$DD, $86, $22, $DD, $77, $22, $DD, $34, $25, $DD, $34, $25
	dc.b	$18, $C6, $26, $00, $6F, $DD, $46, $22, $04, $EB, $19, $10
	dc.b	$FD, $DD, $34, $25, $C9, $DD, $7E, $0D, $DD, $B6, $0E, $C8
	dc.b	$DD, $7E, $00, $E6, $06, $C0, $DD, $7E, $01, $F6, $F0, $4F
	dc.b	$3E, $28, $DF, $C9, $DD, $7E, $00, $E6, $06, $C0, $DD, $4E
	dc.b	$01, $CB, $79, $C0, $3E, $28, $DF, $C9, $06, $00, $DD, $7E
	dc.b	$10, $B7, $F2, $F6, $03, $05, $DD, $66, $0E, $DD, $6E, $0D
	dc.b	$4F, $09, $DD, $CB, $01, $7E, $20, $22, $EB, $3E, $07, $A2
	dc.b	$47, $4B, $B7, $21, $83, $02, $ED, $42, $38, $06, $21, $85
	dc.b	$FA, $19, $18, $0E, $B7, $21, $08, $05, $ED, $42, $30, $05
	dc.b	$21, $7C, $05, $19, $EB, $EB, $DD, $CB, $00, $6E, $C8, $DD
	dc.b	$74, $0E, $DD, $75, $0D, $C9, $09, $08, $F7, $08, $C9, $06
	dc.b	$00, $09, $4D, $44, $0A, $C9, $2A, $37, $1C, $3A, $19, $1C
	dc.b	$B7, $28, $06, $DD, $6E, $2A, $DD, $66, $2B, $AF, $B0, $28
	dc.b	$06, $11, $19, $00, $19, $10, $FD, $C9, $DD, $CB, $01, $56
	dc.b	$20, $11, $DD, $CB, $00, $56, $C0, $DD, $86, $01, $32, $00
	dc.b	$40, $CF, $79, $32, $01, $40, $C9, $DD, $CB, $00, $56, $C0
	dc.b	$DD, $86, $01, $D6, $04, $32, $02, $40, $CF, $79, $32, $03
	dc.b	$40, $C9, $B0, $30, $38, $34, $3C, $50, $58, $54, $5C, $60
	dc.b	$68, $64, $6C, $70, $78, $74, $7C, $80, $88, $84, $8C, $40
	dc.b	$48, $44, $4C, $90, $98, $94, $9C, $11, $82, $04, $DD, $4E
	dc.b	$0A, $3E, $B4, $D7, $CD, $BE, $04, $DD, $77, $1B, $06, $14
	dc.b	$CD, $BE, $04, $10, $FB, $DD, $75, $1C, $DD, $74, $1D, $C3
	dc.b	$41, $0D, $1A, $13, $4E, $23, $D7, $C9, $3A, $09, $1C, $CB
	dc.b	$7F, $CA, $A5, $07, $FE, $90, $DA, $14, $05, $FE, $D0, $DA
	dc.b	$BE, $05, $FE, $E0, $DA, $B5, $05, $FE, $F9, $D2, $A5, $07
	dc.b	$D6, $E0, $21, $EB, $04, $EF, $AF, $32, $18, $1C, $E9, $36
	dc.b	$07, $A5, $07, $0D, $08, $F3, $04, $DD, $21, $20, $1E, $06
	dc.b	$02, $3E, $80, $32, $19, $1C, $C5, $DD, $CB, $00, $7E, $C4
	dc.b	$0F, $05, $11, $30, $00, $DD, $19, $C1, $10, $F0, $C9, $E5
	dc.b	$E5, $C3, $DE, $0D, $D6, $81, $F8, $F5, $CD, $A5, $07, $F1
	dc.b	$0E, $04, $E7, $EF, $E5, $E5, $F7, $22, $37, $1C, $E1, $FD
	dc.b	$E1, $FD, $7E, $05, $32, $13, $1C, $32, $14, $1C, $11, $06
	dc.b	$00, $19, $22, $33, $1C, $21, $A1, $05, $22, $35, $1C, $11
	dc.b	$40, $1C, $FD, $46, $02, $FD, $7E, $04, $C5, $2A, $35, $1C
	dc.b	$ED, $A0, $ED, $A0, $12, $13, $22, $35, $1C, $2A, $33, $1C
	dc.b	$ED, $A0, $ED, $A0, $ED, $A0, $ED, $A0, $22, $33, $1C, $CD
	dc.b	$80, $06, $C1, $10, $DF, $FD, $7E, $03, $B7, $CA, $9B, $05
	dc.b	$47, $21, $AF, $05, $22, $35, $1C, $11, $90, $1D, $FD, $7E
	dc.b	$04, $C5, $2A, $35, $1C, $ED, $A0, $ED, $A0, $12, $13, $22
	dc.b	$35, $1C, $2A, $33, $1C, $01, $06, $00, $ED, $B0, $22, $33
	dc.b	$1C, $CD, $87, $06, $C1, $10, $E2, $3E, $80, $32, $09, $1C
	dc.b	$C9, $80, $02, $80, $00, $80, $01, $80, $04, $80, $05, $80
	dc.b	$06, $80, $02, $80, $80, $80, $A0, $80, $C0, $D6, $D0, $08
	dc.b	$3E, $80, $0E, $02, $18, $06, $D6, $90, $08, $AF, $0E, $06
	dc.b	$32, $19, $1C, $08, $E7, $EF, $E5, $F7, $22, $39, $1C, $AF
	dc.b	$32, $15, $1C, $E1, $E5, $FD, $E1, $FD, $7E, $02, $32, $3B
	dc.b	$1C, $11, $04, $00, $19, $FD, $46, $03, $C5, $E5, $23, $4E
	dc.b	$CD, $47, $06, $CB, $D6, $DD, $E5, $3A, $19, $1C, $B7, $28
	dc.b	$03, $E1, $FD, $E5, $D1, $E1, $ED, $A0, $1A, $FE, $02, $CC
	dc.b	$CF, $07, $ED, $A0, $3A, $3B, $1C, $12, $13, $ED, $A0, $ED
	dc.b	$A0, $ED, $A0, $ED, $A0, $CD, $80, $06, $DD, $CB, $00, $7E
	dc.b	$28, $0C, $DD, $7E, $01, $FD, $BE, $01, $20, $04, $FD, $CB
	dc.b	$00, $D6, $E5, $2A, $39, $1C, $3A, $19, $1C, $B7, $28, $04
	dc.b	$FD, $E5, $DD, $E1, $DD, $75, $2A, $DD, $74, $2B, $CD, $DC
	dc.b	$03, $CD, $DB, $07, $E1, $C1, $10, $A0, $C3, $9B, $05, $CB
	dc.b	$79, $20, $05, $79, $D6, $02, $18, $16, $3E, $1F, $CD, $6C
	dc.b	$0F, $3E, $FF, $32, $11, $7F, $79, $CB, $3F, $CB, $3F, $CB
	dc.b	$3F, $CB, $3F, $CB, $3F, $3C, $32, $32, $1C, $F5, $21, $AA
	dc.b	$06, $EF, $E5, $DD, $E1, $F1, $F5, $21, $9A, $06, $EF, $E5
	dc.b	$FD, $E1, $F1, $21, $BA, $06, $EF, $C9, $08, $AF, $12, $13
	dc.b	$12, $13, $08, $EB, $36, $30, $23, $36, $C0, $23, $36, $01
	dc.b	$06, $24, $23, $36, $00, $10, $FB, $23, $EB, $C9, $20, $1E
	dc.b	$20, $1E, $20, $1E, $20, $1E, $50, $1E, $20, $1E, $20, $1E
	dc.b	$50, $1E, $80, $1E, $B0, $1E, $B0, $1E, $B0, $1E, $E0, $1E
	dc.b	$10, $1F, $40, $1F, $70, $1F, $60, $1D, $00, $1D, $00, $1D
	dc.b	$00, $1D, $30, $1D, $90, $1D, $C0, $1D, $F0, $1D, $3A, $01
	dc.b	$1C, $07, $32, $00, $60, $06, $08, $3A, $00, $1C, $32, $00
	dc.b	$60, $0F, $10, $FA, $C9, $21, $10, $1C, $7E, $B7, $C8, $FA
	dc.b	$EE, $06, $D1, $3D, $C0, $36, $02, $C3, $E2, $07, $AF, $77
	dc.b	$3A, $0D, $1C, $B7, $C2, $A5, $07, $DD, $21, $70, $1C, $06
	dc.b	$06, $3A, $11, $1C, $B7, $20, $06, $DD, $CB, $00, $7E, $28
	dc.b	$06, $DD, $4E, $0A, $3E, $B4, $D7, $11, $30, $00, $DD, $19
	dc.b	$10, $E7, $DD, $21, $20, $1E, $06, $08, $DD, $CB, $00, $7E
	dc.b	$28, $0C, $DD, $CB, $01, $7E, $20, $06, $DD, $4E, $0A, $3E
	dc.b	$B4, $D7, $11, $30, $00, $DD, $19, $10, $E7, $C9, $3E, $28
	dc.b	$32, $0D, $1C, $3E, $06, $32, $0F, $1C, $32, $0E, $1C, $AF
	dc.b	$32, $40, $1C, $32, $60, $1D, $32, $F0, $1D, $32, $90, $1D
	dc.b	$32, $C0, $1D, $CD, $0D, $08, $C3, $9B, $05, $21, $0D, $1C
	dc.b	$7E, $B7, $C8, $FC, $43, $07, $CB, $BE, $3A, $0F, $1C, $3D
	dc.b	$28, $04, $32, $0F, $1C, $C9, $3A, $0E, $1C, $32, $0F, $1C
	dc.b	$3A, $0D, $1C, $3D, $32, $0D, $1C, $28, $28, $DD, $21, $40
	dc.b	$1C, $06, $06, $DD, $34, $06, $F2, $8E, $07, $DD, $35, $06
	dc.b	$18, $0F, $DD, $CB, $00, $7E, $28, $09, $DD, $CB, $00, $56
	dc.b	$20, $03, $CD, $41, $0D, $11, $30, $00, $DD, $19, $10, $DF
	dc.b	$C9, $21, $09, $1C, $11, $0A, $1C, $01, $96, $03, $36, $00
	dc.b	$ED, $B0, $DD, $21, $A1, $05, $06, $06, $C5, $CD, $79, $08
	dc.b	$CD, $DB, $07, $DD, $23, $DD, $23, $C1, $10, $F2, $06, $07
	dc.b	$AF, $32, $0D, $1C, $CD, $0D, $08, $3E, $0F, $32, $12, $1C
	dc.b	$4F, $3E, $27, $DF, $C3, $9B, $05, $3E, $90, $0E, $00, $C3
	dc.b	$8D, $08, $CD, $0D, $08, $C5, $F5, $06, $03, $3E, $B4, $0E
	dc.b	$00, $F5, $DF, $F1, $3C, $10, $FA, $06, $03, $3E, $B4, $F5
	dc.b	$CD, $79, $04, $F1, $3C, $10, $F8, $0E, $00, $06, $07, $3E
	dc.b	$28, $F5, $DF, $0C, $F1, $10, $FA, $F1, $C1, $E5, $C5, $21
	dc.b	$20, $08, $06, $04, $7E, $32, $11, $7F, $23, $10, $F9, $C1
	dc.b	$E1, $C3, $9B, $05, $9F, $BF, $DF, $FF, $21, $13, $1C, $7E
	dc.b	$B7, $C8, $35, $C0, $3A, $14, $1C, $77, $21, $4B, $1C, $11
	dc.b	$30, $00, $06, $0A, $34, $19, $10, $FC, $C9, $ED, $5F, $32
	dc.b	$17, $1C, $11, $0A, $1C, $CD, $4B, $08, $CD, $4B, $08, $1A
	dc.b	$CB, $7F, $C8, $0E, $00, $FE, $90, $38, $04, $D6, $0F, $0E
	dc.b	$10, $D6, $81, $2A, $02, $1C, $E7, $4F, $06, $00, $09, $3A
	dc.b	$18, $1C, $BE, $28, $02, $30, $0A, $1A, $32, $09, $1C, $7E
	dc.b	$E6, $7F, $32, $18, $1C, $AF, $12, $13, $C9, $CD, $89, $08
	dc.b	$3E, $40, $0E, $7F, $CD, $8D, $08, $DD, $4E, $01, $C3, $E8
	dc.b	$03, $3E, $80, $0E, $FF, $06, $04, $F5, $D7, $F1, $C6, $04
	dc.b	$10, $F9, $C9, $56, $03, $26, $03, $F9, $02, $CE, $02, $A5
	dc.b	$02, $80, $02, $5C, $02, $3A, $02, $1A, $02, $FB, $01, $DF
	dc.b	$01, $C4, $01, $AB, $01, $93, $01, $7D, $01, $67, $01, $53
	dc.b	$01, $40, $01, $2E, $01, $1D, $01, $0D, $01, $FE, $00, $EF
	dc.b	$00, $E2, $00, $D6, $00, $C9, $00, $BE, $00, $B4, $00, $A9
	dc.b	$00, $A0, $00, $97, $00, $8F, $00, $87, $00, $7F, $00, $78
	dc.b	$00, $71, $00, $6B, $00, $65, $00, $5F, $00, $5A, $00, $55
	dc.b	$00, $50, $00, $4B, $00, $47, $00, $43, $00, $40, $00, $3C
	dc.b	$00, $39, $00, $36, $00, $33, $00, $30, $00, $2D, $00, $2B
	dc.b	$00, $28, $00, $26, $00, $24, $00, $22, $00, $20, $00, $1F
	dc.b	$00, $1D, $00, $1B, $00, $1A, $00, $18, $00, $17, $00, $16
	dc.b	$00, $15, $00, $13, $00, $12, $00, $11, $00, $84, $02, $AB
	dc.b	$02, $D3, $02, $FE, $02, $2D, $03, $5C, $03, $8F, $03, $C5
	dc.b	$03, $FF, $03, $3C, $04, $7C, $04, $C0, $04, $CD, $BE, $02
	dc.b	$CC, $40, $09, $C9, $DD, $5E, $03, $DD, $56, $04, $1A, $13
	dc.b	$FE, $E0, $D2, $ED, $09, $B7, $FA, $55, $09, $1B, $DD, $7E
	dc.b	$0D, $DD, $77, $0D, $FE, $80, $CA, $D7, $09, $D5, $21, $60
	dc.b	$1D, $CB, $56, $20, $44, $E6, $0F, $28, $40, $08, $CD, $DC
	dc.b	$03, $08, $11, $E7, $09, $EB, $ED, $A0, $ED, $A0, $ED, $A0
	dc.b	$3D, $21, $11, $0A, $EF, $01, $06, $00, $ED, $B0, $CD, $87
	dc.b	$06, $21, $65, $1D, $DD, $7E, $05, $86, $77, $3A, $68, $1D
	dc.b	$21, $25, $0A, $EF, $3A, $66, $1D, $DD, $5E, $06, $D5, $83
	dc.b	$DD, $77, $06, $CD, $9F, $04, $D1, $DD, $73, $06, $CD, $CF
	dc.b	$07, $21, $F0, $1D, $CB, $56, $20, $26, $DD, $7E, $0D, $E6
	dc.b	$70, $28, $1F, $11, $EA, $09, $EB, $ED, $A0, $ED, $A0, $ED
	dc.b	$A0, $CB, $3F, $CB, $3F, $CB, $3F, $CB, $3F, $3D, $21, $F7
	dc.b	$09, $EF, $01, $06, $00, $ED, $B0, $CD, $87, $06, $D1, $1A
	dc.b	$13, $B7, $F2, $30, $02, $1B, $DD, $7E, $0C, $DD, $77, $0B
	dc.b	$C3, $36, $02, $80, $02, $01, $80, $C0, $01, $21, $F3, $09
	dc.b	$C3, $32, $0B, $13, $C3, $46, $09, $FB, $09, $06, $0A, $01
	dc.b	$0A, $00, $04, $00, $01, $F3, $E7, $C2, $08, $F2, $0C, $0A
	dc.b	$00, $06, $00, $02, $F3, $E7, $C5, $08, $F2, $31, $0A, $53
	dc.b	$0A, $77, $0A, $80, $0A, $94, $0A, $B6, $0A, $8B, $0A, $D8
	dc.b	$0A, $E1, $0A, $08, $0B, $3A, $0A, $5E, $0A, $9D, $0A, $BF
	dc.b	$0A, $EF, $0A, $16, $0B, $37, $0A, $00, $06, $00, $00, $B4
	dc.b	$10, $F2, $3C, $0F, $00, $00, $00, $1F, $1A, $18, $1C, $17
	dc.b	$11, $1A, $0E, $00, $0F, $14, $10, $1F, $EC, $FF, $FF, $07
	dc.b	$80, $16, $80, $59, $0A, $00, $0C, $01, $01, $E0, $80, $B6
	dc.b	$0A, $F2, $3E, $60, $30, $30, $30, $19, $1F, $1F, $1F, $15
	dc.b	$11, $11, $0C, $10, $0A, $06, $09, $4F, $5F, $AF, $8F, $00
	dc.b	$82, $83, $80, $7D, $0A, $00, $0C, $01, $01, $B3, $0A, $F2
	dc.b	$86, $0A, $00, $0C, $01, $01, $E0, $40, $B0, $0A, $F2, $91
	dc.b	$0A, $00, $0C, $01, $01, $B2, $0A, $F2, $9A, $0A, $00, $0A
	dc.b	$01, $02, $8F, $08, $F2, $3C, $00, $00, $00, $00, $1F, $1F
	dc.b	$1F, $1F, $00, $16, $0F, $0F, $00, $00, $00, $00, $0F, $AF
	dc.b	$FF, $FF, $00, $85, $0A, $80, $BC, $0A, $00, $06, $01, $03
	dc.b	$B0, $16, $F2, $72, $9E, $5B, $42, $22, $96, $96, $9E, $96
	dc.b	$16, $18, $16, $18, $10, $17, $11, $18, $4F, $5F, $4F, $4F
	dc.b	$00, $00, $10, $80, $DE, $0A, $00, $0E, $01, $01, $B9, $10
	dc.b	$F2, $E7, $0A, $F7, $0A, $00, $04, $FE, $03, $00, $00, $00
	dc.b	$95, $20, $F2, $3C, $0A, $50, $70, $00, $1F, $17, $19, $1D
	dc.b	$1D, $15, $1A, $17, $06, $18, $07, $19, $0F, $5F, $6F, $1F
	dc.b	$0C, $95, $00, $8E, $0E, $0B, $00, $07, $00, $05, $FE, $00
	dc.b	$03, $00, $03, $D1, $08, $F2, $3D, $00, $0F, $0F, $0F, $1F
	dc.b	$9F, $9F, $9F, $1F, $1F, $1F, $1F, $00, $0E, $10, $0F, $0F
	dc.b	$4F, $4F, $4F, $00, $90, $90, $85, $21, $3B, $0B, $E5, $D6
	dc.b	$E0, $21, $46, $0B, $EF, $1A, $E9, $13, $C3, $9E, $01, $21
	dc.b	$86, $0B, $EF, $13, $1A, $E9, $27, $0D, $34, $0C, $49, $0C
	dc.b	$7E, $0C, $8E, $0C, $60, $0D, $68, $0D, $A1, $0C, $84, $0C
	dc.b	$38, $0D, $C2, $0B, $CF, $0B, $4D, $0C, $60, $0C, $65, $0C
	dc.b	$E4, $0C, $70, $0C, $A8, $0D, $DE, $0D, $80, $0D, $B0, $0D
	dc.b	$9F, $0D, $B4, $0D, $A5, $0E, $78, $0E, $92, $0E, $7C, $0D
	dc.b	$75, $0D, $BA, $0D, $D0, $0D, $A7, $0C, $3F, $0B, $BE, $0B
	dc.b	$41, $0C, $E3, $0B, $EB, $0B, $26, $0C, $AF, $0B, $96, $0B
	dc.b	$38, $0C, $DD, $36, $18, $80, $DD, $73, $19, $DD, $72, $1A
	dc.b	$21, $9B, $04, $06, $04, $1A, $13, $4F, $7E, $23, $D7, $10
	dc.b	$F8, $1B, $C9, $D9, $06, $0A, $11, $30, $00, $21, $42, $1C
	dc.b	$77, $19, $10, $FC, $D9, $C9, $32, $07, $1C, $C9, $21, $04
	dc.b	$1C, $EB, $ED, $A0, $ED, $A0, $ED, $A0, $EB, $1B, $C9, $EB
	dc.b	$4E, $23, $46, $23, $EB, $2A, $04, $1C, $09, $22, $04, $1C
	dc.b	$1A, $21, $06, $1C, $86, $77, $C9, $DD, $E5, $CD, $C7, $04
	dc.b	$DD, $E1, $C9, $32, $11, $1C, $B7, $28, $1D, $DD, $E5, $D5
	dc.b	$DD, $21, $40, $1C, $06, $0A, $11, $30, $00, $DD, $CB, $00
	dc.b	$BE, $CD, $E2, $03, $DD, $19, $10, $F5, $D1, $DD, $E1, $C3
	dc.b	$0D, $08, $DD, $E5, $D5, $DD, $21, $40, $1C, $06, $0A, $11
	dc.b	$30, $00, $DD, $CB, $00, $FE, $DD, $19, $10, $F8, $D1, $DD
	dc.b	$E1, $C9, $EB, $5E, $23, $56, $23, $4E, $06, $00, $23, $EB
	dc.b	$ED, $B0, $1B, $C9, $DD, $77, $10, $C9, $DD, $77, $18, $13
	dc.b	$1A, $DD, $77, $19, $C9, $21, $14, $1C, $86, $77, $2B, $77
	dc.b	$C9, $32, $16, $1C, $C9, $DD, $CB, $01, $7E, $C8, $DD, $CB
	dc.b	$00, $A6, $DD, $35, $17, $DD, $86, $06, $DD, $77, $06, $C9
	dc.b	$CD, $6A, $0C, $D7, $C9, $CD, $6A, $0C, $DF, $C9, $EB, $7E
	dc.b	$23, $4E, $EB, $C9, $DD, $73, $20, $DD, $72, $21, $DD, $36
	dc.b	$07, $80, $13, $13, $13, $C9, $CD, $79, $08, $C3, $DE, $0D
	dc.b	$CD, $58, $02, $DD, $77, $1E, $DD, $77, $1F, $C9, $DD, $E5
	dc.b	$E1, $01, $11, $00, $09, $EB, $01, $05, $00, $ED, $B0, $3E
	dc.b	$01, $12, $EB, $1B, $C9, $DD, $CB, $00, $CE, $1B, $C9, $DD
	dc.b	$7E, $01, $FE, $02, $20, $2A, $DD, $CB, $00, $C6, $D9, $CD
	dc.b	$80, $01, $06, $04, $C5, $D9, $1A, $13, $D9, $21, $DC, $0C
	dc.b	$87, $4F, $06, $00, $09, $ED, $A0, $ED, $A0, $C1, $10, $EC
	dc.b	$D9, $1B, $3E, $4F, $32, $12, $1C, $4F, $3E, $27, $DF, $C9
	dc.b	$13, $13, $13, $C9, $00, $00, $32, $01, $8E, $01, $E4, $01
	dc.b	$DD, $CB, $01, $7E, $20, $38, $CD, $89, $08, $1A, $DD, $77
	dc.b	$08, $F5, $13, $1A, $DD, $77, $0F, $F1, $B7, $F2, $17, $0D
	dc.b	$D5, $21, $00, $11, $0E, $04, $DD, $7E, $0F, $D6, $81, $CD
	dc.b	$23, $00, $EF, $F7, $DD, $7E, $08, $E6, $7F, $47, $CD, $4D
	dc.b	$04, $18, $06, $1B, $D5, $47, $CD, $3E, $04, $CD, $9F, $04
	dc.b	$D1, $C9, $1A, $B7, $F0, $13, $C9, $0E, $3F, $DD, $7E, $0A
	dc.b	$A1, $EB, $B6, $DD, $77, $0A, $4F, $3E, $B4, $D7, $EB, $C9
	dc.b	$4F, $3E, $22, $DF, $13, $0E, $C0, $18, $E8, $D9, $11, $97
	dc.b	$04, $DD, $6E, $1C, $DD, $66, $1D, $06, $04, $7E, $B7, $F2
	dc.b	$55, $0D, $DD, $86, $06, $E6, $7F, $4F, $1A, $D7, $13, $23
	dc.b	$10, $EF, $D9, $C9, $13, $DD, $86, $06, $DD, $77, $06, $1A
	dc.b	$DD, $CB, $01, $7E, $C0, $DD, $86, $06, $DD, $77, $06, $18
	dc.b	$CC, $DD, $86, $05, $DD, $77, $05, $C9, $DD, $77, $02, $C9
	dc.b	$DD, $CB, $01, $56, $C0, $3E, $DF, $32, $11, $7F, $1A, $DD
	dc.b	$77, $1A, $DD, $CB, $00, $C6, $B7, $20, $06, $DD, $CB, $00
	dc.b	$86, $3E, $FF, $32, $11, $7F, $C9, $DD, $CB, $01, $7E, $C8
	dc.b	$DD, $77, $08, $C9, $13, $DD, $CB, $01, $7E, $20, $01, $1A
	dc.b	$DD, $77, $07, $C9, $EB, $5E, $23, $56, $1B, $C9, $FE, $01
	dc.b	$20, $05, $DD, $CB, $00, $EE, $C9, $DD, $CB, $00, $8E, $DD
	dc.b	$CB, $00, $AE, $AF, $DD, $77, $10, $C9, $FE, $01, $20, $05
	dc.b	$DD, $CB, $00, $DE, $C9, $DD, $CB, $00, $9E, $C9, $DD, $CB
	dc.b	$00, $BE, $3E, $1F, $32, $15, $1C, $CD, $DC, $03, $DD, $4E
	dc.b	$01, $DD, $E5, $CD, $47, $06, $3A, $19, $1C, $B7, $28, $69
	dc.b	$AF, $32, $18, $1C, $FD, $CB, $00, $7E, $28, $12, $DD, $7E
	dc.b	$01, $FD, $BE, $01, $20, $0A, $FD, $E5, $FD, $6E, $2A, $FD
	dc.b	$66, $2B, $18, $04, $E5, $2A, $37, $1C, $DD, $E1, $DD, $CB
	dc.b	$00, $96, $DD, $CB, $01, $7E, $20, $42, $DD, $CB, $00, $7E
	dc.b	$28, $37, $3E, $02, $DD, $BE, $01, $20, $0D, $3E, $4F, $DD
	dc.b	$CB, $00, $46, $20, $02, $E6, $0F, $CD, $D0, $0C, $DD, $7E
	dc.b	$08, $B7, $F2, $4A, $0E, $CD, $FC, $0C, $18, $14, $47, $CD
	dc.b	$4D, $04, $CD, $9F, $04, $DD, $7E, $18, $B7, $F2, $61, $0E
	dc.b	$DD, $5E, $19, $DD, $56, $1A, $CD, $A0, $0B, $DD, $E1, $E1
	dc.b	$E1, $C9, $DD, $CB, $00, $46, $28, $F5, $DD, $7E, $1A, $B7
	dc.b	$F2, $76, $0E, $32, $11, $7F, $18, $E9, $4F, $13, $1A, $47
	dc.b	$C5, $DD, $E5, $E1, $DD, $35, $09, $DD, $4E, $09, $DD, $35
	dc.b	$09, $06, $00, $09, $72, $2B, $73, $D1, $1B, $C9, $DD, $E5
	dc.b	$E1, $DD, $4E, $09, $06, $00, $09, $5E, $23, $56, $DD, $34
	dc.b	$09, $DD, $34, $09, $C9, $13, $C6, $28, $4F, $06, $00, $DD
	dc.b	$E5, $E1, $09, $7E, $B7, $20, $02, $1A, $77, $13, $35, $C2
	dc.b	$B4, $0D, $13, $C9, $CD, $BE, $02, $20, $0D, $CD, $90, $01
	dc.b	$DD, $CB, $00, $66, $C0, $CD, $F5, $02, $18, $0C, $DD, $7E
	dc.b	$1E, $B7, $28, $06, $DD, $35, $1E, $CA, $63, $0F, $CD, $EC
	dc.b	$03, $CD, $20, $03, $DD, $CB, $00, $56, $C0, $DD, $4E, $01
	dc.b	$7D, $E6, $0F, $B1, $32, $11, $7F, $7D, $E6, $F0, $B4, $0F
	dc.b	$0F, $0F, $0F, $32, $11, $7F, $DD, $7E, $08, $B7, $0E, $00
	dc.b	$28, $09, $3D, $0E, $0A, $E7, $EF, $CD, $32, $0F, $4F, $DD
	dc.b	$CB, $00, $66, $C0, $DD, $7E, $06, $81, $CB, $67, $28, $02
	dc.b	$3E, $0F, $DD, $B6, $01, $C6, $10, $DD, $CB, $00, $46, $20
	dc.b	$04, $32, $11, $7F, $C9, $C6, $20, $32, $11, $7F, $C9, $DD
	dc.b	$77, $17, $E5, $DD, $4E, $17, $CD, $37, $04, $E1, $CB, $7F
	dc.b	$28, $21, $FE, $83, $28, $0C, $FE, $81, $28, $13, $FE, $80
	dc.b	$28, $0C, $03, $0A, $18, $E1, $DD, $CB, $00, $E6, $E1, $C3
	dc.b	$63, $0F, $AF, $18, $D6, $E1, $DD, $CB, $00, $E6, $C9, $DD
	dc.b	$34, $17, $C9, $DD, $CB, $00, $E6, $DD, $CB, $00, $56, $C0
	dc.b	$3E, $1F, $DD, $86, $01, $B7, $F0, $32, $11, $7F, $DD, $CB
	dc.b	$00, $46, $C8, $3E, $FF, $32, $11, $7F, $C9, $F3, $F5, $C5
	dc.b	$D5, $E5, $21, $FF, $1F, $7E, $B7, $28, $03, $35, $18, $07
	dc.b	$21, $08, $1C, $34, $CD, $A3, $00, $E1, $D1, $C1, $F1, $C9
	dc.b	$21, $00, $11, $22, $02, $1C, $31, $FD, $1F, $3E, $03, $32
	dc.b	$FF, $1F, $FB, $3A, $FF, $1F, $B7, $C2, $AA, $0F, $CD, $A5
	dc.b	$07, $FB, $CD, $3D, $08, $18, $FA
SecuritySoundEnd:

SecurityJapanSound:
	dc.b	$0B, $13, $0B, $13, $0E, $13, $0B, $13, $14, $11, $5A, $12
	dc.b	$90, $00, $00, $00, $00, $1C, $FF, $12, $28, $11, $34, $11
	dc.b	$40, $11, $4B, $11, $8F, $11, $C4, $11, $01, $12, $1B, $12
	dc.b	$35, $12, $46, $12, $40, $60, $70, $60, $50, $30, $10, $F0
	dc.b	$D0, $B0, $90, $83, $00, $02, $04, $06, $08, $0A, $0C, $0E
	dc.b	$10, $12, $14, $81, $00, $00, $01, $03, $01, $00, $FF, $FD
	dc.b	$00, $82, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $02, $04, $06, $08, $0A
	dc.b	$0C, $0A, $08, $06, $04, $02, $00, $FE, $FC, $FA, $F8, $F6
	dc.b	$F4, $F2, $F4, $F6, $F8, $FA, $FC, $FE, $00, $82, $29, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $02, $04, $06, $08, $0A, $0C, $0A, $08, $06
	dc.b	$04, $02, $00, $FE, $FC, $FA, $F8, $F6, $F4, $F6, $F8, $FA
	dc.b	$FC, $FE, $82, $1B, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $03, $06, $03, $00, $FD, $FA
	dc.b	$FA, $FD, $00, $82, $33, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $04, $02
	dc.b	$00, $FE, $FC, $FE, $00, $82, $11, $FE, $FF, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	dc.b	$00, $01, $01, $00, $00, $FF, $FF, $82, $11, $00, $00, $00
	dc.b	$00, $01, $01, $01, $01, $02, $02, $01, $01, $01, $00, $00
	dc.b	$00, $80, $00, $00, $00, $00, $01, $01, $01, $01, $02, $02
	dc.b	$01, $01, $01, $00, $00, $00, $84, $01, $82, $04, $70, $12
	dc.b	$72, $12, $79, $12, $92, $12, $9E, $12, $A9, $12, $B8, $12
	dc.b	$C1, $12, $D2, $12, $DE, $12, $F3, $12, $02, $83, $00, $02
	dc.b	$04, $06, $08, $10, $83, $02, $01, $00, $00, $01, $02, $02
	dc.b	$02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $03, $03
	dc.b	$03, $04, $04, $04, $05, $81, $00, $00, $02, $03, $04, $04
	dc.b	$05, $05, $05, $06, $06, $81, $03, $00, $01, $01, $01, $02
	dc.b	$03, $04, $04, $05, $81, $00, $00, $01, $01, $02, $03, $04
	dc.b	$05, $05, $06, $08, $07, $07, $06, $81, $01, $0C, $03, $0F
	dc.b	$02, $07, $03, $0F, $80, $00, $00, $00, $02, $03, $03, $04
	dc.b	$05, $06, $07, $08, $09, $0A, $0B, $0E, $0F, $83, $00, $00
	dc.b	$01, $01, $03, $03, $04, $05, $05, $05, $82, $04, $01, $00
	dc.b	$00, $00, $00, $01, $01, $01, $02, $02, $02, $03, $03, $03
	dc.b	$03, $04, $04, $04, $05, $05, $81, $05, $05, $04, $04, $03
	dc.b	$03, $02, $02, $01, $01, $00, $81, $7F, $7F, $7F, $7F, $7F
	dc.b	$7F, $7F, $7F, $7F, $7F, $7F, $7F, $80, $80, $80, $14, $13
	dc.b	$00, $00, $00, $00, $AC, $13, $07, $03, $02, $00, $AB, $13
	dc.b	$00, $00, $48, $13, $00, $24, $4C, $13, $00, $22, $50, $13
	dc.b	$00, $1E, $68, $13, $00, $2E, $6C, $13, $00, $2A, $84, $13
	dc.b	$00, $14, $94, $13, $00, $0B, $00, $09, $98, $13, $00, $08
	dc.b	$00, $09, $9C, $13, $00, $05, $00, $09, $E1, $0A, $80, $02
	dc.b	$E1, $F6, $80, $02, $EF, $00, $F0, $0A, $01, $02, $08, $B8
	dc.b	$24, $80, $01, $B5, $40, $E7, $B5, $02, $E6, $04, $F7, $00
	dc.b	$08, $5D, $13, $F2, $80, $09, $E1, $0A, $EF, $00, $F0, $0A
	dc.b	$01, $02, $08, $B5, $24, $80, $01, $B1, $40, $E7, $B1, $02
	dc.b	$E6, $04, $F7, $00, $08, $79, $13, $F2, $EF, $01, $F0, $01
	dc.b	$01, $F8, $00, $AB, $24, $40, $F0, $0A, $01, $02, $08, $F2
	dc.b	$80, $02, $E1, $02, $80, $02, $E1, $FE, $88, $24, $88, $40
	dc.b	$E7, $88, $04, $EC, $01, $F7, $00, $04, $A0, $13, $F2, $F2
	dc.b	$22, $01, $01, $03, $01, $05, $15, $14, $1B, $06, $04, $0B
	dc.b	$00, $00, $0F, $04, $00, $35, $25, $15, $0A, $00, $0F, $0A
	dc.b	$80, $3C, $01, $01, $01, $01, $1F, $1F, $1F, $1F, $00, $13
	dc.b	$11, $11, $00, $11, $0F, $0F, $00, $1A, $25, $1A, $0A, $82
	dc.b	$24, $80
SecurityJapanSoundEnd:
	even

; ----------------------------------------------------------------------