; ----------------------------------------------------------------------
; Mega CD minimal boot ROM for clownmdemu
; ----------------------------------------------------------------------
; Mega CD Sub CPU definitions
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

PRG_RAM			equ $000000			; Program RAM
WORD_RAM_2M		equ $080000			; Word RAM (2M)
WORD_RAM_1M		equ $0C0000			; Word RAM (1M/1M)
BACKUP_RAM		equ $FE0000			; Backup RAM
PCM_ENV			equ $FF0001			; PCM volume
PCM_PAN			equ $FF0003			; PCM panning
PCM_FDL			equ $FF0005			; PCM frequency (low)
PCM_FDH			equ $FF0007			; PCM frequency (high)
PCM_LSL			equ $FF0009			; PCM wave loop address (low)
PCM_LSH			equ $FF000B			; PCM wave loop address (high)
PCM_ST			equ $FF000D			; PCM wave start address
PCM_CTRL		equ $FF000F			; PCM control
PCM_ENABLE		equ $FF0011			; PCM enable flags
PCM_ADDR_1L		equ $FF0021			; PCM1 wave address (low)
PCM_ADDR_1H		equ $FF0023			; PCM1 wave address (high)
PCM_ADDR_2L		equ $FF0025			; PCM2 wave address (low)
PCM_ADDR_2H		equ $FF0027			; PCM2 wave address (high)
PCM_ADDR_3L		equ $FF0029			; PCM3 wave address (low)
PCM_ADDR_3H		equ $FF002B			; PCM3 wave address (high)
PCM_ADDR_4L		equ $FF002D			; PCM4 wave address (low)
PCM_ADDR_4H		equ $FF002F			; PCM4 wave address (high)
PCM_ADDR_5L		equ $FF0031			; PCM5 wave address (low)
PCM_ADDR_5H		equ $FF0033			; PCM5 wave address (high)
PCM_ADDR_6L		equ $FF0035			; PCM6 wave address (low)
PCM_ADDR_6H		equ $FF0037			; PCM6 wave address (high)
PCM_ADDR_7L		equ $FF0039			; PCM7 wave address (low)
PCM_ADDR_7H		equ $FF003B			; PCM7 wave address (high)
PCM_ADDR_8L		equ $FF003D			; PCM8 wave address (low)
PCM_ADDR_8H		equ $FF003F			; PCM8 wave address (high)
PCM_WAVE		equ $FF2001			; PCM wave RAM
GA_LED			equ $FFFF8000			; LED control
GA_RESET		equ $FFFF8001			; Reset
GA_PROTECT		equ $FFFF8002			; Write protection
GA_MEMORY_MODE		equ $FFFF8003			; Memory mode
GA_CDC_MODE		equ $FFFF8004			; CDC mode/device destination
GA_CDC_RS0		equ $FFFF8005			; CDC register address
GA_CDC_RS1		equ $FFFF8007			; CDC register data
GA_CDC_HOST		equ $FFFF8008			; CDC host data
GA_CDC_DMA		equ $FFFF800A			; CDC DMA address
GA_STOPWATCH		equ $FFFF800C			; Stopwatch
GA_MAIN_FLAG		equ $FFFF800E			; Main CPU flag
GA_SUB_FLAG		equ $FFFF800F			; Sub CPU flag
GA_COMM_CMD_0		equ $FFFF8010			; Communication command 0
GA_COMM_CMD_1		equ $FFFF8012			; Communication command 1
GA_COMM_CMD_2		equ $FFFF8014			; Communication command 2
GA_COMM_CMD_3		equ $FFFF8016			; Communication command 3
GA_COMM_CMD_4		equ $FFFF8018			; Communication command 4
GA_COMM_CMD_5		equ $FFFF801A			; Communication command 5
GA_COMM_CMD_6		equ $FFFF801C			; Communication command 6
GA_COMM_CMD_7		equ $FFFF801E			; Communication command 7
GA_COMM_STAT_0		equ $FFFF8020			; Communication status 0
GA_COMM_STAT_1		equ $FFFF8022			; Communication status 1
GA_COMM_STAT_2		equ $FFFF8024			; Communication status 2
GA_COMM_STAT_3		equ $FFFF8026			; Communication status 3
GA_COMM_STAT_4		equ $FFFF8028			; Communication status 4
GA_COMM_STAT_5		equ $FFFF802A			; Communication status 5
GA_COMM_STAT_6		equ $FFFF802C			; Communication status 6
GA_COMM_STAT_7		equ $FFFF802E			; Communication status 7
GA_IRQ3_TIME		equ $FFFF8031			; IRQ3 timer
GA_IRQ_MASK		equ $FFFF8033			; IRQ mask
GA_CD_FADER		equ $FFFF8034			; Fader control/spindle speed
GA_CDD_TYPE		equ $FFFF8036			; CDD data type
GA_CDD_CTRL		equ $FFFF8037			; CDD control
GA_CDD_STAT_0		equ $FFFF8038			; CDD status 0
GA_CDD_STAT_1		equ $FFFF8039			; CDD status 1
GA_CDD_STAT_2		equ $FFFF803A			; CDD status 2
GA_CDD_STAT_3		equ $FFFF803B			; CDD status 3
GA_CDD_STAT_4		equ $FFFF803C			; CDD status 4
GA_CDD_STAT_5		equ $FFFF803D			; CDD status 5
GA_CDD_STAT_6		equ $FFFF803E			; CDD status 6
GA_CDD_STAT_7		equ $FFFF803F			; CDD status 7
GA_CDD_STAT_8		equ $FFFF8040			; CDD status 8
GA_CDD_STAT_9		equ $FFFF8041			; CDD status 9
GA_CDD_CMD_0		equ $FFFF8042			; CDD command 0
GA_CDD_CMD_1		equ $FFFF8043			; CDD command 1
GA_CDD_CMD_2		equ $FFFF8044			; CDD command 2
GA_CDD_CMD_3		equ $FFFF8045			; CDD command 3
GA_CDD_CMD_4		equ $FFFF8046			; CDD command 4
GA_CDD_CMD_5		equ $FFFF8047			; CDD command 5
GA_CDD_CMD_6		equ $FFFF8048			; CDD command 6
GA_CDD_CMD_7		equ $FFFF8049			; CDD command 7
GA_CDD_CMD_8		equ $FFFF804A			; CDD command 8
GA_CDD_CMD_9		equ $FFFF804B			; CDD command 9
GA_1BPP_COLOR		equ $FFFF804C			; 1BPP decode color
GA_1BPP_OUT		equ $FFFF804E			; 1BPP output data
GA_1BPP_IN		equ $FFFF8056			; 1BPP input data
GA_STAMP_SIZE		equ $FFFF8058			; Stamp size/map size
GA_STAMP_MAP		equ $FFFF805A			; Stamp map address
GA_IMG_STRIDE		equ $FFFF805C			; Image stride
GA_IMG_TILE_OFF		equ $FFFF805E			; Image tile offset
GA_IMG_PIXEL_OFF	equ $FFFF8060			; Image pixel offset
GA_IMG_DRAW_W		equ $FFFF8062			; Image draw width
GA_IMG_DRAW_H		equ $FFFF8064			; Image draw height
GA_IMG_TRACE		equ $FFFF8066			; Image trace table
GA_SUBCODE_ADDR		equ $FFFF8068			; Subcode address
GA_SUBCODE_DATA		equ $FFFF8100			; Subcode data

