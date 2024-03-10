# clownmdemu-mcd-boot
A minimal Mega CD boot ROM, specifically for use with [clownmdemu](https://github.com/Clownacy/clownmdemu)'s Mega CD emulation.

## Building
1. Create a folder called "build".
2. Assemble the "core.asm" file in the "sub" folder to build the Sub CPU BIOS file into the "build" folder.
3. Compress the assembled Sub CPU BIOS file in Kosinski in the "build" folder, using flamewing's [mdcomp](https://github.com/flamewing/mdcomp/releases) compressor (other compressors may not compress it in a way where it can be detected in Mode 1).
4. Assemble the "core.asm" file in the "main" folder to build the full boot ROM.
