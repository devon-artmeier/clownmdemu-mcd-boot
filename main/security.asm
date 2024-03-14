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
	add.w	(a1)+,d3				; Compute checksum
	dbf	d1,.CheckLoop

	cmp.w	d2,d3
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