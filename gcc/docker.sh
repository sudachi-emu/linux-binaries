#!/bin/bash
set -e

THIS=$(readlink -e $0)

mkdir gcc/build
cd gcc/build
/src/gcc/configure --enable-languages=c,c++ --disable-multilib
make -j$(nproc)

mkdir gcc-$1 | true
make -j$(nproc) install DESTDIR=/src/gcc-$1
cp $THIS /src/gcc-$1
