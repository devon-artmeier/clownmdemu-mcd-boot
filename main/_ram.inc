; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU RAM definitions
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

OBJECT_SLOTS		equ 80				; Number of object slots

; ----------------------------------------------------------------------
; Object slot
; ----------------------------------------------------------------------

objID			equ $00				; Object ID
objSprFlags		equ $02				; Sprite flags
objSprite		equ $04				; Sprite data
objX			equ $08				; X position
objY			equ $0C				; Y position
objXSpeed		equ $10				; X speed
objYSpeed		equ $14				; Y speed
objSprTile		equ $18				; Sprite tile ID
objSprFlip		equ $19				; Flag affected by sprite flip
objAnimFrame		equ $20				; Animation frame
objAnimTime		equ $21				; Animation timer
objPalCycle		equ $26				; Palette cycle offset
objMoveTime		equ $28				; Movement timer
objLength		equ $40				; Length of structure

; ----------------------------------------------------------------------
; RAM definitions
; ----------------------------------------------------------------------

objects			equ WORK_RAM+$C000		; Object slots
decompBuffer		equ WORK_RAM+$E000		; Decompression buffer
nemBuffer		equ WORK_RAM+$F700		; Nemesis decompression buffer
sprites			equ WORK_RAM+$F900		; Sprite data buffer
palette			equ WORK_RAM+$FB80		; Palette data buffer
stack			equ WORK_RAM+$FC00		; Stack
stackBase		equ WORK_RAM+$FD00		; Stack base
vdpReg00		equ WORK_RAM+$FDB4		; VDP register #00 cache
vdpReg01		equ WORK_RAM+$FDB6		; VDP register #01 cache
vdpReg02		equ WORK_RAM+$FDB8		; VDP register #02 cache
vdpReg03		equ WORK_RAM+$FDBA		; VDP register #03 cache
vdpReg04		equ WORK_RAM+$FDBC		; VDP register #04 cache
vdpReg05		equ WORK_RAM+$FDBE		; VDP register #05 cache
vdpReg06		equ WORK_RAM+$FDC0		; VDP register #06 cache
vdpReg07		equ WORK_RAM+$FDC2		; VDP register #07 cache
vdpReg08		equ WORK_RAM+$FDC4		; VDP register #08 cache
vdpReg09		equ WORK_RAM+$FDC6		; VDP register #09 cache
vdpReg0A		equ WORK_RAM+$FDC8		; VDP register #0A cache
vdpReg0B		equ WORK_RAM+$FDCA		; VDP register #0B cache
vdpReg0C		equ WORK_RAM+$FDCC		; VDP register #0C cache
vdpReg0D		equ WORK_RAM+$FDCE		; VDP register #0D cache
vdpReg0E		equ WORK_RAM+$FDD0		; VDP register #0E cache
vdpReg0F		equ WORK_RAM+$FDD2		; VDP register #0F cache
vdpReg10		equ WORK_RAM+$FDD4		; VDP register #10 cache
vdpReg11		equ WORK_RAM+$FDD6		; VDP register #11 cache
vdpReg12		equ WORK_RAM+$FDD8		; VDP register #12 cache
ctrlHoldP1		equ WORK_RAM+$FE20		; Player 1 controller data (held buttons)
ctrlTapP1		equ WORK_RAM+$FE21		; Player 1 controller data (tapped buttons)
ctrlHoldP2		equ WORK_RAM+$FE22		; Player 2 controller data (held buttons)
ctrlTapP2		equ WORK_RAM+$FE23		; Player 2 controller data (tapped buttons)
ctrlTimerP1		equ WORK_RAM+$FE24		; Player 1 controller directional pad timer
ctrlTimerP2		equ WORK_RAM+$FE25		; Player 2 controller directional pad timer
vblankFlags		equ WORK_RAM+$FE26		; V-BLANK handler flags
vblankUpdatesOff	equ WORK_RAM+$FE28		; V-BLANK handler update disable flag
cramUpdate		equ WORK_RAM+$FE29		; CRAM update flag
rngSeed			equ WORK_RAM+$FE2A		; Random number generator seed
fontTile		equ WORK_RAM+$FE2C		; Font tile properties
planeStride		equ WORK_RAM+$FE2E		; VDP plane stride
objSpriteSlot		equ WORK_RAM+$FE30		; Current object sprite slot
objIndexTable		equ WORK_RAM+$FE34		; Object index table
objSpriteLink		equ WORK_RAM+$FE38		; Current object sprite link
palFadeInOffset		equ WORK_RAM+$FE46		; Palette fade in offset
palFadeInLength		equ WORK_RAM+$FE47		; Palette fade in length
palFadeInIntensity	equ WORK_RAM+$FE48		; Palette fade in intensity
palFadeInData		equ WORK_RAM+$FE4A		; Palette fade in data
timeMinuend		equ WORK_RAM+$FE4E		; Time subtraction minuend
timeSubtrahend		equ WORK_RAM+$FE50		; Time subtraction subtrahend

; ----------------------------------------------------------------------