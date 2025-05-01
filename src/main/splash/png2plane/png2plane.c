#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lodepng.h"

#include "common.h"

static unsigned char tiles[2048][8][8]; // 2048 is the number of tiles that can fit in the Mega Drive's VRAM
static unsigned char tiles_x[2048][8][8];
static unsigned char tiles_y[2048][8][8];
static unsigned char tiles_xy[2048][8][8];

static RGBColour palette[4][16];

static size_t created_tiles;
static unsigned int palette_line;

int main(int argc, char **argv)
{
	(void)argc;
	(void)argv;

	int exit_code = EXIT_SUCCESS;

	palette_line = 0;

	// Process command-line arguments
	for (int i = 1; i < argc; ++i)
	{
		const char *argument = argv[i];

		if (strlen(argument) != 2 || argument[0] != '-')
		{
			fprintf(stderr, "Error: Unrecognised option '%s'\n", argument);
			exit_code = EXIT_FAILURE;
		}
		else
		{
			switch (argument[1])
			{
				case 'l':
					++i;

					if (i == argc)
					{
						fputs("Error: '-l' argument needs a value after it\n", stderr);
						exit_code = EXIT_FAILURE;
					}
					else
					{
						char *end;
						const long value = strtol(argv[i], &end, 0);

						if (end != argv[i] + strlen(argv[i]) || errno == ERANGE)
						{
							fputs("Error: '-l' argument is not a valid number\n", stderr);
							exit_code = EXIT_FAILURE;
						}
						else if (value < 0 || value > 3)
						{
							fputs("Error: Palette line must be between 0 and 3 (inclusive)\n", stderr);
							exit_code = EXIT_FAILURE;
						}
						else
						{
							palette_line = (unsigned int)value;
						}
					}

					break;

				default:
					fprintf(stderr, "Error: Unrecognised option '%s'\n", argument);
					exit_code = EXIT_FAILURE;
					break;
			}
		}
	}

	// Read image
	RGBAColour *image_buffer;
	unsigned int image_width;
	unsigned int image_height;
	unsigned int error_code = lodepng_decode32_file((unsigned char**)&image_buffer, &image_width, &image_height, "plane.png");

	if (error_code != 0)
	{
		fprintf(stderr, "Error: LodePNG failed to decode file\nLodePNG error %u: %s\n", error_code, lodepng_error_text(error_code));
		exit_code = EXIT_FAILURE;
	}
	else
	{
		if (image_width & 7)
		{
			fputs("Error: Image width must be a multiple of 8\n", stderr);
			exit_code = EXIT_FAILURE;
		}
		else if (image_height & 7)
		{
			fputs("Error: Image height must be a multiple of 8\n", stderr);
			exit_code = EXIT_FAILURE;
		}
		else
		{
			// Read palette
			FILE *file_palette = fopen("palette.bin", "rb");

			if (file_palette == NULL)
			{
				fputs("Error: Could not open 'palette.bin'\n", stderr);
				exit_code = EXIT_FAILURE;
			}
			else
			{
				for (size_t index = 0; index < sizeof(palette) / sizeof(palette[0][0]); ++index)
				{
					int character;

					character = fgetc(file_palette);

					if (character == EOF)
						break;

					unsigned short colour = character << 8;

					character = fgetc(file_palette);

					if (character == EOF)
						break;

					colour |= character;

					RGBColour* const rgb_colour = &palette[index / 16][index % 16];

					DecodeColour(colour, rgb_colour);

					/*fprintf(stderr, "Got colour %X %X %X\n", rgb_colour->red, rgb_colour->green, rgb_colour->blue);*/
				}

				fclose(file_palette);

				FILE *file_map = fopen("map.bin", "wb");

				if (file_map == NULL)
				{
					fputs("Error: Could not open 'map.bin'\n", stderr);
					exit_code = EXIT_FAILURE;
				}
				else
				{
					for (size_t tile_y = 0; tile_y < image_height; tile_y += 8)
					{
						for (size_t tile_x = 0; tile_x < image_width; tile_x += 8)
						{
							unsigned char tile[8][8];
							for (size_t y = 0; y < 8; ++y)
							{
								for (size_t x = 0; x < 8; ++x)
								{
									const RGBAColour *colour = &image_buffer[((tile_y + y) * image_width) + tile_x + x];

									size_t i;

									if (colour->alpha == 0)
									{
										// Transparent pixel
										i = 0;
									}
									else
									{
										if (colour->alpha != 0xFF)
											fputs("Warning: Pixels can only have an alpha value of 0 or 0xFF\n", stderr);

										// Find colour in palette
										for (i = 1; i < 16; ++i)
											if (!memcmp(&colour->rgb, &palette[palette_line][i], sizeof(RGBColour)))
												break;

										if (i == 16)
										{
											fprintf(stderr, "Error: Could not find colour %X %X %X in specified palette line\n", colour->rgb.red, colour->rgb.green, colour->rgb.blue);
											exit_code = EXIT_FAILURE;
										}
									}

									tile[y][x] = i;
								}
							}

							size_t i;
							unsigned int rotation = 0;

							for (i = 0; i < created_tiles; ++i)
							{
								rotation = 0;

								if (!memcmp(tiles[i], tile, 8 * 8))
									break;

								rotation = 1;

								if (!memcmp(tiles_x[i], tile, 8 * 8))
									break;

								rotation = 2;

								if (!memcmp(tiles_y[i], tile, 8 * 8))
									break;

								rotation = 3;

								if (!memcmp(tiles_xy[i], tile, 8 * 8))
									break;
							}

							if (i >= created_tiles)
							{
								// Create tile
								++created_tiles;

								rotation = 0;

								for (size_t y = 0; y < 8; ++y)
								{
									for (size_t x = 0; x < 8; ++x)
									{
										tiles[i][y][x] = tile[y][x];
										tiles_x[i][y][7 - x] = tile[y][x];
										tiles_y[i][7 - y][x] = tile[y][x];
										tiles_xy[i][7 - y][7 - x] = tile[y][x];
									}
								}
							}

							unsigned short tile_metadata = 0;/*palette_line << 13;*/
							tile_metadata |= rotation << 11;
							tile_metadata |= i;

							fputc((tile_metadata >> 8) & 0xFF, file_map);
							fputc(tile_metadata & 0xFF, file_map);
						}
					}

					fclose(file_map);

					FILE *file_tiles = fopen("tiles.bin", "wb");

					if (file_tiles == NULL)
					{
						fputs("Error: Could not create 'tiles.bin'\n", stderr);
						exit_code = EXIT_FAILURE;
					}
					else
					{
						for (size_t i = 0; i < created_tiles; ++i)
							for (size_t y = 0; y < 8; ++y)
								for (size_t x = 0; x < 8; x += 2)
									fputc((tiles[i][y][x] << 4) | tiles[i][y][x + 1], file_tiles);

						fclose(file_tiles);
					}
				}
			}
		}

		free(image_buffer);
	}

	return exit_code;
}
