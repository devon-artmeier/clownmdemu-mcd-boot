# clownmdemu-mcd-boot
A minimal Mega CD boot ROM, specifically for use with
[ClownMDEmu](https://github.com/Clownacy/clownmdemu)'s Mega CD emulation.

## Building
1. Create a folder called "out".
2. Assemble the "core.asm" file in the "sub" folder to build the Sub CPU BIOS
   file into the "out" folder.
   [clownassembler](https://github.com/Clownacy/clownassembler) can be used for
   this.
3. Compress the assembled Sub CPU BIOS file in Kosinski in the "out" folder,
   using Clownacy's
   [accurate Kosinski](https://github.com/Clownacy/accurate-kosinski/releases)
   compressor (other compressors may not compress it in a way where it can be
   detected in Mode 1). Make sure that the compressed file is named
   'subbios.kos'.
4. Assemble the "core.asm" file in the "main" folder to build the full boot
   ROM.

## Mode 1 Compatibility
It is important that the string 'SEGA' appears at exactly offset 0x6D in the
compressed Sub CPU BIOS file. This is because software which uses the Mega CD
in 'Mode 1' checks for this string to detect where the Sub CPU BIOS is. If the
string is not at the expected position, then software may fail to detect the
Mega CD or even crash!
