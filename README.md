# clownmdemu-mcd-boot
A minimal Mega CD boot ROM, specifically for use with [clownmdemu](https://github.com/Clownacy/clownmdemu)'s Mega CD emulation.

## Building
1. Assemble the "core.asm" file in the "sub" folder to build the Sub CPU BIOS file.
2. Compress the assembled Sub CPU BIOS file in Kosinski, using flamewing's [mdcomp](https://github.com/flamewing/mdcomp) compressor (other compressors may not compress it in a way where it can be detected in Mode 1).
3. Assemble the "core.asm" file in the "main" folder to build the full boot ROM.
