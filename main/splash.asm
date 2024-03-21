; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU splash screen
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
; Splash screen
; ----------------------------------------------------------------------
; Sega's BIOS loads a font and logo. Since it does not clear VRAM before
; booting anything, games and homebrew are able to use them. Here, we
; provide our own custom font and logo.
;
; One bit of homebrew that uses the font is 'Sega LOader', which can be
; found here: https://www.retrodev.com/slo.html
;
; Software which uses the logo include Devon's Bad Apple demo and the
; CrazySonic ROM-hack:
; https://github.com/DevsArchive/bad-apple-sega-cd-30-fps
; https://forums.sonicretro.org/index.php?posts/1056900/
; ----------------------------------------------------------------------

SplashScreen:
	bsr.w	SetDefaultVdpRegs			; Set VDP registers
	bsr.w	ClearVdpMemory				; Clear VDP memory
	bsr.w	ClearSprites				; Clear sprites
	bsr.w	LoadFontDefault				; Load font
	
	move.l	VBLANK_INT+2,-(sp)			; Save V-BLANK handler
	move.w	VBLANK_INT,-(sp)
	
	lea	WORK_RAM,a0				; Get security block type
	bsr.w	CheckSecurityBlock
	move.w	d0,-(sp)
	bmi.w	InvalidSecurityBlock			; If it's invalid, branch
	
	move	#$2700,sr				; Set V-BLANK handler
	move.w	#$4EF9,VBLANK_INT
	move.l	#VBlank_Splash,VBLANK_INT+2
	
	move.w	(sp),d1					; Check region
	bsr.w	CheckRegion

	lea	SplashPalette(pc),a1			; Load palette
	bsr.w	LoadPalette

	move.l	#$60000000,VDP_CTRL			; Load logo graphics
	lea	SplashLogoGraphics(pc),a1
	bsr.w	NemDec

	move.w	#$6100,d0				; Decompress logo tilemap
	lea	SplashLogoTilemap(pc),a1
	lea	decompBuffer,a2
	bsr.w	EniDec

	lea	decompBuffer,a1				; Load logo tilemap
	move.l	#$44180003,d0
	moveq	#16-1,d1
	moveq	#12-1,d2
	bsr.w	DrawTilemap

	lea	.Text(pc),a1				; Load text
	move.l	#$4A9C0003,d0
	bsr.w	DrawText

	bsr.w	EnableDisplay				; Enable display

	moveq	#60-1,d1				; Wait for a second
	bsr.w	Delay
	
	addq.w	#2,sp					; Deallocate security block type
	move.w	(sp)+,VBLANK_INT			; Restore V-BLANK handler
	move.l	(sp)+,VBLANK_INT+2
	rts

; ----------------------------------------------------------------------

.Text:
	dc.b	"NOW  LOADING", -1
	even

; ----------------------------------------------------------------------
; Invalid security block error message
; ----------------------------------------------------------------------

InvalidSecurityBlock:
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

CheckRegion:
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

	move.w	#(60*5)-1,d2				; Wait for several seconds

.Wait:
	bsr.w	DefaultVSync				; VSync
	dbf	d2,.Wait				; Loop until finished

	clr.w	palette					; Black out screen
	bsr.w	BlackOutDisplay
	
	move	#$2700,sr				; Disable interrupts
	bra.w	ClearScreen				; Clear screen

; ----------------------------------------------------------------------

.WarningStrings:
	dc.l	.NtscOnPal				; Japan
	dc.l	.NtscOnPal				; USA
	dc.l	.PalOnNtsc				; Europe

.NtscOnPal:
	dc.b	"            WARNING", 0, 0
	dc.b	" THIS IS AN NTSC DISC RUNNING", 0
	dc.b	"ON A PAL SYSTEM! THINGS MAY NOT", 0
	dc.b	"       WORK AS EXPECTED.", -1

.PalOnNtsc:
	dc.b	"            WARNING", 0, 0
	dc.b	"  THIS IS A PAL DISC RUNNING", 0
	dc.b	" ON AN NTSC SYSTEM. THINGS MAY", 0
	dc.b	"     NOT WORK AS EXPECTED.", -1
	even

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
	moveq	#0,d0					; Check Japanese security block
	move.w	#$156/2-1,d1
	move.w	#$B1E2,d2
	bsr.s	.Check
	beq.s	.End					; Branch if there was a match
	
	moveq	#1,d0					; Check USA security block
	move.w	#$584/2-1,d1
	move.w	#$35F9,d2
	bsr.s	.Check
	beq.s	.End					; Branch if there was a match
	
	moveq	#2,d0					; Check European security block
	move.w	#$56E/2-1,d1
	move.w	#$4351,d2
	bsr.s	.Check
	beq.s	.End					; Branch if there was a match

	moveq	#-1,d0					; No match

