; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU header and vector table
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
; Vector table
; ----------------------------------------------------------------------

	dc.l	stackBase				; Stack pointer
	dc.l	HardReset				; Reset

	dc.l	Exception				; Bus error
	dc.l	ADDRESS_ERROR				; Address error
	dc.l	INSTRUCTION_ERROR			; Illegal instruction
	dc.l	DIVISION_ERROR				; Division by zero error
	dc.l	CHK_ERROR				; CHK out of bounds error
	dc.l	TRAPV_EXCEPT				; TRAPV exception
	dc.l	PRIVILEGE_ERROR				; Privilege violation error
	dc.l	TRACE_EXCEPT				; TRACE exception
	dc.l	LINE_A_EXCEPT				; Line A emulator exception
	dc.l	LINE_F_EXCEPT				; Line F emulator exception

	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved

	dc.l	Exception				; Spurious exception
	dc.l	Exception				; IRQ1
	dc.l	EXT_INT					; IRQ2 (external interrupt)
	dc.l	Exception				; IRQ3
	dc.l	HBLANK_INT				; IRQ4 (H-BLANK interrupt)
	dc.l	Exception				; IRQ5
	dc.l	VBLANK_INT				; IRQ6 (V-BLANK interrupt)
	dc.l	Exception				; IRQ7

	dc.l	TRAP_00					; TRAP #00 exception
	dc.l	TRAP_01					; TRAP #01 exception
	dc.l	TRAP_02					; TRAP #02 exception
	dc.l	TRAP_03					; TRAP #03 exception
	dc.l	TRAP_04					; TRAP #04 exception
	dc.l	TRAP_05					; TRAP #05 exception
	dc.l	TRAP_06					; TRAP #06 exception
	dc.l	TRAP_07					; TRAP #07 exception
	dc.l	TRAP_08					; TRAP #08 exception
	dc.l	TRAP_09					; TRAP #09 exception
	dc.l	TRAP_10					; TRAP #10 exception
	dc.l	TRAP_11					; TRAP #11 exception
	dc.l	TRAP_12					; TRAP #12 exception
	dc.l	TRAP_13					; TRAP #13 exception
	dc.l	TRAP_14					; TRAP #14 exception
	dc.l	TRAP_15					; TRAP #15 exception

	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved
	dc.l	Exception				; Reserved

; ----------------------------------------------------------------------
; Header
; ----------------------------------------------------------------------

	dc.b	"SEGA MEGA DRIVE "
	dc.b	"DEVON   2024.MAR"
	dc.b	"MEGA-CD BOOT ROM   CLOWNMDEMU              1.00 "
	dc.b	"MEGA-CD BOOT ROM                                "
	dc.b	"BR  CLOWN-1.00"
	dc.w	0
	dc.b	"J               "
	dc.l	$000000, $1FFFFF
	dc.l	$FF0000, $FFFFFF
	dc.b	"            "
	dc.b	"            "
	dc.b	"                                        "
	dc.b	"JUE             "

; ----------------------------------------------------------------------