#include "Colbi.hpp"
#include <jpeglib.h>

void mozjThrowMsg(j_common_ptr cinfo) {
# ifdef QT_DEBUG
	char error_msg[JMSG_LENGTH_MAX];
	// Call the function pointer to get the error message
	(*cinfo->err->format_message)(cinfo, error_msg);
	qWarning(error_msg);
# endif
	throw cinfo->err->msg_code;
};

static inline void mozjInitDecoder(
	jpeg_decompress_struct *jdec,
	jpeg_compress_struct   *jcom,

	const unsigned char *src_data,
	const unsigned long  src_size
) {
	/* hook src data for decompressor */
	jpeg_mem_src(jdec, src_data, src_size);
	/* this sets default decompress params,
	   then read from img header e.g. colorspace, w/h etc */
	jpeg_read_header(jdec, TRUE);
	/* wee need set profile before do `jpeg_set_defaults` for compressor */
	jpeg_c_set_int_param(jcom, JINT_COMPRESS_PROFILE, JCP_MAX_COMPRESSION);
}

static inline void mozjLosslessOptim(
	jpeg_decompress_struct *jdec,
	jpeg_compress_struct   *jcom,

	unsigned char **out_data,
	unsigned long  *out_size
) {
	/* Read source file as DCT coefficients */
	jvirt_barray_ptr *coef_arrays = jpeg_read_coefficients(jdec);
	/* This fn first do `jpeg_set_defaults` and then copy image params 
	   like color space and w/h from decompressor (src) to compressor (dest) */
	jpeg_copy_critical_parameters(jdec, jcom);
	/* JCP_MAX_COMPRESSION sets progressive as default
	jpeg_simple_progression(jcom); */
	jcom->optimize_coding = TRUE;
	jcom->dct_method = JDCT_ISLOW;
	/* Fill output img buffer */
	jpeg_mem_dest(jcom, out_data, out_size);
	/* Start compressor (note no image data is actually written here) */
	jpeg_write_coefficients(jcom, coef_arrays);
	/* Finish compression (write result) */
	jpeg_finish_compress(jcom);
	jpeg_finish_decompress(jdec);
}

static inline void mozjLossyOptim(
	jpeg_decompress_struct *jdec,
	jpeg_compress_struct   *jcom,

	unsigned char **tmp_data,
	unsigned long  *tmp_size,

	int qmax
) {
	JDIMENSION max_lines = 8 * jdec->max_v_samp_factor;
	signed int i, max_comps = jdec->num_components;
	JSAMPARRAY plane_pointer[4];

	jdec->raw_data_out = TRUE;
	jdec->do_fancy_upsampling = FALSE;
	jdec->two_pass_quantize = TRUE;

	jpeg_start_decompress(jdec);
	jpeg_copy_critical_parameters(jdec, jcom);

	jpeg_c_set_int_param(jcom, JINT_DC_SCAN_OPT_MODE, 1);
	jpeg_set_quality    (jcom, qmax, TRUE);

	jcom->max_v_samp_factor = jdec->max_v_samp_factor;
	jcom->max_h_samp_factor = jdec->max_h_samp_factor;

	jcom->raw_data_in = TRUE;
	jcom->optimize_coding = TRUE;
	jcom->dct_method = JDCT_ISLOW;

	for (i = 0; i < max_comps; i++) {
		plane_pointer[i] = (*jcom->mem->alloc_sarray)((j_common_ptr)jcom, JPOOL_IMAGE, jcom->image_width, 32);
	}
	/* Fill output img buffer */
	jpeg_mem_dest(jcom, tmp_data, tmp_size);
	/* start compression */
	jpeg_start_compress(jcom, TRUE);
	/* write image */
	while (jcom->next_scanline < jcom->image_height) {
		jpeg_read_raw_data (jdec, plane_pointer, max_lines);
		jpeg_write_raw_data(jcom, plane_pointer, max_lines);
	}
	jpeg_finish_compress  (jcom);
	jpeg_finish_decompress(jdec);
}

auto Jpg_optim(Colbi *parent, int index, QByteArray &src_jpg, bool progss, bool arith, int qmax) -> stat_t
{
	jpeg_error_mgr djerr = { .trace_level = 0 };
	jpeg_error_mgr cjerr = { .trace_level = 0 };

	jpeg_decompress_struct jdec = { .err = jpeg_std_error(&djerr) };
	jpeg_compress_struct   jcom = { .err = jpeg_std_error(&cjerr) };

	/* Initialize the JPEG decompression object with default error handling. */
	jpeg_create_decompress(&jdec);
	/* Initialize the JPEG compression object with default error handling. */
	jpeg_create_compress(&jcom);

	djerr.error_exit = cjerr.error_exit = mozjThrowMsg;

	unsigned long src_size, out_size, tmp_size;
	unsigned char*src_data,*out_data,*tmp_data;

	stat_t status;
	int i, diff;

	out_data = tmp_data = nullptr;
	out_size = tmp_size = diff = 0;
	src_data = reinterpret_cast<unsigned char*>(src_jpg.data());
	src_size = src_jpg.size();
	try {
		if (qmax >= 0) {
			mozjInitDecoder(&jdec, &jcom, src_data, src_size);
			mozjLossyOptim(&jdec, &jcom, &tmp_data, &tmp_size, qmax);

			if ((diff = src_size - tmp_size)) {
				QCoreApplication::postEvent(parent,
					new TaskEvent(index, S_Working, src_size, tmp_size));
			}
		}
		mozjInitDecoder(&jdec, &jcom, (diff > 0 ? tmp_data : src_data), (diff > 0 ? tmp_size : src_size));
		mozjLosslessOptim(&jdec, &jcom, &out_data, &out_size);
		status = S_Complete;
	} catch(int ecode) {
		status = S_Error;
	}
	if (status == S_Complete)
		MergeSmaller(src_jpg, out_data, out_size, false);
	/* Finish compression and release memory */
	if (tmp_size) delete[] tmp_data;
	jpeg_destroy_compress  (&jcom);
	jpeg_destroy_decompress(&jdec);

	return status;
}
