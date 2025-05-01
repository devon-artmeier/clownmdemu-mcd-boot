all: tiles.bin map.bin

png2plane/png2plane:
	$(MAKE) -C png2plane

tiles.bin map.bin: png2plane/png2plane plane.png palette.bin
	$< -l 3
