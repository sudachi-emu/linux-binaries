#!/bin/bash
set -e
# This script is meant to make it easy to build a package using a Docker container.

# Run this from the same directory as source directory

THIS=$(readlink -e $0)
USER_ID=`id -u`
GROUP_ID=`id -g`
VERSION=1_81_0
PKG_NAME=boost

mkdir -p $PKG_NAME-$VERSION

docker run -v $(pwd):/src -w /src -u root -t yuzuemu/build-environments:linux-fresh /bin/bash -ex /src/docker.sh $PKG_NAME $VERSION

cp -v $THIS $PKG_NAME-$VERSION/
tar cv $PKG_NAME-$VERSION | xz -T0 -c > $PKG_NAME-$VERSION.tar.xz
