#!/bin/bash
set -e

# This script is meant to make it easy to build GNU binutils using a Docker container.

THIS=$(readlink -e $0)
USER_ID=`id -u`
GROUP_ID=`id -g`
VERSION=2.40
UBUNTU=focal

PKG=binutils-${VERSION}
OUT=$PKG-$UBUNTU

wget -nc https://ftp.gnu.org/gnu/binutils/$PKG.tar.xz
tar xf $PKG.tar.xz

mkdir -p $OUT | true

docker run -v $(pwd):/src -w /src -u root -t yuzuemu/build-environments:linux-fresh /bin/bash /src/docker.sh $VERSION $UBUNTU

cp -v $THIS $OUT
tar cv $OUT | xz -T0 -c | split --bytes=90MB - $OUT.tar.xz.
