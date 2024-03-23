#!/bin/bash
set -e

THIS=$(readlink -e $0)
VERSION=$1
UBUNTU=$2

OUT=/src/binutils-$VERSION-$UBUNTU

mkdir build
cd build
/src/binutils-$VERSION/configure
make -j$(nproc)

make -j$(nproc) install DESTDIR=$OUT
cp $THIS $OUT
