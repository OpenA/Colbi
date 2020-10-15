#!/bin/sh

PREFIX:="$PWD"
STABLE:="$1"

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
cd "$PREFIX/lib/libimagequant"
./configure --enable-sse
make shared

# build mozjpeg library
cd "$PREFIX/lib/mozjpeg"
cmake . -DENABLE_STATIC=0 -DPNG_SUPPORTED=0 -DWITH_12BIT=0
make

# build zopfli library
cd "$PREFIX/lib/zopfli"
make libzopflipng
ln -s libzopflipng.so.* libzopflipng.so.1
ln -s libzopflipng.so.1 libzopflipng.so
