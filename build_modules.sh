#!/bin/bash

LIBDIR="$PWD/lib"
DIST="_Dist_"
libs=('libgifsi' 'libimagequant' 'mozjpeg' 'zopfli' 'svgo')
module="$2"

function build_svgo() {
	mkdir -p "$LIBDIR/$DIST"
	cd "$LIBDIR/svgo"
	npm install && npm install babelify @babel/core @babel/cli @babel/preset-env @babel/plugin-transform-spread
	browserify lib/svgo.js -t [ babelify --presets [ @babel/preset-env ] --plugins [ @babel/plugin-transform-spread ] ] | terser -c -m -f max_line_len=512 -o ../_Dist_/svgo.js
	echo $'\n ====== svgo build complete ======\n\n'
}
function build_libgifsi() {
	mkdir -p "$LIBDIR/$DIST/libgifsi"
	cd "$LIBDIR/$DIST/libgifsi"
	cmake ../../libgifsi -DENABLE_SHARED=0 -DBUILD_GIFSICLE=0 -DWITH_SIMD=1
	make
	echo $'\n ====== libgifsi build complete ======\n\n'
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

	if [ -n $module ]; then
		cd "$LIBDIR/$module"

		git reset --hard
		git clean -f -d

		rm rf -R "$LIBDIR/$DIST/$module"
		exit
	fi

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
