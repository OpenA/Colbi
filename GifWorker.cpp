#include <main.h>
#include <gifsi.h>

static auto gifTryAssignQuantization(Gif_Stream *gStrm, Gif_Dither plan, quint16 colors) -> void
{
	quint32 ncols;
	quint8 mW = 3, mH = 3;

	if (plan == DiP_FloydSteinberg)
		mW = mH = 127;

	Gif_ColorTransform gCT;
	Gif_InitColorTransform(&gCT);
	Gif_SetDitherPlan(&gCT, plan, mW, mH, colors);

	ncols = Gif_MakeDiverseColormap(gStrm, &gCT, CD_Blend, colors);

	if (ncols > colors) {
		Gif_SetDitherPlan(&gCT, plan, mW, mH, colors);
		Gif_QuantizeColors(gStrm, &gCT);
	} else
		Gif_FreeColormap(gCT.div_colmap);
	Gif_FreeColorTransform(&gCT);
}

auto GifWrk::optim() -> bool
{
	QByteArray gif_src;

	bool is_ok = m_parent->qFileLoad(m_index, gif_src);

	quint16  colors = 256;
	Gif_Dither plan = DiP_FloydSteinberg;

	if (m_colors >= 2 && m_colors <= 256) {
		colors = m_colors;
		plan   = (Gif_Dither)(m_dither + 1);
	}

	//qDebug() << "colors: " << colors << " lossy:" << m_lossy;
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
				gifTryAssignQuantization(gStrm, plan, colors);

			/* ~~~~ */ Gif_FullOptimize (gStrm, gCInf);
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
