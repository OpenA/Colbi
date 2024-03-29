#include <main.h>
#include <jpeglib.h>

static auto mozjInit(j_decompress_ptr srcinfo, j_compress_ptr dstinfo, const unsigned char* src_jpg, const unsigned long src_size) -> void
{
	/* Initialize the JPEG decompression object with default error handling. */
	jpeg_error_mgr *jsrcerr = srcinfo->err = jpeg_std_error(new jpeg_error_mgr);
	jpeg_create_decompress(srcinfo);

	/* Initialize the JPEG compression object with default error handling. */
	jpeg_error_mgr *jdsterr = dstinfo->err = jpeg_std_error(new jpeg_error_mgr);
	jpeg_create_compress(dstinfo);

	jsrcerr->trace_level = jdsterr->trace_level = 0;
	jsrcerr->error_exit  = jdsterr->error_exit  = [](j_common_ptr cdinfo) {
		char error_msg[JMSG_LENGTH_MAX];
		// Call the function pointer to get the error message
		(*cdinfo->err->format_message)(cdinfo, error_msg);
		throw QString(error_msg);
	};
	/* ... */
	jpeg_mem_src(srcinfo, src_jpg, src_size);
	/* Read file header */
	jpeg_read_header(srcinfo, TRUE);
	/* Set Compression settings */
	jpeg_c_set_int_param(dstinfo, JINT_COMPRESS_PROFILE, JCP_MAX_COMPRESSION);
}

static inline auto mozj_set_encmethods(j_compress_ptr dstinfo, bool progss, bool arith) -> void {
	if (progss)
		jpeg_simple_progression(dstinfo);
#ifdef C_ARITH_CODING_SUPPORTED
	dstinfo->optimize_coding = arith ? FALSE : TRUE;
	dstinfo->arith_code      = arith ? TRUE : FALSE;
#else
	dstinfo->optimize_coding = TRUE;
#endif
}

static auto mozjLosslessOptim(j_decompress_ptr srcinfo, j_compress_ptr dstinfo, unsigned char **out_jpg, unsigned long *out_size, bool progss, bool arith) -> void
{
	/* Read source file as DCT coefficients */
	jvirt_barray_ptr *coef_arrays = jpeg_read_coefficients(srcinfo);
	/* Initialize destination compression parameters from source values */
	jpeg_copy_critical_parameters(srcinfo, dstinfo);
	/* Set progressive/baseline & arithmetic/huffman encode methods */
	mozj_set_encmethods(dstinfo, progss, arith);
	/* Fill output img buffer */
	jpeg_mem_dest(dstinfo, out_jpg, out_size);
	/* Start compressor (note no image data is actually written here) */
	jpeg_write_coefficients(dstinfo, coef_arrays);
	jpeg_finish_compress  ( dstinfo );
	jpeg_finish_decompress( srcinfo );
}

static auto mozjLossyOptim(j_decompress_ptr srcinfo, j_compress_ptr dstinfo, unsigned char **out_jpg, unsigned long *out_size, bool progss, bool arith, char qmax) -> void
{
	JDIMENSION max_scanlines = 8 * srcinfo->max_v_samp_factor;
	JSAMPARRAY plane_pointer[4];

	srcinfo->raw_data_out        = TRUE;
	srcinfo->do_fancy_upsampling = FALSE;

	jpeg_start_decompress(srcinfo);
	jpeg_set_defaults    (dstinfo);

	dstinfo->in_color_space   = srcinfo->out_color_space;
	dstinfo->input_components = srcinfo->output_components;
	dstinfo->data_precision   = srcinfo->data_precision;
	dstinfo->image_width      = srcinfo->image_width;
	dstinfo->image_height     = srcinfo->image_height;

	jpeg_set_colorspace(dstinfo, srcinfo->jpeg_color_space);
	jpeg_set_quality   (dstinfo, qmax, (progss ? TRUE : FALSE));
	mozj_set_encmethods(dstinfo, progss, arith);

	dstinfo->max_v_samp_factor = srcinfo->max_v_samp_factor;
	dstinfo->max_h_samp_factor = srcinfo->max_h_samp_factor;
	dstinfo->raw_data_in       = TRUE;

	for (int i = 0; i < dstinfo->input_components; i++) {
	  dstinfo->comp_info[i].h_samp_factor = srcinfo->comp_info[i].h_samp_factor;
	  dstinfo->comp_info[i].v_samp_factor = srcinfo->comp_info[i].v_samp_factor;

	  plane_pointer[i] = dstinfo->mem->alloc_sarray((j_common_ptr)dstinfo, JPOOL_IMAGE, dstinfo->image_width, 32);
	}
	/* Fill output img buffer */
	jpeg_mem_dest(dstinfo, out_jpg, out_size);
	/* start compression */
	jpeg_start_compress(dstinfo, TRUE);
	/* write image */
	while (dstinfo->next_scanline < dstinfo->image_height) {
		jpeg_read_raw_data (srcinfo, plane_pointer, max_scanlines);
		jpeg_write_raw_data(dstinfo, plane_pointer, max_scanlines);
	}
	jpeg_finish_compress  ( dstinfo );
	jpeg_finish_decompress( srcinfo );
}

auto JpgWrk::optim() -> bool
{
	QByteArray jpg_img;

	bool is_ok = m_parent->qFileLoad(m_index, jpg_img);
	if ( is_ok ) {

		unsigned long out_size = 0;
		unsigned char*out_data = nullptr;

		j_decompress_ptr srcinfo = new jpeg_decompress_struct;
		j_compress_ptr   dstinfo = new jpeg_compress_struct;

		try {
			mozjInit(srcinfo, dstinfo, reinterpret_cast<unsigned char*>(jpg_img.data()), jpg_img.size());
			mozjLosslessOptim(srcinfo, dstinfo, &out_data, &out_size, m_progressive, m_algorithm);

			if (m_quality >= 0) {
				if (m_rawSize > out_size)
					QCoreApplication::postEvent(m_parent, new TaskEvent(m_index, S_Working, m_rawSize, out_size));

				unsigned long tmp_size = out_size, best_size = 0;
				unsigned char*tmp_data = nullptr;

				do {
					jpeg_mem_src    (srcinfo,        (!best_size ? out_data : tmp_data), tmp_size);
					jpeg_read_header(srcinfo, TRUE);   best_size = tmp_size;
					mozjLossyOptim  (srcinfo, dstinfo, &tmp_data, &tmp_size, m_progressive, m_algorithm, m_quality);
				} while (90 < (best_size - tmp_size));

				if (tmp_size < out_size) {
					out_data = tmp_data;
					out_size = tmp_size;
				}
			}
		} catch(QString emsg) {
#ifdef QT_DEBUG
			qDebug() << "mozjpeg: " << emsg;
#endif
			is_ok = false;
		}
		jpeg_destroy_compress  ( dstinfo );
		jpeg_destroy_decompress( srcinfo );

		if (is_ok && m_rawSize > (m_optSize = out_size)) {
			QByteArray cjpg_out((char*)out_data, out_size);
			is_ok = m_parent->qFileStore(m_index, cjpg_out, JPG);
		}
	}
	return is_ok;
}
