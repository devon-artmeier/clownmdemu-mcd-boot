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
; ------------------------------------------------------------------------------

OBJECT_SLOTS		equ 80					; Number of object slots

; ------------------------------------------------------------------------------
; Object slot
; ------------------------------------------------------------------------------

obj.id			equ $00					; Object ID
obj.sprite_flags	equ $02					; Sprite flags
obj.sprite		equ $04					; Sprite data
obj.x			equ $08					; X position
obj.y			equ $0C					; Y position
obj.x_speed		equ $10					; X speed
obj.y_speed		equ $14					; Y speed
obj.sprite_tile		equ $18					; Sprite tile ID
obj.sprite_flip		equ $19					; Flag affected by sprite flip
obj.anim_frame		equ $20					; Animation frame
obj.anim_time		equ $21					; Animation timer
obj.pal_cycle		equ $26					; Palette cycle offset
obj.move_time		equ $28					; Movement timer
obj.len			equ $40					; Length of structure

; ------------------------------------------------------------------------------
; RAM definitions
; ------------------------------------------------------------------------------

objects			equ WORK_RAM+$C000			; Object slots
decomp_buffer		equ WORK_RAM+$E000			; Decompression buffer
nem_code_table		equ WORK_RAM+$F700			; Nemesis code table
sprites			equ WORK_RAM+$F900			; Sprite data buffer
palette			equ WORK_RAM+$FB80			; Palette data buffer
stack			equ WORK_RAM+$FC00			; Stack
stack_base		equ WORK_RAM+$FD00			; Stack base
vdp_reg_00		equ WORK_RAM+$FDB4			; VDP register #00 cache
vdp_reg_01		equ WORK_RAM+$FDB6			; VDP register #01 cache
vdp_reg_02		equ WORK_RAM+$FDB8			; VDP register #02 cache
vdp_reg_03		equ WORK_RAM+$FDBA			; VDP register #03 cache
vdp_reg_04		equ WORK_RAM+$FDBC			; VDP register #04 cache
vdp_reg_05		equ WORK_RAM+$FDBE			; VDP register #05 cache
vdp_reg_06		equ WORK_RAM+$FDC0			; VDP register #06 cache
vdp_reg_07		equ WORK_RAM+$FDC2			; VDP register #07 cache
vdp_reg_08		equ WORK_RAM+$FDC4			; VDP register #08 cache
vdp_reg_09		equ WORK_RAM+$FDC6			; VDP register #09 cache
vdp_reg_0a		equ WORK_RAM+$FDC8			; VDP register #0A cache
vdp_reg_0b		equ WORK_RAM+$FDCA			; VDP register #0B cache
vdp_reg_0c		equ WORK_RAM+$FDCC			; VDP register #0C cache
vdp_reg_0d		equ WORK_RAM+$FDCE			; VDP register #0D cache
vdp_reg_0e		equ WORK_RAM+$FDD0			; VDP register #0E cache
vdp_reg_0f		equ WORK_RAM+$FDD2			; VDP register #0F cache
vdp_reg_10		equ WORK_RAM+$FDD4			; VDP register #10 cache
vdp_reg_11		equ WORK_RAM+$FDD6			; VDP register #11 cache
vdp_reg_12		equ WORK_RAM+$FDD8			; VDP register #12 cache
ctrl_hold_p1		equ WORK_RAM+$FE20			; Player 1 controller data (held buttons)
ctrl_tap_p1		equ WORK_RAM+$FE21			; Player 1 controller data (tapped buttons)
ctrl_hold_p2		equ WORK_RAM+$FE22			; Player 2 controller data (held buttons)
ctrl_tap2		equ WORK_RAM+$FE23			; Player 2 controller data (tapped buttons)
ctrl_timer_p1		equ WORK_RAM+$FE24			; Player 1 controller directional pad timer
ctrl_timer_p2		equ WORK_RAM+$FE25			; Player 2 controller directional pad timer
vblank_flags		equ WORK_RAM+$FE26			; V-BLANK handler flags
vblank_user_count	equ WORK_RAM+$FE27			; User V-BLANK counter
vblank_updates_off	equ WORK_RAM+$FE28			; V-BLANK handler update disable flag
update_cram		equ WORK_RAM+$FE29			; CRAM update flag
rng_seed		equ WORK_RAM+$FE2A			; Random number generator seed
font_tile		equ WORK_RAM+$FE2C			; Font tile properties
plane_stride		equ WORK_RAM+$FE2E			; VDP plane stride
object_sprite_slot	equ WORK_RAM+$FE30			; Current object sprite slot
object_index		equ WORK_RAM+$FE34			; Object index table
object_sprite_link	equ WORK_RAM+$FE38			; Current object sprite link
fade_in_offset		equ WORK_RAM+$FE46			; Palette fade in offset
fade_in_length		equ WORK_RAM+$FE47			; Palette fade in length
fade_in_intensity	equ WORK_RAM+$FE48			; Palette fade in intensity
fade_in_data		equ WORK_RAM+$FE4A			; Palette fade in data
time_minuend		equ WORK_RAM+$FE4E			; Time subtraction minuend
time_subtrahend		equ WORK_RAM+$FE50			; Time subtraction subtrahend
user_vblank		equ WORK_RAM+$FDA8			; User V-BLANK interrupt

; ------------------------------------------------------------------------------