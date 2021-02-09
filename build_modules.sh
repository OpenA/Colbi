#!/bin/bash

LIBDIR="$PWD/lib"
DIST="_Dist_"
libs=('gifsicle' 'libimagequant' 'mozjpeg' 'zopfli')

function build_gifsicle() {
	cd "$LIBDIR/gifsicle"
	autoreconf -i
	./configure --disable-gifview --disable-gifdiff --disable-threads
	make
    ar -rcs libgifsicle.a src/fmalloc.o src/gifread.o src/gifwrite.o src/giffunc.o src/gifunopt.o src/merge.o src/optimize.o src/quantize.o src/xform.o
}
function build_libimagequant() {
	mkdir -p "$LIBDIR/$DIST/imagequant"
	cd "$LIBDIR/libimagequant"
	./configure --enable-sse
	make static && mv libimagequant.a "$LIBDIR/$DIST/imagequant"
	echo $'\n clean:'
	make clean
	echo $'\n ====== libimagequant build complete ======\n\n'
}
function build_mozjpeg() {
	mkdir -p "$LIBDIR/$DIST/mozjpeg"
	cd "$LIBDIR/$DIST/mozjpeg"
	cmake ../../mozjpeg -DENABLE_SHARED=0 -DENABLE_STATIC=1 -DWITH_TURBOJPEG=0 -DPNG_SUPPORTED=0 -DWITH_JPEG8=1 -DWITH_ARITH_ENC=1 -DWITH_ARITH_DEC=1
	make
	echo $'\n ====== mozjpeg build complete ======\n\n'
}
function build_zopfli() {
	mkdir -p "$LIBDIR/$DIST/zopfli"
	cd "$LIBDIR/zopfli"
	make libzopfli.a libzopflipng.a
	ar rcs "$LIBDIR/$DIST/zopfli/libzopflipng.a" obj/src/*/*.o obj/src/*/*/*.o
	echo $'\n clean:'
	make clean
	echo $'\n ====== mozjpeg build complete ======\n\n'
}

case $1 in
	'')
	git submodule update --init --recursive

	for libname in "${libs[@]}"; do
		build_$libname
	done
	;;
	'clean')
	git submodule foreach git reset --hard
	git submodule foreach git clean -f -d

	rm rf -R "$LIBDIR/$DIST"

	for libname in "${libs[@]}"; do
		cd "$LIBDIR/$libname"
		make clean
	done
	;;
	'update')
	git submodule foreach git pull origin master
	;;
	*)
		build_$1
	;;
esac
