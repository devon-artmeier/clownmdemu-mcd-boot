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
	bsr.w	SetDefaultVDPRegs			; Set VDP registers
	bsr.w	ClearVDPMemory				; Clear VDP memory
	bsr.w	ClearSprites				; Clear sprites
	bsr.w	LoadFontDefault				; Load font
	
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
	bsr.w	SecurityCheckRegion

	bsr.w	EnableDisplay				; Enable display

	moveq	#0,d1					; Wait for the V-BLANK handler
	bsr.w	Delay
	
	addq.w	#2,sp					; Deallocate security block type
	move.w	(sp)+,VBLANK_INT			; Restore V-BLANK handler
	move.l	(sp)+,VBLANK_INT+2
	rts
	
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
	even

; ----------------------------------------------------------------------