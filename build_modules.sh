#!/bin/sh

LIBDIR="$PWD/lib"
STABLE="$1"

git_reset_stable() {
	git -C 'lib/libimagequant' reset --hard cfda870
	git -C 'lib/mozjpeg'       reset --hard 8fb32c0
	git -C 'lib/zopfli'        reset --hard 7113f4e
}

git submodule update --init --recursive

if [[ $STABLE == 'stable' ]]
	then git_reset_stable
fi

# build imagequanl library
cd "$LIBDIR/libimagequant"
./configure --enable-sse
make shared

# build mozjpeg library
cd "$LIBDIR/mozjpeg"
cmake .. -DENABLE_STATIC=0 -DWITH_TURBOJPEG=0 -DPNG_SUPPORTED=0 -DWITH_JPEG8=1 -DWITH_ARITH_ENC=1 -DWITH_ARITH_DEC=1
make

# build zopfli library
cd "$LIBDIR/zopfli"
make libzopflipng
ln -s libzopflipng.so.* libzopflipng.so.1
ln -s libzopflipng.so.1 libzopflipng.so