; ----------------------------------------------------------------------
; BIOS function codes
; ----------------------------------------------------------------------

MSCSTOP			equ $02				; Stop CDDA music
MSCPAUSEON		equ $03				; Pause CDDA music
MSCPAUSEOFF		equ $04				; Unpase CDDA music
MSCSCANFF		equ $05				; Fast forward CDDA music
MSCSCANFR		equ $06				; Fast reverse CDDA music
MSCSCANOFF		equ $07				; Set CDDA music to normal speed
ROMPAUSEON		equ $08				; Pause data read
ROMPAUSEOFF		equ $09				; Unpase data read
DRVOPEN			equ $0A				; Open CD driver
DRVINIT			equ $10				; Close CD drive and initialize
MSCPLAY			equ $11				; Play CDDA music sequentially
MSCPLAY1		equ $12				; Play CDDA music once
MSCPLAYR		equ $13				; Loop CDDA music
MSCPLAYT		equ $14				; Play CDDA music sequentially from time
MSCSEEK			equ $15				; Seek to track
MSCSEEKT		equ $16				; Seek to time
ROMREAD			equ $17				; Start data read
ROMSEEK			equ $18				; Seek to sector
MSCSEEK1		equ $19				; Play CDDA music once from time
ROMREADN		equ $20				; Read number of sectors
ROMREADE		equ $21				; Read between 2 sectors
CDBCHK			equ $80				; Check if BIOS commands are done
CDBSTAT			equ $81				; Get BIOS status
CDBTOCWRITE		equ $82				; Write table of contents
CDBTOCREAD		equ $83				; Read table of contents
CDBPAUSE		equ $84				; Set standby mode timer
FDRSET			equ $85				; Set volume
FDRCHG			equ $86				; Fade to volume
CDCSTART		equ $87				; Start reading data
CDCSTARTP		equ $88				; Start reading data with CDC flags
CDCSTOP			equ $89				; Stop reading data
CDCSTAT			equ $8A				; Check if data is read
CDCREAD			equ $8B				; Start data transfer to host or DMA destination
CDCTRN			equ $8C				; Copy data from host
CDCACK			equ $8D				; Finish data transfer
SCDINIT			equ $8E				; Initialize subcode read
SCDSTART		equ $8F				; Start reading subcode data
SCDSTOP			equ $90				; Stop reading subcode data
SCDSTAT			equ $91				; Get subcode read staus
SCDREAD			equ $92				; Copy read subcode data to buffer
SCDPQ			equ $93				; Copy P/Q codes from subcode data
SCDPQL			equ $94				; Copy last P/Q codes from subcode data
LEDSET			equ $95				; Set LED mode
CDCSETMODE		equ $96				; Set CDC flags

