#include <main.h>
#include <lib/mozjpeg/jpeglib.h>
#include <lib/mozjpeg/jerror.h>

auto qFileLoad(const QString path, QByteArray &blob) -> bool
{
	QFile file(path);
	 bool ok;
	if (( ok = file.open(QIODevice::ReadOnly))) {
		blob = file.readAll();
		file.close();
	}
	return ok;
}

auto qFileStore(const QString path, const QByteArray &blob) -> bool
{
	QFile file(path);
	 bool ok;
	if (( ok = file.open(QIODevice::WriteOnly))) {
		file.write(blob);
		file.close();
	}
	return ok;
}

static auto mozjoptim(const unsigned char* src_jpg, const unsigned long src_size, unsigned long &out_size, QString file) -> void
{
	char quality     = -1;
	bool progressive = true;

	struct jpeg_decompress_struct srcinfo;
	struct jpeg_compress_struct   dstinfo;
	struct jpeg_error_mgr jsrcerr,jdsterr;

	jvirt_barray_ptr *coef_arrays;
	unsigned char* out_jpg;

	/* Initialize the JPEG decompression object with default error handling. */
	srcinfo.err = jpeg_std_error(&jsrcerr);
	jpeg_create_decompress(&srcinfo);

	/* Initialize the JPEG compression object with default error handling. */
	dstinfo.err = jpeg_std_error(&jdsterr);
	jpeg_create_compress(&dstinfo);

	jsrcerr.trace_level = jdsterr.trace_level;
	srcinfo.mem->max_memory_to_use = dstinfo.mem->max_memory_to_use;

#ifdef C_ARITH_CODING_SUPPORTED
	/* Use arithmetic coding. */
	dstinfo.arith_code = TRUE;
	/* No table optimization required for AC */
	dstinfo.optimize_coding = FALSE;
#else
	dstinfo.optimize_coding = TRUE;
#endif

	jpeg_mem_src(&srcinfo, src_jpg, src_size);
	jpeg_save_markers(&srcinfo, JPEG_COM, 0xFFFF);

	/* Read file header */
	jpeg_read_header(&srcinfo, TRUE);

	/* Read source file as DCT coefficients */
	coef_arrays = jpeg_read_coefficients(&srcinfo);

	/* Initialize destination compression parameters from source values */
	jpeg_copy_critical_parameters(&srcinfo, &dstinfo);

	if (srcinfo.progressive_mode || progressive) {
		jpeg_simple_progression(&dstinfo);
	} else {
		dstinfo.scan_info = NULL; // Explicitly disables progressive if libjpeg had it on by default
		dstinfo.num_scans = 0;
	}
	jpeg_mem_dest(&dstinfo, &out_jpg, &out_size);

	/* Start compressor (note no image data is actually written here) */
	jpeg_write_coefficients(&dstinfo, coef_arrays);
	QByteArray blob((char *)out_jpg);
	qFileStore(file, blob);

	jpeg_finish_compress    ( &dstinfo );
	jpeg_destroy_compress   ( &dstinfo );
	jpeg_finish_decompress  ( &srcinfo );
	jpeg_destroy_decompress ( &srcinfo );
}


auto JpgWrk::optim() -> bool
{
	QByteArray jpg_img;

	bool is_ok = qFileLoad(m_inFile, jpg_img);
	if ( is_ok ) {
		QByteArray jpg_out;
		unsigned long out_size = 0;
		try {
			mozjoptim(
				reinterpret_cast<unsigned char*>(jpg_img.data()),
				jpg_img.size(), out_size, m_outFile
			);
		} catch(QString e){
			qDebug() << "error blat";
			is_ok = false;
		}
		if (is_ok) {
			m_optSize = out_size;
			//is_ok = qFileStore(m_outFile, jpg_out);
			qDebug() << jpg_img.size() << out_size;
		}
	}
	return is_ok;
}
