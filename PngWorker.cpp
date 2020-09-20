#include <main.h>
#include <lib/libimagequant/libimagequant.h>
#include "lib/zopfli/src/zopflipng/zopflipng_lib.h"
#include "lib/zopfli/src/zopflipng/lodepng/lodepng.h"

typedef std::vector<unsigned char> U8ClampVec;

namespace PngOpts {
	quint8 quality = 100;
}

static auto isValidResult(const U8ClampVec &src_png, const U8ClampVec &optim_png, bool lossy) -> int
{
	unsigned w, h, cmpW, cmpH;
	U8ClampVec original, optimized;

	lodepng::decode(original, w, h, src_png);
	lodepng::decode(optimized, cmpW, cmpH, optim_png);

	bool same_size = cmpW == w && cmpH == h && optimized.size() == original.size();
	if ( same_size ) {
		for (size_t i = 0; i < optimized.size(); i += 4) {
			if (
				optimized[i + 0] != original[i + 0] ||
				optimized[i + 1] != original[i + 1] ||
				optimized[i + 2] != original[i + 2] ||
				optimized[i + 3] != (lossy ? 0 : original[i + 3])
			) {
				return -1;
			}
		}
	}
	return 0;
}

static auto zoptim(const U8ClampVec &src_png, U8ClampVec &optim_png) -> int
{
	ZopfliPNGOptions png_options;

	png_options.lossy_transparent = true;
	png_options.lossy_8bit        = true;
	png_options.verbose           = false;
	png_options.use_zopfli        = true;

	int ecode = ZopfliPNGOptimize(src_png, png_options, png_options.verbose, &optim_png);
	if(!ecode) {
		return 0;//isValidResult(src_png, optim_png, png_options.lossy_transparent);
	}
	return ecode;
}

