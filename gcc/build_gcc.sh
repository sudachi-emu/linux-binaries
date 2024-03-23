#!/bin/bash
set -e

# This script is meant to make it easy to build GCC using a Docker container.

THIS=$(readlink -e $0)
USER_ID=`id -u`
GROUP_ID=`id -g`
VERSION=12.2.0

if [ ! -d gcc ]; then
    git clone --depth 1 -b "releases/gcc-$VERSION" git://gcc.gnu.org/git/gcc.git
else
    cd gcc
    sudo git clean -fxd
    git restore :/
    cd ..
fi

mkdir -p gcc-$VERSION | true

docker run -v $(pwd):/src -w /src -u root -t yuzuemu/build-environments:linux-fresh /bin/bash /src/docker.sh $VERSION

cp -v $THIS gcc-$VERSION/
tar cv gcc-$VERSION | xz -T0 -c | split --bytes=90MB - gcc-$VERSION.tar.xz.