.End:
	tst.b	d0					; Check security block type
	rts

; ----------------------------------------------------------------------

.Check:
	movea.l	a0,a1					; Get security block to check
	moveq	#0,d3

.CheckLoop:
	add.w	(a1)+,d3				; Calculate checksum
	dbf	d1,.CheckLoop

	cmp.w	d2,d3					; Check calculated checksum value
	rts

; ----------------------------------------------------------------------
; V-BLANK handler
; ----------------------------------------------------------------------

VBlank_Splash:
	movem.l	d0-a6,-(sp)				; Save registers

	bsr.w	TriggerSubCpuIrq2			; Trigger Sub CPU IRQ2
	bsr.w	UpdateCram				; Update CRAM

	clr.b	vblankFlags				; Clear V-BLANK handler flags
	movem.l	(sp)+,d0-a6				; Restore registers
	rte

; ----------------------------------------------------------------------
; Assets
; ----------------------------------------------------------------------

SplashPalette:
	dc.b	0, (.DataEnd-.Data)/2-1
.Data:
	dc.w	$000, $EE8, $000, $000, $000, $000, $000, $000
	dc.w	$000, $000, $000, $000, $000, $000, $000, $000
	dc.w	$000, $EC0, $000, $000, $000, $000, $000, $000
	dc.w	$000, $000, $000, $000, $000, $000, $000, $000
	dc.w	$000, $E80, $000, $000, $000, $000, $000, $000
	dc.w	$000, $000, $000, $000, $000, $000, $000, $000
	dc.w	$000, $000, $222, $444, $EEE, $CCE, $AAC, $88C
	dc.w	$66C, $44A, $448, $22A, $000, $000, $000, $000
.DataEnd:

