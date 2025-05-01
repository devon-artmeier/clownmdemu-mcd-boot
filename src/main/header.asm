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
	dc.l	HardReset					; Reset

	dc.l	Exception					; Bus error
	dc.l	_ADRERR						; Address error
	dc.l	_CODERR						; Illegal instruction
	dc.l	_DIVERR						; Division by zero
	dc.l	_CHKERR						; CHK exception
	dc.l	_TRPERR						; TRAPV exception
	dc.l	_SPVERR						; Privilege violation
	dc.l	_TRACE						; TRACE exception
	dc.l	_NOCOD0						; Line A emulator
	dc.l	_NOCOD1						; Line F emulator

	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved

	dc.l	Exception					; Spurious exception
	dc.l	Exception					; IRQ1
	dc.l	_LEVEL2						; IRQ2 (external interrupt)
	dc.l	Exception					; IRQ3
	dc.l	_LEVEL4						; IRQ4 (H-BLANK interrupt)
	dc.l	Exception					; IRQ5
	dc.l	_LEVEL6						; IRQ6 (V-BLANK interrupt)
	dc.l	Exception					; IRQ7

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

	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved
	dc.l	Exception					; Reserved

; ------------------------------------------------------------------------------
; Header
; ------------------------------------------------------------------------------

	dc.b	"SEGA MEGA DRIVE "
	dc.b	"DEVON   2024.MAR"
	dc.b	"MEGA-CD BOOT ROM   CLOWNMDEMU              1.00 "
	dc.b	"MEGA-CD BOOT ROM                                "
	dc.b	"BR  CLOWN-1.00"
	dc.w	0
	dc.b	"J               "
	dc.l	0, $1FFFFF
	dc.l	$FF0000, $FFFFFF
	dc.b	"            "
	dc.b	"            "
	dc.b	"                                        "
	dc.b	"JUE             "

; ------------------------------------------------------------------------------