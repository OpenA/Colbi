#include <main.h>
#include <gifsi.h>

auto GifWrk::optim() -> bool
{
	QByteArray gif_src;

	bool is_ok = m_parent->qFileLoad(m_index, gif_src);
	if ( is_ok ) {
		// create memory object
		Gif_CompressInfo gCInf;
		gCInf.flags = 0;
		gCInf.lossy = m_quality;
		// decode gif data from memory
		Gif_Stream *gStrm = new Gif_Stream;
		Gif_ReadData(gStrm,
			reinterpret_cast<unsigned char *>(gif_src.data()),
							(unsigned int   )(gif_src.size()));

		// get frames count
		quint32 gNumFrms = gStrm && !gStrm->errors.num ? Gif_ImageCount(gStrm) : 0;

		if ((is_ok = gNumFrms)) {
			unsigned long  out_size;
			unsigned char *out_data = nullptr;
			Gif_FullOptimizeFragments(gStrm, 3, 1, &gCInf);
			out_size = Gif_FullWriteData(gStrm, out_data, &gCInf);

			if (is_ok && m_rawSize > (m_optSize = out_size)) {
				QByteArray cgif_out((char*)out_data, out_size);
				is_ok = m_parent->qFileStore(m_index, cgif_out, GIF);
			}
		}
		Gif_FreeStream(gStrm);
	}
	return is_ok;
}