static auto quantz(const quint8 qmin, unsigned &w, unsigned &h, U8ClampVec &raw_RGBA_pixels, U8ClampVec &optim_png) -> int
{
	// You could set more options here, like liq_set_last_index_transparent(options, 200000);
	liq_attr *options = liq_attr_create();

	if (LIQ_OK != liq_set_quality           (options, qmin, 100) ||
		LIQ_OK != liq_set_min_opacity       (options, 0) ||
		LIQ_OK != liq_set_min_posterization (options, 0)) {
		liq_attr_destroy(options);
		return -2;
	}

	// Use libimagequant to make a palette for the RGBA pixels
	liq_result *qResult;
	liq_image  *in_IMG = liq_image_create_rgba(options, reinterpret_cast<unsigned char*>(raw_RGBA_pixels.data()), w, h, 0);

	if (LIQ_OK != liq_image_quantize(in_IMG, options, &qResult)) {
		liq_image_destroy( in_IMG  );
		liq_attr_destroy ( options );
		return -3;
	}
	liq_set_dithering_level(qResult, 1.0);

	size_t pixels_size = w * h;
	unsigned char q8bit_buff[pixels_size];

	liq_write_remapped_image(qResult, in_IMG, q8bit_buff, pixels_size);

	// Save converted pixels as a PNG file
	lodepng::State out_PNG_state;
	out_PNG_state.info_raw.colortype       = LCT_PALETTE;
	out_PNG_state.info_raw.bitdepth        = 8;
	out_PNG_state.info_png.color.colortype = LCT_PALETTE;
	out_PNG_state.info_png.color.bitdepth  = 8;

	const liq_palette *palette = liq_get_palette(qResult);

	for (unsigned i = 0; i < palette->count; i++) {
		lodepng_palette_add(&out_PNG_state.info_png.color, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
		lodepng_palette_add(&out_PNG_state.info_raw      , palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
	}

	// Done. Free memory.
	liq_result_destroy( qResult ); // Must be freed only after you're done using the palette
	liq_image_destroy ( in_IMG  );
	liq_attr_destroy  ( options );

	return lodepng::encode(optim_png, q8bit_buff, w, h, out_PNG_state);
}

//returns 0 if all went ok, non-0 if error
//output image is always given in RGBA (with alpha channel), even if it's a BMP without alpha channel
static auto decodePixData(U8ClampVec& img, unsigned &w, unsigned &h, U8ClampVec& raw_RGBA_pixels) -> int
{
	if (img[0] == 'B' && img[1] == 'M') {
	  if(img.size() < 54) return -4; //minimum BMP header size
	  unsigned pix_offset = img[10] + 256 * img[11]; //where the pixel data starts
	  //read width and height from BMP header
	  w = img[18] + img[19] * 256;
	  h = img[22] + img[23] * 256;
	  //read number of channels from BMP header
	  if(img[28] != 24 && img[28] != 32) return -5; //only 24-bit and 32-bit BMPs are supported.
	  //The amount of scanline bytes is width of image times channels, with extra bytes added if needed
	  //to make it a multiple of 4 bytes.
	  unsigned char channels  = img[28] / 8;
	  unsigned int line_bytes = w * channels;
	  if(line_bytes % 4 != 0) line_bytes = (line_bytes / 4) * 4 + 4;
	  if(img.size() < line_bytes * h + pix_offset) return -6; //BMP file too small to contain all pixels
	  raw_RGBA_pixels.resize(w * h * 4);
	  const bool rgb = channels == 3;
	/*
	There are 3 differences between BMP and the raw image buffer for LodePNG:
	-it's upside down
	-it's in BGR instead of RGB format (or BRGA instead of RGBA)
	-each scanline has padding bytes to make it a multiple of 4 if needed
	The 2D for loop below does all these 3 conversions at once.
	*/
	  for(unsigned y = 0; y < h; y++)
	  for(unsigned x = 0; x < w; x++) {
		//pixel start byte position in the BMP
		unsigned bmpos = pix_offset + (h - y - 1) * line_bytes + channels * x;
		//pixel start byte position in the new raw image
		unsigned newpos = 4 * y * w + 4 * x;
		raw_RGBA_pixels[newpos + 0] = img[bmpos + 2]; //R
		raw_RGBA_pixels[newpos + 1] = img[bmpos + 1]; //G
		raw_RGBA_pixels[newpos + 2] = img[bmpos + 0]; //B
		raw_RGBA_pixels[newpos + 3] = rgb ? 255 : img[bmpos + 3]; //A
	  }
	  return 0;
	} else // decode PNG as raw RGBA pixels
		return lodepng::decode(raw_RGBA_pixels, w, h, img);
}

auto PngWrk::optim() -> bool
{
	U8ClampVec raw_png, optim_png;
	int ecode  = lodepng::load_file(raw_png, m_inFile.toUtf8().constData());
	if(!ecode) {

		unsigned w, h;
		U8ClampVec raw_RGBA_pixels, quanz_png;
		const quint8 qmin = PngOpts::quality;

		if (!(ecode = decodePixData(raw_png, w, h, raw_RGBA_pixels))) {
			if (qmin < 100) {
				if (!(ecode = quantz(qmin, w, h, raw_RGBA_pixels, quanz_png))) {
					QCoreApplication::postEvent(m_parent, new TaskEvent(m_index, S_Working, m_rawSize, quanz_png.size()));
					ecode = zoptim(quanz_png, optim_png);
				}
			} else {
				ecode = lodepng::encode(quanz_png, raw_RGBA_pixels, w, h) ?: zoptim(quanz_png, optim_png);
			}
			if(!ecode) {
				m_optSize = optim_png.size();
				ecode = lodepng::save_file(optim_png, m_outFile.toUtf8().constData());
			}
		}
	}
#ifdef QT_DEBUG
	switch(ecode)
	{
	case  0: return true;
	case -1: qDebug() << "result is not valid"; break;
	case -2: qDebug() << "libimagequant: Set Options failed"; break;
	case -3: qDebug() << "libimagequant: Quantization failed"; break;
	default: qDebug() << "lodepng:" << lodepng_error_text(ecode);
	}
#endif
	return !ecode;
}