; ----------------------------------------------------------------------
; Boot function codes
; ----------------------------------------------------------------------

CBTINIT			equ $00				; Initialize booting
CBTINT			equ $01				; Boot interrupt
CBTOPENDISC		equ $02				; Start CD drive open
CBTOPENSTAT		equ $03				; Check if the CD drive is open
CBTCHKDISC		equ $04				; Start check for bootable disc
CBTCHKSTAT		equ $05				; Check if disc is bootable
CBTIPDISC		equ $06				; Start loading initial program
CBTIPSTAT		equ $07				; Check if initial program is loaded
CBTSPDISC		equ $08				; Start loading system program
CBTSPSTAT		equ $09				; Check if system program is loaded

; ----------------------------------------------------------------------
; Backup RAM function codes
; ----------------------------------------------------------------------

BRMINIT			equ $00				; Initialize Backup RAM management
BRMSTAT			equ $01				; Check Backup RAM space
BRMSERCH		equ $02				; Search file in Backup RAM
BRMREAD			equ $03				; Read Backup RAM file
BRMWRITE		equ $04				; Write Backup RAM file
BRMDEL			equ $05				; Delete Backup RAM file
BRMFORMAT		equ $06				; Format Backup RAM
BRMDIR			equ $07				; Get Backup RAM directory
BRMVERIFY		equ $08				; Verify Backup RAM

; ----------------------------------------------------------------------
; BIOS entry points
; ----------------------------------------------------------------------

_CDSTAT			equ $005E80			; Status
_BOOTSTAT		equ $005EA0			; Boot status
_SETJMPTBL		equ $005F0A			; Set jump table
_WAITVSYNC		equ $005F10			; VSync
_BURAM			equ $005F16			; Backup RAM handler
_CDBOOT			equ $005F1C			; Boot function handler
_CDBIOS			equ $005F22			; BIOS function handler
_USERCALL0		equ $005F28			; System program initialization
_USERCALL1		equ $005F2E			; System program main
_USERCALL2		equ $005F34			; System program Mega Drive interrupt
_USERCALL3		equ $005F3A			; System program user call
ADDRESS_ERROR		equ $005F40			; Address error
INSTRUCTION_ERROR	equ $005F46			; Illegal instruction
DIVISION_ERROR		equ $005F4C			; Division by zero
CHK_ERROR		equ $005F52			; CHK exception
TRAPV_EXCEPT		equ $005F58			; TRAPV exception
PRIVILEGE_ERROR		equ $005F5E			; Privilege violation
TRACE_EXCEPT		equ $005F64			; TRACE exception
LINE_A_EXCEPT		equ $005F6A			; Line A emulator
LINE_F_EXCEPT		equ $005F70			; Line F emulator
GRAPHICS_INT		equ $005F76			; Graphics interrupt
MEGA_DRIVE_INT		equ $005F7C			; Mega Drive interrupt
TIMER_INT		equ $005F82			; Timer interrupt
CDD_INT			equ $005F88			; CDD interrupt
CDC_INT			equ $005F8E			; CDC interrupt
SUBCODE_INT		equ $005F94			; Subcode interrupt
IRQ7			equ $005F9A			; IRQ7
TRAP_00			equ $005FA0			; TRAP #00
TRAP_01			equ $005FA6			; TRAP #01
TRAP_02			equ $005FAC			; TRAP #02
TRAP_03			equ $005FB2			; TRAP #03
TRAP_04			equ $005FB8			; TRAP #04
TRAP_05			equ $005FBE			; TRAP #05
TRAP_06			equ $005FC4			; TRAP #06
TRAP_07			equ $005FCA			; TRAP #07
TRAP_08			equ $005FD0			; TRAP #08
TRAP_09			equ $005FD6			; TRAP #09
TRAP_10			equ $005FDC			; TRAP #10
TRAP_11			equ $005FE2			; TRAP #11
TRAP_12			equ $005FE8			; TRAP #12
TRAP_13			equ $005FEE			; TRAP #13
TRAP_14			equ $005FF4			; TRAP #14
TRAP_15			equ $005FFA			; TRAP #15

; ----------------------------------------------------------------------