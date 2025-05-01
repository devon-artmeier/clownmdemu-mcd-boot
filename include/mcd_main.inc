; ------------------------------------------------------------------------------
; Copyright (c) 2025 Devon Artmeier
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
; Addresses
; ----------------------------------------------------------------------

BIOS			equ 0					; Boot ROM
PRG_RAM			equ $20000				; Program RAM window
WORD_RAM_1M		equ $200000				; Word RAM (1M/1M)
WORD_RAM_2M		equ $200000				; Word RAM (2M)
CARTRIDGE		equ $400000				; Cartridge
Z80_RAM			equ $A00000				; Z80 RAM
VERSION			equ $A10001				; Hardware version
IO_DATA_1		equ $A10003				; I/O data port 1
IO_DATA_2		equ $A10005				; I/O data port 2
IO_DATA_3		equ $A10007				; I/O data port 3
IO_CTRL_1		equ $A10009				; I/O control port 1
IO_CTRL_2		equ $A1000B				; I/O control port 2
IO_CTRL_3		equ $A1000D				; I/O control port 3
Z80_BUS			equ $A11100				; Z80 bus control port
Z80_RESET		equ $A11200				; Z80 reset control port
MCD_IRQ2		equ $A12000				; Sub CPU IRQ2 trigger
MCD_RESET		equ $A12001				; Reset
MCD_PROTECT		equ $A12002				; Write protection
MCD_MEM_MODE		equ $A12003				; Memory mode
MCD_CDC_MODE		equ $A12004				; CDC mode/device destination
MCD_HBLANK		equ $A12006				; H-BLANK interrupt handler
MCD_CDC_HOST		equ $A12008				; CDC host data
MCD_STOPWATCH		equ $A1200C				; Stopwatch
MCD_MAIN_FLAG		equ $A1200E				; Main CPU communication flag
MCD_SUB_FLAG		equ $A1200F				; Sub CPU communication flag
MCD_MAIN_COMM_0		equ $A12010				; Main CPU communication register 0
MCD_MAIN_COMM_1		equ $A12011				; Main CPU communication register 1
MCD_MAIN_COMM_2		equ $A12012				; Main CPU communication register 2
MCD_MAIN_COMM_3		equ $A12013				; Main CPU communication register 3
MCD_MAIN_COMM_4		equ $A12014				; Main CPU communication register 4
MCD_MAIN_COMM_5		equ $A12015				; Main CPU communication register 5
MCD_MAIN_COMM_6		equ $A12016				; Main CPU communication register 6
MCD_MAIN_COMM_7		equ $A12017				; Main CPU communication register 7
MCD_MAIN_COMM_8		equ $A12018				; Main CPU communication register 8
MCD_MAIN_COMM_9		equ $A12019				; Main CPU communication register 9
MCD_MAIN_COMM_10	equ $A1201A				; Main CPU communication register 10
MCD_MAIN_COMM_11	equ $A1201B				; Main CPU communication register 11
MCD_MAIN_COMM_12	equ $A1201C				; Main CPU communication register 12
MCD_MAIN_COMM_13	equ $A1201D				; Main CPU communication register 13
MCD_MAIN_COMM_14	equ $A1201E				; Main CPU communication register 14
MCD_MAIN_COMM_15	equ $A1201F				; Main CPU communication register 15
MCD_SUB_COMM_0		equ $A12020				; Sub CPU communication register 0
MCD_SUB_COMM_1		equ $A12021				; Sub CPU communication register 1
MCD_SUB_COMM_2		equ $A12022				; Sub CPU communication register 2
MCD_SUB_COMM_3		equ $A12023				; Sub CPU communication register 3
MCD_SUB_COMM_4		equ $A12024				; Sub CPU communication register 4
MCD_SUB_COMM_5		equ $A12025				; Sub CPU communication register 5
MCD_SUB_COMM_6		equ $A12026				; Sub CPU communication register 6
MCD_SUB_COMM_7		equ $A12027				; Sub CPU communication register 7
MCD_SUB_COMM_8		equ $A12028				; Sub CPU communication register 8
MCD_SUB_COMM_9		equ $A12029				; Sub CPU communication register 9
MCD_SUB_COMM_10		equ $A1202A				; Sub CPU communication register 10
MCD_SUB_COMM_11		equ $A1202B				; Sub CPU communication register 11
MCD_SUB_COMM_12		equ $A1202C				; Sub CPU communication register 12
MCD_SUB_COMM_13		equ $A1202D				; Sub CPU communication register 13
MCD_SUB_COMM_14		equ $A1202E				; Sub CPU communication register 14
MCD_SUB_COMM_15		equ $A1202F				; Sub CPU communication register 15
TMSS_SEGA		equ $A14000				; TMSS "SEGA" register
VDP_DATA		equ $C00000				; VDP data port
VDP_CTRL		equ $C00004				; VDP control port
PSG_CTRL		equ $C00011				; PSG control port
WORK_RAM		equ $FFFF0000				; Work RAM
_EXCPT			equ $FFFFFD00				; Exception
_LEVEL6			equ $FFFFFD06				; V-BLANK interrupt
_LEVEL4			equ $FFFFFD0C				; H-BLANK interrupt
_LEVEL2			equ $FFFFFD12				; External interrupt
_TRAP00			equ $FFFFFD18				; TRAP #00
_TRAP01			equ $FFFFFD1E				; TRAP #01
_TRAP02			equ $FFFFFD24				; TRAP #02
_TRAP03			equ $FFFFFD2A				; TRAP #03
_TRAP04			equ $FFFFFD30				; TRAP #04
_TRAP05			equ $FFFFFD36				; TRAP #05
_TRAP06			equ $FFFFFD3C				; TRAP #06
_TRAP07			equ $FFFFFD42				; TRAP #07
_TRAP08			equ $FFFFFD48				; TRAP #08
_TRAP09			equ $FFFFFD4E				; TRAP #09
_TRAP10			equ $FFFFFD54				; TRAP #10
_TRAP11			equ $FFFFFD5A				; TRAP #11
_TRAP12			equ $FFFFFD60				; TRAP #12
_TRAP13			equ $FFFFFD66				; TRAP #13
_TRAP14			equ $FFFFFD6C				; TRAP #14
_TRAP15			equ $FFFFFD72				; TRAP #15
_CHKERR			equ $FFFFFD78				; CHK exception
_ADRERR			equ $FFFFFD7E				; Address error
_CODERR			equ $FFFFFD7E				; Illegal instruction
_DIVERR			equ $FFFFFD84				; Division by zero
_TRPERR			equ $FFFFFD8A				; TRAPV
_NOCOD0			equ $FFFFFD90				; Line A emulator
_NOCOD1			equ $FFFFFD96				; Line F emulator
_SPVERR			equ $FFFFFD9C				; Privilege violation
_TRACE			equ $FFFFFDA2				; TRACE exception
_BURAM			equ $FFFFFDAE				; Cartridge Backup RAM handler

; ----------------------------------------------------------------------