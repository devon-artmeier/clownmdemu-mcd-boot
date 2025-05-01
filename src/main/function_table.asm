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

	dcb.b	$280-*, $FF
	
; ------------------------------------------------------------------------------

	bra.w	SoftReset					; Soft reset
	bra.w	HardReset					; Hard reset
	bra.w	GoToControlPanel				; Go to control panel
	bra.w	ResetToControlPanel				; Reset to control panel
	rts							; V-BLANK interrupt handler (not available in clownmdemu)
	nop
	bra.w	EnableHBlank					; Enable and set up H-BLANK interrupt
	bra.w	ReadControllers					; Read 3 button controllers
	bra.w	GetControllerId					; Get controller ID
	bra.w	ClearVdp					; Clear VDP memory
	bra.w	ClearScreen					; Clear screen
	bra.w	ClearVsram					; Clear vertical scroll table
	bra.w	SetDefaultVdpRegs				; Set default VDP register values
	bra.w	SetVdpRegisters					; Set VDP register values
	bra.w	FillVdpRegion					; Fill region of VDP memory
	bra.w	ClearVdpRegion					; Clear region of VDP memory
	bra.w	ClearVramRegion					; Clear region of VRAM
	bra.w	FillVramRegion					; Fill region of VRAM
	bra.w	DrawTilemap					; Draw tilemap
	bra.w	DrawByteTilemap					; Draw tilemap (byte sized tile IDs)
	bra.w	FillPlaneRegion					; Fill plane region
	bra.w	DmaToVram					; DMA transfer from 68000 memory to VRAM
	bra.w	DmaWordRamToVram				; DMA transfer from Word RAM to VRAM
	bra.w	EnableDisplay					; Enable display
	bra.w	DisableDisplay					; Disable display
	bra.w	LoadPaletteNoUpdate				; Load palette (don't set the update flag)
	bra.w	LoadPalette					; Load palette
	bra.w	UpdateCram					; Update CRAM
	bra.w	NemDecToVram					; Decompress Nemesis graphics into VRAM
	bra.w	NemDecToRam					; Decompress Nemesis graphics into RAM
	bra.w	UpdateObjects					; Update objects
	bra.w	ClearMemoryRegion				; Clear region of memory
	bra.w	ClearLargeMemoryRegion				; Clear large region of memory
	bra.w	DrawObjectSprite				; Draw object sprite
	bra.w	VSync						; VSync
	bra.w	DefaultVSync					; VSync with default flags
	bra.w	UpdateSprites					; Update sprites
	bra.w	UnkCopyFunction					; Unknown and bugged copy and caller function
	bra.w	EnableWorkRamHBlank				; Enable and set up H-BLANK interrupt (in second half of Work RAM)
	bra.w	DisableHBlank					; Disable H-BLANK interrupt
	bra.w	DrawText					; Draw text
	bra.w	Decode1bppArt					; Decode 1BPP graphics into VRAM
	bra.w	LoadFont					; Load the BIOS font
	bra.w	LoadFontDefault					; Load the BIOS font with the default settings
	bra.w	UpdateDpadTimer					; Update controller D-Pad timer
	bra.w	EniDec						; Decompress Enigma mappings into RAM
	bra.w	DrawMcdImageTilemap				; Draw tilemap for Mega CD generated graphics
	bra.w	Random						; Get random number
	bra.w	UpdateRngSeed					; Update random number generator seed
	bra.w	ClearMcdCommRegs				; Clear communication registers
	rts							; Update communication registers (not available in clownmdemu)
	nop
	rts							; Get disc track information (not available in clownmdemu)
	nop
	rts							; Sync with Sub CPU (not available in clownmdemu)
	nop
	rts							; Call Sub CPU BIOS function (not available in clownmdemu)
	nop
	rts							; Call Sub CPU Backup RAM function (not available in clownmdemu)
	nop
	rts							; Call unknown Sub CPU function (not available in clownmdemu)
	nop
	rts							; Call Sub CPU scene function (not available in clownmdemu)
	nop
	bra.w	TriggerMcdSubIrq2				; Trigger Sub CPU's IRQ2
	bra.w	SplashScreen					; Display splash screen
	bra.w	SetVBlankHandler				; Set V-BLANK interrupt handler
	bra.w	DrawSequentialTilemap				; Draw tilemap with sequential tile IDs
	bra.w	DrawPartialTilemap				; Partially draw tilemap
	bra.w	CopyVramRegion					; Copy a region of VRAM to another place in VRAM
	rts							; Call indexed Sub CPU BIOS function (not available in clownmdemu)
	nop
	bra.w	ByteToBcd					; Convert byte value to BCD format
	bra.w	WordToBcd					; Convert word value to BCD format
	bra.w	BlackOutDisplay					; Black out display
	bra.w	FadeOutPalette					; Fade out palette
	bra.w	FadeInPalette					; Fade in palette
	bra.w	SetupPaletteFadeIn				; Set up palette fade in
	bra.w	FlushDmaQueue					; Flush Word RAM DMA queue
	bra.w	FlushShortDmaQueue				; Flush short Word RAM DMA queue
	bra.w	AddTimeCodes					; Add 2 minute:second timecodes together
	bra.w	SubtractTimeCodes				; Subtract minute:second:centisecond:xx timecode from another
	
; ------------------------------------------------------------------------------