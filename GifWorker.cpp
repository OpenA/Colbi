#include <main.h>

auto GifWrk::optim() -> bool
{
	QByteArray gif_src;

	bool is_ok = m_parent->qFileLoad(m_index, gif_src);
	if ( is_ok ) {
		// create memory object
		/*const Gif_Record gRec = {
			.data   = reinterpret_cast<unsigned char *>(gif_src.data()),
			.length = (unsigned int)gif_src.size()
		};
		// decode gif data from memory
		Gif_Stream *gStrm = Gif_ReadRecord(&gRec);
		// get frames count
		int gNumFrms = gStrm && !gStrm->errors ? Gif_ImageCount(gStrm) : 0;

		if ((is_ok = gNumFrms)) {
			Gif_CompressInfo gCInf;
			Gif_InitCompressInfo(&gCInf);
			optimize_fragments(gStrm, 0xFFFF, (int)(gRec.length > 0xB000000));
			FILE *f = fopen("/home/arrte/_/Developer/Colbi/lib/gifsicle/ok.gif", "wb");
			if (f) {
				Gif_FullWriteFile(gStrm, &gCInf, f);
				fclose(f);
			}
		}
		Gif_DeleteStream(gStrm);*/
	}
	return is_ok;
}
