#include <main.h>
#include <gifsi.h>

static auto gifAssignQuantization(Gif_Stream *gStrm, Gif_Dither plan, quint16 colors) -> void
{
	unsigned int ncols = colors;
	quint8 mW = 3, mH = 3;

	if (plan == DiP_FloydSteinberg)
		mW = mH = 127;

	Gif_ColorTransform gCT;
	Gif_InitColorTransform(&gCT);
	Gif_SetDitherPlan(&gCT, plan, mW, mH, colors);

	Gif_Colormap *gCmap = Gif_NewDiverseColormap(gStrm, &gCT, CD_Blend, &ncols);

	//qDebug() << "colors: " << colors << " at source: " << ncols << " plan: " << plan;
	if (ncols > colors)
		Gif_FullQuantizeColors(gStrm, &gCT, gCmap, (Gif_CompressInfo){0,0});
	Gif_FreeColormap(gCmap);
	Gif_FreeColorTransform(&gCT);
}

auto GifWrk::optim() -> bool
{
	QByteArray gif_src;

	bool is_ok = m_parent->qFileLoad(m_index, gif_src);
	quint16 colors = (quint8)m_quality + 1;
	Gif_Dither plan = (Gif_Dither)(m_dither + 1);

	qDebug() << "colors: " << colors << " lossy:" << m_lossy;
	if ( is_ok ) {
		// create memory object
		Gif_CompressInfo gCInf = {
			.flags = GIF_WRITE_DROP_EXTRA | GIF_WRITE_TRUNC_PADS | GIF_OPTIZ_LVL3,
			.lossy = m_lossy
		};
		Gif_Stream *gStrm;

		// decode gif data from memory
		is_ok = (
			Gif_NewStream(gStrm, nullptr) &&
			Gif_ReadData (gStrm, reinterpret_cast<unsigned char *>(gif_src.data()), gif_src.size())
		);
		// get frames count
		if (is_ok)
			is_ok = !gStrm->errors.num && Gif_GetImagesCount(gStrm);
		if (is_ok) {
			unsigned long  out_size;
			unsigned char *out_data;

			if (gStrm->global->ncol > colors || gStrm->has_local_colors)
				   gifAssignQuantization(gStrm, plan, colors);

					   Gif_FullOptimize (gStrm, gCInf);
			out_size = Gif_FullWriteData(gStrm, gCInf, &out_data);

			if (is_ok && m_rawSize > (m_optSize = out_size)) {
				QByteArray cgif_out((char*)out_data, out_size);
				is_ok = m_parent->qFileStore(m_index, cgif_out, GIF);
			}
		}
		Gif_FreeStream(gStrm);
	}
	return is_ok;
}
