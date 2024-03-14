; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Sub CPU header and vector table
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
	dc.l	GRAPHICS_INT				; IRQ1 (graphics interrupt)
	dc.l	MEGA_DRIVE_INT				; IRQ2 (Mega Drive interrupt)
	dc.l	TIMER_INT				; IRQ3 (timer interrupt)
	dc.l	CDD_INT					; IRQ4 (CDD interrupt)
	dc.l	CDC_INT					; IRQ5 (CDC interrupt)
	dc.l	SUBCODE_INT				; IRQ6 (Subcode interrupt)
	dc.l	IRQ7					; IRQ7

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

	dc.b	"SEGA CD         "
	dc.b	"DEVON   2024.MAR"
	dc.b	"CD-ROM BIOS        CLOWNMDEMU              1.00 "
	dc.b	"CD-ROM BIOS                                     "
	dc.b	"BR  CLOWN-1.00"
	dc.w	0
	dc.b	"                "
	dc.l	$000000, $0057FF
	dc.l	$005800, $07FFFF
	dc.b	"RA", $F8, $20
	dc.l	$FE0001, $FE3FFF
	dc.b	"            "
	dc.b	"                                        "
	dc.b	"JUE             "

; ----------------------------------------------------------------------