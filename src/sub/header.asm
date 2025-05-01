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
; Vector table
; ------------------------------------------------------------------------------

	dc.l	stack_base					; Stack pointer
	dc.l	HardResetEntry					; Reset

	dc.l	ExceptionEntry					; Bus error
	dc.l	_ADRERR						; Address error
	dc.l	_CODERR						; Illegal instruction
	dc.l	_DIVERR						; Division by zero
	dc.l	_CHKERR						; CHK exception
	dc.l	_TRPERR						; TRAPV exception
	dc.l	_SPVERR						; Privilege violation
	dc.l	_TRACE						; TRACE exception
	dc.l	_NOCOD0						; Line A emulator
	dc.l	_NOCOD1						; Line F emulator

	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved

	dc.l	ExceptionEntry					; Spurious exception
	dc.l	_LEVEL1						; IRQ1 (graphics interrupt)
	dc.l	_LEVEL2						; IRQ2 (Mega Drive interrupt)
	dc.l	_LEVEL3						; IRQ3 (timer interrupt)
	dc.l	_LEVEL4						; IRQ4 (CDD interrupt)
	dc.l	_LEVEL5						; IRQ5 (CDC interrupt)
	dc.l	_LEVEL6						; IRQ6 (Subcode interrupt)
	dc.l	_LEVEL7						; IRQ7

	dc.l	_TRAP00						; TRAP #00 exception
	dc.l	_TRAP01						; TRAP #01 exception
	dc.l	_TRAP02						; TRAP #02 exception
	dc.l	_TRAP03						; TRAP #03 exception
	dc.l	_TRAP04						; TRAP #04 exception
	dc.l	_TRAP05						; TRAP #05 exception
	dc.l	_TRAP06						; TRAP #06 exception
	dc.l	_TRAP07						; TRAP #07 exception
	dc.l	_TRAP08						; TRAP #08 exception
	dc.l	_TRAP09						; TRAP #09 exception
	dc.l	_TRAP10						; TRAP #10 exception
	dc.l	_TRAP11						; TRAP #11 exception
	dc.l	_TRAP12						; TRAP #12 exception
	dc.l	_TRAP13						; TRAP #13 exception
	dc.l	_TRAP14						; TRAP #14 exception
	dc.l	_TRAP15						; TRAP #15 exception

	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved
	dc.l	ExceptionEntry					; Reserved

; ------------------------------------------------------------------------------
; Header
; ------------------------------------------------------------------------------

	dc.b	"SEGA CD         "
	dc.b	"DEVON   2024.MAR"
	dc.b	"CD-ROM BIOS        CLOWNMDEMU              1.00 "
	dc.b	"CD-ROM BIOS                                     "
	dc.b	"BR  CLOWN-1.00"
	dc.w	0
	dc.b	"                "
	dc.l	0, $57FF
	dc.l	$5800, $7FFFF
	dc.b	"RA", $F8, $20
	dc.l	$FE0001, $FE3FFF
	dc.b	"            "
	dc.b	"                                        "
	dc.b	"JUE             "

; ------------------------------------------------------------------------------
; Hard reset entry point
; ------------------------------------------------------------------------------

HardResetEntry:
	bra.w	HardReset

; ------------------------------------------------------------------------------
; Exception entry point
; ------------------------------------------------------------------------------

ExceptionEntry:
	bra.w	Exception

; ------------------------------------------------------------------------------