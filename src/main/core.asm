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

	include	"include/mcd_main.inc"
	include	"src/main/variables.inc"
	
; ------------------------------------------------------------------------------
; Header
; ------------------------------------------------------------------------------

	include	"src/main/header.asm"

; ------------------------------------------------------------------------------
; Program
; ------------------------------------------------------------------------------

	include	"src/main/function_table.asm"
	include	"src/main/call_table.asm"
	include	"src/main/interrupt.asm"
	include	"src/main/vdp.asm"
	include	"src/main/controller.asm"
	include	"src/main/z80.asm"
	include	"src/main/communication.asm"
	include	"src/main/memory.asm"
	include	"src/main/decompress.asm"
	include	"src/main/math.asm"
	include	"src/main/object.asm"
	include	"src/main/main.asm"
	include	"src/main/control_panel.asm"
	include	"src/main/splash.asm"

; ------------------------------------------------------------------------------
; Sub CPU program
; ------------------------------------------------------------------------------
; It is vital for this data to appear at exactly this address, as
; software that uses the Mega CD in 'Mode 1' will try to manually load
; the Sub CPU program from here!
; ------------------------------------------------------------------------------

	dcb.b	$16000-*, $FF
SubCpuBios:
	incbin	"out/sub_bios.kos"

; ------------------------------------------------------------------------------
; Padding
; ------------------------------------------------------------------------------

	dcb.b	$20000-*, $FF

; ------------------------------------------------------------------------------
