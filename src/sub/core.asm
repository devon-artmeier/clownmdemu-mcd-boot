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

	include	"include/mcd_sub.inc"
	include	"src/sub/variables.inc"
	
; ------------------------------------------------------------------------------
; Header
; ------------------------------------------------------------------------------

	include	"src/sub/header.asm"

; ------------------------------------------------------------------------------
; Program
; ------------------------------------------------------------------------------

	include	"src/sub/call_table.asm"
	include	"src/sub/interrupt.asm"
	include	"src/sub/module.asm"
	include	"src/sub/pcm.asm"
	include	"src/sub/main.asm"
	
; ------------------------------------------------------------------------------
; Padding
; ------------------------------------------------------------------------------

	dcb.b	$5800-*, $FF

; ------------------------------------------------------------------------------