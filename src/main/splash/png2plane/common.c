#include "common.h"

#include <stdbool.h>

bool DecodeColour(unsigned short md_colour, RGBColour *colour)
{
	bool perfect_conversion;

	if (md_colour & 0xF111)
		perfect_conversion = false;
	else
		perfect_conversion = true;

	colour->red = (md_colour << 4) & 0xF0;
	colour->green = md_colour & 0xF0;
	colour->blue = (md_colour >> 4) & 0xF0;

	return perfect_conversion;
}

bool EncodeColour(const RGBColour *colour, unsigned short *md_colour)
{
	bool perfect_conversion;

	if (colour->red & 0x1F || colour->green & 0x1F || colour->blue & 0x1F)
		perfect_conversion = false;
	else
		perfect_conversion = true;

	*md_colour = 0;
	*md_colour |= (colour->red & 0xF0) >> 4;
	*md_colour |= colour->green & 0xF0;
	*md_colour |= (colour->blue & 0xF0) << 4;

	return perfect_conversion;
}
