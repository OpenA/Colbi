#!/bin/bash

LIBDIR="$PWD/lib"
libs=('gifsicle' 'libimagequant' 'mozjpeg' 'zopfli')

function build_gifsicle() {
	cd "$LIBDIR/gifsicle"
	autoreconf -i
	./configure --disable-gifview --disable-gifdiff --disable-threads
	make
    ar -rcs libgifsicle.a src/fmalloc.o src/gifread.o src/gifwrite.o src/giffunc.o src/gifunopt.o src/merge.o src/optimize.o src/quantize.o src/xform.o
}
function build_libimagequant() {
	cd "$LIBDIR/libimagequant"
	./configure --enable-sse
	make static
}
function build_mozjpeg() {
	cd "$LIBDIR/mozjpeg"
	cmake . -DENABLE_SHARED=0 -DENABLE_STATIC=1 -DWITH_TURBOJPEG=0 -DPNG_SUPPORTED=0 -DWITH_JPEG8=1 -DWITH_ARITH_ENC=1 -DWITH_ARITH_DEC=1
	make
}
function build_zopfli() {
	cd "$LIBDIR/zopfli"
	sed -i 's/libzopflipng.a: $(LODEPNG_OBJ) $(ZOPFLIPNGLIB_OBJ)/libzopflipng.a: $(LODEPNG_OBJ) $(ZOPFLILIB_OBJ) $(ZOPFLIPNGLIB_OBJ)/' Makefile
	make libzopflipng.a
}

case $1 in
	'')
	git submodule update --init --recursive

	for libname in "${libs[@]}"; do
		echo `build_$libname`
	done
	;;
	'clean')
	git submodule foreach git reset --hard
	git submodule foreach git clean -f -d

	for libname in "${libs[@]}"; do
		cd "$LIBDIR/$libname"
		make clean
	done
	;;
	*)
		echo `build_$1`
	;;
esac
