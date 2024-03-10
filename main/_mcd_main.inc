; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Mega CD Main CPU definitions
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
; Addresses
; ----------------------------------------------------------------------

BOOT_ROM		equ $000000			; Boot ROM
PRG_RAM			equ $020000			; Program RAM window
WORD_RAM		equ $200000			; Word RAM
CARTRIDGE		equ $400000			; Cartridge
Z80_RAM			equ $A00000			; Z80 RAM
VERSION			equ $A10001			; Hardware version
IO_DATA_1		equ $A10003			; I/O data port 1
IO_DATA_2		equ $A10005			; I/O data port 2
IO_DATA_3		equ $A10007			; I/O data port 3
IO_CTRL_1		equ $A10009			; I/O control port 1
IO_CTRL_2		equ $A1000B			; I/O control port 2
IO_CTRL_3		equ $A1000D			; I/O control port 3
Z80_BUS			equ $A11100			; Z80 bus control port
Z80_RESET		equ $A11200			; Z80 reset control port
GA_IRQ2			equ $A12000			; Sub CPU IRQ2 trigger
GA_RESET		equ $A12001			; Reset
GA_PROTECT		equ $A12002			; Write protection
GA_MEMORY_MODE		equ $A12003			; Memory mode
GA_CDC_MODE		equ $A12004			; CDC mode/device destination
GA_HBLANK		equ $A12006			; H-BLANK interrupt handler
GA_CDC_HOST		equ $A12008			; CDC host data
GA_STOPWATCH		equ $A1200C			; Stopwatch
GA_MAIN_FLAG		equ $A1200E			; Main CPU flag
GA_SUB_FLAG		equ $A1200F			; Sub CPU flag
GA_COMM_CMD_0		equ $A12010			; Communication command 0
GA_COMM_CMD_1		equ $A12012			; Communication command 1
GA_COMM_CMD_2		equ $A12014			; Communication command 2
GA_COMM_CMD_3		equ $A12016			; Communication command 3
GA_COMM_CMD_4		equ $A12018			; Communication command 4
GA_COMM_CMD_5		equ $A1201A			; Communication command 5
GA_COMM_CMD_6		equ $A1201C			; Communication command 6
GA_COMM_CMD_7		equ $A1201E			; Communication command 7
GA_COMM_STAT_0		equ $A12020			; Communication status 0
GA_COMM_STAT_1		equ $A12022			; Communication status 1
GA_COMM_STAT_2		equ $A12024			; Communication status 2
GA_COMM_STAT_3		equ $A12026			; Communication status 3
GA_COMM_STAT_4		equ $A12028			; Communication status 4
GA_COMM_STAT_5		equ $A1202A			; Communication status 5
GA_COMM_STAT_6		equ $A1202C			; Communication status 6
GA_COMM_STAT_7		equ $A1202E			; Communication status 7
TMSS_SEGA		equ $A14000			; TMSS "SEGA" register
VDP_DATA		equ $C00000			; VDP data port
VDP_CTRL		equ $C00004			; VDP control port
PSG_CTRL		equ $C00011			; PSG control port
WORK_RAM		equ $FFFF0000			; Work RAM
EXCEPT			equ $FFFFFD00			; Exception
VBLANK_INT		equ $FFFFFD06			; V-BLANK interrupt
HBLANK_INT		equ $FFFFFD0C			; H-BLANK interrupt
EXT_INT			equ $FFFFFD12			; External interrupt
TRAP_00			equ $FFFFFD18			; TRAP #00
TRAP_01			equ $FFFFFD1E			; TRAP #01
TRAP_02			equ $FFFFFD24			; TRAP #02
TRAP_03			equ $FFFFFD2A			; TRAP #03
TRAP_04			equ $FFFFFD30			; TRAP #04
TRAP_05			equ $FFFFFD36			; TRAP #05
TRAP_06			equ $FFFFFD3C			; TRAP #06
TRAP_07			equ $FFFFFD42			; TRAP #07
TRAP_08			equ $FFFFFD48			; TRAP #08
TRAP_09			equ $FFFFFD4E			; TRAP #09
TRAP_10			equ $FFFFFD54			; TRAP #10
TRAP_11			equ $FFFFFD5A			; TRAP #11
TRAP_12			equ $FFFFFD60			; TRAP #12
TRAP_13			equ $FFFFFD66			; TRAP #13
TRAP_14			equ $FFFFFD6C			; TRAP #14
TRAP_15			equ $FFFFFD72			; TRAP #15
CHK_ERROR		equ $FFFFFD78			; CHK exception
ADDRESS_ERROR		equ $FFFFFD7E			; Address error
INSTRUCTION_ERROR	equ $FFFFFD7E			; Illegal instruction
DIVISION_ERROR		equ $FFFFFD84			; Division by zero
TRAPV_EXCEPT		equ $FFFFFD8A			; TRAPV
LINE_A_EXCEPT		equ $FFFFFD90			; Line A emulator
LINE_F_EXCEPT		equ $FFFFFD96			; Line F emulator
PRIVILEGE_ERROR		equ $FFFFFD9C			; Privilege violation
TRACE_EXCEPT		equ $FFFFFDA2			; TRACE exception
VBLANK_USER		equ $FFFFFDA8			; User V-BLANK interrupt
BURAM_CALL		equ $FFFFFDAE			; Cartridge Backup RAM handler

; ----------------------------------------------------------------------