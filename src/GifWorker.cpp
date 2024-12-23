#include "Colbi.hpp"
#include <gifsi.h>

static auto gifTryAssignQuantization(Gif_Stream *gStrm, Gif_Dither plan, int colors) -> void
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

auto Colbi::Gif_optim(int index, QByteArray &gif_src, int colors, int plan, float lossy) -> stat_t
{
	stat_t status = S_Error;

	unsigned char *out_data,*tmp_data = reinterpret_cast<unsigned char *>(gif_src.data());
	unsigned long  out_size, tmp_size = gif_src.size();

	Gif_Dither dither;

#ifdef QT_DEBUG
	QMessageLogger log("GifWorker.cpp", 26, "Gif_optim");
#endif
	if (colors < 2 || colors > 256) {
		colors = 256;
		dither = DiP_FloydSteinberg;
	} else {
		dither = (Gif_Dither)(plan + 1);
	}
#ifdef QT_DEBUG
	log.debug() << "colors: " << colors << " lossy: " << lossy << Qt::endl;
#endif
	// create memory object
	Gif_Stream *stream;
	Gif_CompressInfo info;

	info.flags = GIF_WRITE_DROP_EXTRA | GIF_WRITE_TRUNC_PADS | GIF_OPTIZ_LVL3,
	info.lossy = lossy;
	// decode gif data from memory
	if (Gif_NewStream(stream, nullptr) &&
	    Gif_ReadData( stream, tmp_data, tmp_size )) {

		int i = Gif_GetImagesCount(stream); // get frames count
		if (i != 0) {
			if (stream->global->ncol > colors || stream->has_local_colors)
				gifTryAssignQuantization(stream, dither, colors);

			/* ~~~~ */ Gif_FullOptimize (stream, info);
			out_size = Gif_FullWriteData(stream, info, &out_data);

			if (gif_src.size() > out_size) {
				gif_src.resize(  out_size  );
				for (i = 0; i  < out_size; i++)
					gif_src[i] = out_data[i];
			}
		}
#ifdef QT_DEBUG
		else log.warning("no frames in image");
#endif
		status = S_Complete;
	}
#ifdef QT_DEBUG
	else log.fatal("can't read data");
#endif
	Gif_FreeStream(stream);
	return status;
}
