CFLAGS = -O3 -s -flto -DNDEBUG -Wall -Wextra -pedantic

all: png2plane

png2plane: png2plane.c common.c lodepng.c
	$(CC) $(CFLAGS) $(LDFLAGS) -DLODEPNG_NO_COMPILE_ENCODER $^ -o $@ $(LIBS)
