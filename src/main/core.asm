; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Main CPU core file
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

	include	"main/_mcd_main.inc"
	include	"main/_ram.inc"
	
; ----------------------------------------------------------------------
; Header
; ----------------------------------------------------------------------

	include	"main/header.asm"

; ----------------------------------------------------------------------
; Program
; ----------------------------------------------------------------------

	include	"main/function_table.asm"
	include	"main/call_table.asm"
	include	"main/interrupt.asm"
	include	"main/vdp.asm"
	include	"main/controller.asm"
	include	"main/z80.asm"
	include	"main/communication.asm"
	include	"main/memory.asm"
	include	"main/decompress.asm"
	include	"main/math.asm"
	include	"main/object.asm"
	include	"main/main.asm"
	include	"main/control_panel.asm"
	include	"main/splash.asm"

; ----------------------------------------------------------------------
; Sub CPU program
; ----------------------------------------------------------------------
; It is vital for this data to appear at exactly this address, as
; software that uses the Mega CD in 'Mode 1' will try to manually load
; the Sub CPU program from here!
; ----------------------------------------------------------------------

	dcb.b	$16000-*, $FF
SubCpuBios:
	incbin	"out/subbios.kos"

; ----------------------------------------------------------------------
; Padding
; ----------------------------------------------------------------------

	dcb.b	$20000-*, $FF

; ----------------------------------------------------------------------
