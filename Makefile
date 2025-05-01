all: out/bios.bin

out/accurate-kosinski/kosinski-compress:
	@mkdir -p out
	@mkdir -p out/accurate-kosinski
	cmake -B out/accurate-kosinski bin/accurate-kosinski -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build out/accurate-kosinski --config Release --target kosinski-compress

bin/clownassembler/clownassembler:
	$(MAKE) -C bin/clownassembler clownassembler

bin/clownlzss/clownlzss:
	$(MAKE) -C bin/clownlzss clownlzss

out/clownnemesis/clownnemesis-tool:
	@mkdir -p out
	@mkdir -p out/clownnemesis
	cmake -B out/clownnemesis bin/clownnemesis -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build out/clownnemesis --config Release --target clownnemesis-tool

out/sub_bios.bin: src/sub/core.asm bin/clownassembler/clownassembler
	@mkdir -p out
	bin/clownassembler/clownassembler -i $< -o $@

out/sub_bios.kos: out/sub_bios.bin out/accurate-kosinski/kosinski-compress
	@mkdir -p out
	out/accurate-kosinski/kosinski-compress $< $@

src/main/splash/tiles.bin src/main/splash/map.bin:
	$(MAKE) -C src/main/splash

src/main/splash/tiles.nem: src/main/splash/tiles.bin out/clownnemesis/clownnemesis-tool
	out/clownnemesis/clownnemesis-tool -c $< $@

src/main/splash/map.eni: src/main/splash/map.bin bin/clownlzss/clownlzss
	bin/clownlzss/clownlzss -e $< $@

out/bios.bin: src/main/core.asm out/sub_bios.kos bin/clownassembler/clownassembler src/main/splash/tiles.nem src/main/splash/map.eni
	@mkdir -p out
	bin/clownassembler/clownassembler -i $< -o $@
