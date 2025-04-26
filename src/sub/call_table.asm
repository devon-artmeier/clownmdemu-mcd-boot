; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Sub CPU call table functions
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
; Generic exception
; ----------------------------------------------------------------------

Exception:
	lea	stackBase,sp				; Reset stack pointer
	bra.w	HardReset				; Reset program

; ----------------------------------------------------------------------
; Null exception
; ----------------------------------------------------------------------

NullException:
	rte

; ----------------------------------------------------------------------
; Set up call table
; ----------------------------------------------------------------------

SetupCallTable:
	lea	_SETJMPTBL,a0				; Call table in RAM
	move.w	#$4EF9,d0				; JMP opcode
	
	move.w	d0,(a0)+				; Set module setup
	move.l	#SetupModule,(a0)+

	move.w	d0,(a0)+				; Set VSync
	move.l	#VSync,(a0)+
	
	lea	.End(pc),a1				; Set callers
	moveq	#7-1,d1
	bsr.s	.SetJumps

	lea	Exception(pc),a1			; Set error exceptions
	moveq	#9-1,d1
	bsr.s	.SetJumps

	lea	NullException(pc),a1			; Set TRAPS and interrupts
	move.w	d0,(a0)+
	move.l	a1,(a0)+
	move.w	d0,(a0)+
	move.l	#MDInterrupt,(a0)+
	moveq	#(5+16)-1,d1
	
; ----------------------------------------------------------------------

.SetJumps:
	move.w	d0,(a0)+				; Set opcode
	move.l	a1,(a0)+				; Set address
	dbf	d1,.SetJumps				; Loop until finished

.End:
	rts

; ----------------------------------------------------------------------