SplashLogoGraphics:
	dc.b	$80, $4D, $80, $06, $38, $15, $1A, $25, $19, $36, $36, $45
	dc.b	$16, $54, $09, $64, $04, $72, $00, $81, $04, $05, $82, $04
	dc.b	$07, $83, $04, $0A, $16, $3A, $89, $07, $7D, $8C, $04, $06
	dc.b	$8D, $04, $08, $8E, $05, $17, $8F, $05, $18, $16, $39, $26
	dc.b	$37, $36, $3B, $46, $3D, $56, $3C, $77, $7C, $FF, $00, $11
	dc.b	$EC, $F4, $B9, $7A, $5B, $3F, $5D, $00, $7F, $CC, $3F, $E6
	dc.b	$01, $5F, $EB, $0A, $FF, $58, $07, $FE, $C3, $F3, $7F, $7F
	dc.b	$91, $A5, $97, $45, $97, $45, $00, $00, $03, $FD, $00, $00
	dc.b	$7E, $20, $25, $A5, $AA, $DD, $4D, $D1, $C4, $DC, $BE, $ED
	dc.b	$95, $CD, $42, $3B, $25, $3A, $32, $2F, $C0, $00, $84, $80
	dc.b	$B3, $62, $D1, $56, $67, $B3, $D4, $B4, $C2, $CC, $7A, $73
	dc.b	$76, $95, $A6, $4E, $92, $E8, $E6, $BC, $25, $B7, $CC, $55
	dc.b	$A9, $E6, $11, $44, $F0, $F8, $00, $7C, $3C, $BC, $4A, $B8
	dc.b	$07, $C1, $D2, $31, $08, $F8, $64, $A8, $47, $BA, $2C, $63
	dc.b	$C8, $00, $02, $DB, $80, $01, $E8, $00, $1B, $57, $9C, $53
	dc.b	$A3, $22, $B6, $5B, $3D, $71, $D6, $CD, $4D, $2C, $6B, $15
	dc.b	$2F, $52, $C8, $A0, $05, $B9, $00, $02, $79, $0D, $BF, $65
	dc.b	$95, $FD, $E8, $19, $5E, $C3, $F6, $5B, $7E, $F7, $0C, $B3
	dc.b	$57, $74, $83, $E0, $00, $A8, $C9, $7C, $79, $4E, $98, $47
	dc.b	$19, $15, $29, $14, $F4, $00, $4A, $46, $4C, $00, $02, $A2
	dc.b	$80, $06, $AA, $55, $A5, $6F, $D8, $00, $1B, $DC, $00, $33
	dc.b	$16, $AB, $BF, $1D, $B2, $E9, $44, $59, $74, $64, $50, $D7
	dc.b	$A0, $1A, $54, $A4, $5B, $72, $DA, $DC, $02, $CA, $8E, $8C
	dc.b	$BC, $78, $B8, $00, $95, $47, $95, $6E, $31, $B2, $F3, $C3
	dc.b	$25, $42, $E5, $74, $F7, $DE, $E0, $1C, $EB, $BE, $1A, $62
	dc.b	$A5, $C3, $2A, $8E, $8C, $BA, $F5, $79, $00, $B2, $A3, $CA
	dc.b	$B6, $B9, $D2, $EE, $00, $69, $52, $2D, $CB, $71, $FB, $2D
	dc.b	$BF, $64, $00, $00, $08, $F2, $B1, $67, $BD, $AA, $36, $E5
	dc.b	$B6, $74, $C4, $D3, $CB, $00, $4C, $24, $02, $34, $B5, $5B
	dc.b	$A9, $BE, $BB, $BC, $6F, $D6, $2F, $B3, $31, $6B, $EE, $D9
	dc.b	$5C, $D4, $23, $B2, $53, $F8, $B1, $37, $C0, $4B, $62, $D1
	dc.b	$56, $67, $B3, $D6, $7E, $75, $88, $D9, $98, $9E, $6E, $D2
	dc.b	$B4, $C9, $D2, $5F, $5B, $BF, $0F, $CE, $62, $91, $B7, $2C
	dc.b	$D1, $19, $7C, $53, $BE, $62, $62, $DC, $B9, $6F, $83, $25
	dc.b	$61, $D2, $08, $47, $EE, $55, $FC, $BC, $00, $1C, $C5, $A3
	dc.b	$11, $67, $0C, $B4, $43, $69, $F1, $4E, $F5, $A8, $98, $48
	dc.b	$F0, $03, $0E, $90, $45, $B9, $8B, $42, $3B, $25, $3A, $32
	dc.b	$2B, $65, $B3, $D7, $1D, $6C, $D4, $DC, $6E, $BC, $36, $D0
	dc.b	$B6, $67, $B3, $D4, $B2, $28, $19, $EC, $00, $0C, $67, $B0
	dc.b	$00, $38, $C0, $00, $0B, $6E, $57, $8E, $C0, $0D, $A9, $23
	dc.b	$38, $CA, $EE, $00, $52, $42, $2E, $BD, $00, $0D, $2A, $2F
	dc.b	$6C, $8C, $00, $4A, $A2, $E1, $52, $E3, $25, $42, $E5, $74
	dc.b	$F7, $DE, $E1, $BB, $77, $A5, $69, $BC, $B4, $C5, $4B, $86
	dc.b	$56, $D1, $85, $B6, $11, $C7, $48, $29, $19, $D2, $17, $8F
	dc.b	$62, $F8, $B3, $DD, $E5, $60, $00, $C7, $8F, $67, $BB, $E3
	dc.b	$F5, $D8, $85, $D2, $AA, $80, $00, $01, $97, $95, $8D, $3E
	dc.b	$F7, $CE, $11, $E5, $D2, $26, $91, $84, $FC, $42, $A7, $D1
	dc.b	$53, $E8, $A9, $F5, $53, $EA, $A7, $DF, $C4, $2F, $F2, $3F
	dc.b	$09, $F8, $7B, $D9, $95, $2E, $E9, $00, $1E, $34, $AB, $59
	dc.b	$6F, $AC, $75, $8B, $EC, $CC, $01, $C3, $6F, $B3, $2A, $5D
	dc.b	$52, $F8, $00, $F5, $A5, $5A, $CF, $7C, $F5, $88, $D9, $98
	dc.b	$09, $F9, $48, $D0, $F2, $F1, $8A, $75, $B3, $45, $F0, $07
	dc.b	$C0, $95, $7F, $2F, $00, $7B, $13, $51, $B3, $C3, $66, $B1
	dc.b	$0F, $B3, $00, $9F, $88, $54, $FB, $FD, $80, $00, $FF, $C7
	dc.b	$FE, $00, $00
	even

SplashLogoTilemap:
	dc.b	$07, $03, $00, $00, $00, $05, $0E, $40, $0F, $92, $08, $02
	dc.b	$80, $33, $82, $19, $0E, $08, $44, $78, $01, $84, $E0, $95
	dc.b	$0F, $82, $19, $3E, $20, $60, $88, $5C, $42, $A9, $50, $F8
	dc.b	$21, $93, $E0, $06, $1B, $82, $9C, $1E, $08, $64, $F8, $01
	dc.b	$81, $E0, $10, $1B, $82, $19, $3E, $40, $60, $8E, $6C, $1E
	dc.b	$21, $54, $A8, $1C, $02, $00, $71, $48, $A1, $93, $E0, $06
	dc.b	$A2, $11, $82, $12, $E0, $15, $07, $80, $40, $1E, $08, $64
	dc.b	$F8, $81, $97, $41, $70, $5B, $89, $C1, $0C, $98, $5C, $02
	dc.b	$00, $F0, $C4, $85, $C4, $20, $C3, $47, $84, $11, $10, $63
	dc.b	$13, $38, $32, $D1, $E1, $84, $A3, $00, $99, $01, $E1, $80
	dc.b	$FE, $00
	even

; ----------------------------------------------------------------------