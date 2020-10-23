#include <main.h>
#include <lodepng/lodepng.h>
#include <libimagequant.h>
#include <zopflipng_lib.h>

typedef std::vector<unsigned char> U8ClampVec;

static auto TryQuantize(U8ClampVec& raw_pix, quint32 w, quint32 h, qint8 qmin, U8ClampVec& quanz_png) -> bool
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
	liq_image  *in_IMG = liq_image_create_rgba(options, reinterpret_cast<unsigned char*>(raw_pix.data()), w, h, 0);

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
	U8ClampVec img(src_png.begin(), src_png.end()), raw_RGBA_pixels;
	quint32 w, h;
	int ecode = 0;

	if (img[0] == 'B' && img[1] == 'M') {
	  if(img.size() < 54) return -2; //minimum BMP header size
	  unsigned pix_offset = img[10] + 256 * img[11]; //where the pixel data starts
	  //read width and height from BMP header
	  w = img[18] + img[19] * 256;
	  h = img[22] + img[23] * 256;
	  //read number of channels from BMP header
	  if(img[28] != 24 && img[28] != 32) return -3; //only 24-bit and 32-bit BMPs are supported.
	  //The amount of scanline bytes is width of image times channels, with extra bytes added if needed
	  //to make it a multiple of 4 bytes.
	  unsigned char channels  = img[28] / 8;
	  unsigned int line_bytes = w * channels;
	  if(line_bytes % 4 != 0) line_bytes = (line_bytes / 4) * 4 + 4;
	  if(img.size() < line_bytes * h + pix_offset) return -2; //BMP file too small to contain all pixels
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
	  /* Try apply Quantization */
	  if (!TryQuantize(raw_RGBA_pixels, w, h, qmin, quanz_png)) {
		ecode = lodepng::encode(quanz_png, raw_RGBA_pixels, w, h, LCT_RGBA, 8);
	  }
	} else {
	  // decode PNG as raw RGBA pixels
	  if (!(ecode = lodepng::decode(raw_RGBA_pixels, w, h, img))) {
		/* Try apply Quantization */
		if (!TryQuantize(raw_RGBA_pixels, w, h, qmin, quanz_png)) {
		  quanz_png.swap(img);
		}
	  }
	}
	return ecode;
}

auto PngWrk::optim() -> bool
{
	QByteArray src_png;

	bool is_ok = m_parent->qFileLoad(m_index, src_png);
	if ( is_ok ) {

		U8ClampVec quanz_png, optim_png;
		int ecode = decodePixData(src_png, m_quality, quanz_png);

		if (( is_ok = !ecode )) {

			if (quanz_png.size() != m_rawSize) {
				QCoreApplication::postEvent(m_parent,
					new TaskEvent(m_index, S_Working, m_rawSize, quanz_png.size()));
			}
			ZopfliPNGOptions png_options;

			png_options.lossy_transparent = m_8bit;
			png_options.lossy_8bit        = m_8bit;
			png_options.verbose           = false;
			png_options.use_zopfli        = true;

			ecode = ZopfliPNGOptimize(quanz_png, png_options, false, &optim_png);

			if (( is_ok = !ecode ) && m_rawSize > (m_optSize = optim_png.size())) {
				QByteArray out_png(reinterpret_cast<const char*>(optim_png.data()), m_optSize);
				is_ok = m_parent->qFileStore(m_index, out_png, PNG);
			}
		}
		switch (ecode) {
			case  0:
			case -1: break;
			case -2: qWarning("BMP data corrupt or contains wrong header info"); break;
			case -3: qWarning("only 24/32-bit BMPs are supported"); break;
			default: qWarning() << "lodepng:" << lodepng_error_text(ecode);
		}
	}
	return is_ok;
}
