#include <main.h>
#include <lib/mozjpeg/jpeglib.h>
#include <lib/mozjpeg/jerror.h>

//static const char * const cdjpeg_message_table[] = {
//#include "lib/mozjpeg/cderror.h"
//  NULL
//};

auto qFileLoad(const QString path, QByteArray &blob) -> bool
{
	QFile file(path);

	bool ok;
	if ((ok  = file.open(QIODevice::ReadOnly))) {
		blob = file.readAll();
	}
	return ok;
}

auto qFileStore(const QString path, const QByteArray &blob) -> void {
	QFile file(path);

	if (!file.open(QIODevice::WriteOnly))
		return;
}

static auto mozjoptim(const unsigned char* src_jpg, const long long src_bytes) -> void {
	int oldquality = 200;

	struct jpeg_decompress_struct dinfo;
	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jderr, jcerr;

	/* initialize decompression object */
	dinfo.err = jpeg_std_error(&jderr);
	jpeg_create_decompress(&dinfo);
	//jderr.addon_message_table = cdjpeg_message_table;
	jderr.first_addon_message = 1000;
	jderr.last_addon_message  = 1007;
	jpeg_mem_src(&dinfo, src_jpg, src_bytes);

	/* initialize compression object */
	cinfo.err = jpeg_std_error(&jcerr);
	jpeg_create_compress(&cinfo);
	//jcerr.addon_message_table = cdjpeg_message_table;
	jcerr.first_addon_message = 1000;
	jcerr.last_addon_message  = 1007;
	cinfo.in_color_space      = JCS_RGB; /* arbitrary guess */
	jpeg_set_defaults(&cinfo);
}


auto JpgWrk::optim() -> bool
{
	QByteArray jpg_img;

	bool is_ok = qFileLoad(m_inFile, jpg_img);
	if ( is_ok ) {
		//reinterpret_cast<unsigned char*>(jpg_img.data());
		qDebug() << jpg_img.size() << m_rawSize;
	}
	return is_ok;
}
