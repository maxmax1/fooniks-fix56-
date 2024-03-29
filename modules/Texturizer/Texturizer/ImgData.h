#ifndef __IMGDATA_H
#define __IMGDATA_H

#include <stdio.h> 

#include <iostream>
#include <fstream>

#include <gd.h>

#include <vector>
#include <map>

#include "extra/CLuaArguments.h"

#include "pstdint.h"

#include <squish.h>
using namespace squish;

#define FORMAT_DEFAULT         0x0000
#define FORMAT_1555            0x0100 // (1 bit alpha, RGB 5 bits each; also used for DXT1 with alpha)
#define FORMAT_565             0x0200 // (5 bits red, 6 bits green, 5 bits blue; also used for DXT1 without alpha)
#define FORMAT_4444            0x0300 // (RGBA 4 bits each; also used for DXT3)
#define FORMAT_LUM8            0x0400 // (gray scale)
#define FORMAT_8888            0x0500 // (RGBA 8 bits each)
#define FORMAT_888             0x0600 // (RGB 8 bits each)
#define FORMAT_555             0x0A00 // (RGB 5 bits each - rare, use 565 instead)

#define FORMAT_EXT_AUTO_MIPMAP 0x1000 // (RW generates mipmaps)
#define FORMAT_EXT_PAL8        0x2000 // (2^8 = 256 palette colors)
#define FORMAT_EXT_PAL4        0x4000 // (2^4 = 16 palette colors)
#define FORMAT_EXT_MIPMAP      0x8000 // (mipmaps included)

#define ORDER_RGBA			   0
#define ORDER_BGRA			   1

class TextureImage
{
private:

	std::string 
		fileName;

	std::map<uint32_t, int> 
		fOrder;

	uint32_t 
		cFilter;

	void Init( );

public:
	// Default constructor
	TextureImage();

	// Default destructor
	~TextureImage();

	/**
	 * TextureImage intializer overload which also sets the fileName.
	 * @param std::string fileName to load.
	 */
	TextureImage(std::string fName);

	void LoadImageToData( uint32_t filter, bool mAlpha );
	void Compress( );

	int
		errorCode,
		width,
		height;

	std::vector<unsigned char>
		fileData;

};

class GdImgManager
{
private:
	std::map<void *, gdImagePtr> mImages;

public:
	GdImgManager( );
	~GdImgManager( );

	gdImagePtr GetImage( void * userData );

	void * AddImage( lua_State * luaVM, int width, int height );
	void * AddImage( lua_State * luaVM, std::string rFilePath );

	void RemoveImage( void * userData );

};

#endif // __IMGDATA_H