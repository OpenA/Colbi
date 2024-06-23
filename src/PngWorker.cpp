#include "Colbi.hpp"
#include <lodepng/lodepng.h>
#include <libimagequant.h>
#include <zopflipng_lib.h>

typedef std::vector<unsigned char> U8ClampVec;

static auto TryQuantize(U8ClampVec& raw_pix, unsigned int w, unsigned int h, int qmin, U8ClampVec& quanz_png) -> bool
{
	// You could set more options here, like liq_set_last_index_transparent(options, 200000);
	liq_attr *options = liq_attr_create();

	if (LIQ_OK != liq_set_quality           (options, qmin, 100) ||
		LIQ_OK != liq_set_min_opacity       (options, 0) ||
		LIQ_OK != liq_set_min_posterization (options, 0)) {
		liq_attr_destroy(options);
		qWarning("libimagequant: Set Options failed");
		return false;
	}
	// Use libimagequant to make a palette for the RGBA pixels
	liq_result *qResult;
	liq_image  *in_IMG = liq_image_create_rgba(options, raw_pix.data(), w, h, 0);

	if (LIQ_OK != liq_image_quantize(in_IMG, options, &qResult)) {
		liq_image_destroy( in_IMG  );
		liq_attr_destroy ( options );
		qWarning("libimagequant: Quantization failed");
		return false;
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
	bool err = lodepng::encode(quanz_png, q8bit_buff, w, h, out_PNG_state);
	if ( err )
		qWarning("lodepng: Quantized img encoding failed");
	// Done. Free memory.
	liq_result_destroy( qResult ); // Must be freed only after you're done using the palette
	liq_image_destroy ( in_IMG  );
	liq_attr_destroy  ( options );

	return !err;
}

//returns 0 if all went ok, non-0 if error
//output image is always given in RGBA (with alpha channel), even if it's a BMP without alpha channel
static auto decodePixData(QByteArray& src_png, qint8 qmin, U8ClampVec& quanz_png) -> int
{
	U8ClampVec raw_pixels, qnz_pixels;
	unsigned int w, h;
	int ecode = 0;

	unsigned char *src_data = reinterpret_cast<unsigned char*>(src_png.data());
	unsigned int   src_size = src_png.size();

	if (src_png.at(0) == 'B' &&
		src_png.at(1) == 'M' &&
		src_png.at(2) == 'P')
	{
		unsigned int pix_offset, line_bytes, x, y;
		unsigned char fff, bpp;

		if (src_size < 54)
			return -2; // minimum BMP header size

		// where the pixel data starts
		pix_offset = (unsigned)src_png.at(10) + 256 * (unsigned)src_png.at(11); 
		// read width and height from BMP header
		w = (unsigned)src_png.at(18) + (unsigned)src_png.at(19) * 256;
		h = (unsigned)src_png.at(22) + (unsigned)src_png.at(23) * 256;
		// read bit per pixel
		bpp = src_png.at(28),
		fff = bpp == 24 ? 0xFF : 0;
		if (bpp != 24 && bpp != 32)
			return -3; // only 24-bit and 32-bit BMPs are supported.
		// The amount of scanline bytes is width of image times channels, with extra bytes added if needed
		// to make it a multiple of 4 bytes.
		bpp /= 8, // perform to bytes per pixel
		line_bytes = w * bpp;
		if (line_bytes % 4 != 0)
			line_bytes = (line_bytes / 4) * 4 + 4;
		if (src_size < line_bytes * h + pix_offset)
			return -2; // BMP file too small to contain all pixels
		raw_pixels.resize(w * h * 4);
		/*
		There are 3 differences between BMP and the raw image buffer for LodePNG:
		-it's upside down
		-it's in BGR instead of RGB format (or BRGA instead of RGBA)
		-each scanline has padding bytes to make it a multiple of 4 if needed
		The 2D for loop below does all these 3 conversions at once.
		*/
		for (y = 0; y < h; y++) {
			for (x = 0; x < w; x++) {
				// pixel start byte position in the new raw image
				unsigned pngpos = 4 * y * w + 4 * x,
				// pixel start byte position in the BMP
				         bmpos = pix_offset + (h - y - 1) * line_bytes + bpp * x;
				raw_pixels[pngpos + 0] = src_png.at(bmpos + 2); // R
				raw_pixels[pngpos + 1] = src_png.at(bmpos + 1); // G
				raw_pixels[pngpos + 2] = src_png.at(bmpos + 0); // B
				raw_pixels[pngpos + 3] = fff ? fff : src_png.at(bmpos + 3); // A
			}
		}
		/* Try apply Quantization */
		if (!TryQuantize(raw_pixels, w, h, qmin, quanz_png)) {
			ecode = lodepng::encode(quanz_png, raw_pixels, w, h);
		}
	} else {
		// decode PNG as raw RGBA pixels
		if (!(ecode = lodepng::decode(raw_pixels, w, h, src_data, src_size))) {
			/* Try apply Quantization */
			if (!TryQuantize(raw_pixels, w, h, qmin, quanz_png)) {
				quanz_png.assign(src_data, src_data + src_size);
			}
		}
	}
	return ecode;
}

auto Png_optim(Colbi *parent, int index, QByteArray &src_png, bool rgb8b, int  qmin) -> stat_t
{
	U8ClampVec qnz_png, opt_png;

	int ecode = decodePixData(src_png, qmin, qnz_png);
	if (ecode == 0) {

		int i, src_sz = src_png.size(),
		       opt_sz = qnz_png.size();

		if (src_sz != opt_sz)
			QCoreApplication::postEvent(parent,
				new TaskEvent(index, S_Working, src_sz, opt_sz));

		ZopfliPNGOptions options;

		options.lossy_transparent = rgb8b,
		options.lossy_8bit        = rgb8b,
		options.verbose           = false,
		options.use_zopfli        = true;

		ecode = ZopfliPNGOptimize(qnz_png, options, false, &opt_png);

		if (ecode == 0)
		if (src_png.size() > opt_png.size()) {
			src_png.resize(  opt_png.size());
			for (i = 0; i  < opt_png.size(); i++)
				src_png[i] = opt_png[i];
		}
	}
	switch (ecode) {
	case  0:
		return S_Complete;
	case -1:
		break;
	case -2: qWarning("BMP data corrupt or contains wrong header info");
		break;
	case -3: qWarning("only 24/32-bit BMPs are supported");
		break;
	default: qWarning() << "lodepng:" << lodepng_error_text(ecode);
	}
	return S_Error;
}
