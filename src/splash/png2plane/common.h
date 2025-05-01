#ifndef COMMON_H
#define COMMON_H

#include <stdbool.h>

typedef struct RGBColour
{
	unsigned char red;
	unsigned char green;
	unsigned char blue;
} RGBColour;

typedef struct RGBAColour
{
	RGBColour rgb;
	unsigned char alpha;
} RGBAColour;

bool DecodeColour(unsigned short md_colour, RGBColour *colour);
bool EncodeColour(const RGBColour *colour, unsigned short *md_colour);

#endif
