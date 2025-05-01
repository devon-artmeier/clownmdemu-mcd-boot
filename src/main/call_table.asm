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
; Set up call table in RAM
; ------------------------------------------------------------------------------

SetupCallTable:
	lea	_EXCPT,a0					; Call table in RAM
	move.w	#$4EF9,d0					; JMP opcode
	
	move.w	d0,(a0)+					; Set exception
	move.l	#SoftReset,(a0)+
	
	move.w	d0,(a0)+					; Set V-BLANK interrupt
	move.l	#VBlankIrq,(a0)+

	lea	NullException(pc),a1				; Set interrupts and TRAPs
	moveq	#(16+2)-1,d1
	bsr.s	.SetJumps
	
	lea	Exception(pc),a1				; Set exceptions
	moveq	#8-1,d1
	bsr.s	.SetJumps
	
	lea	.End(pc),a1					; Set the rest
	moveq	#2-1,d1
	
; ------------------------------------------------------------------------------

.SetJumps:
	move.w	d0,(a0)+					; Set opcode
	move.l	a1,(a0)+					; Set address
	dbf	d1,.SetJumps					; Loop until finished

.End:
	rts

; ------------------------------------------------------------------------------
; Generic exception
; ------------------------------------------------------------------------------

Exception:
	move.w	#$4EF9,_EXCPT					; Set exception target
	move.l	#SoftReset,_EXCPT+2
	lea	stack_base,sp					; Reset stack pointer
	bra.w	HardReset					; Reset program

; ------------------------------------------------------------------------------
; Null exception
; ------------------------------------------------------------------------------

NullException:
	rte

; ------------------------------------------------------------------------------