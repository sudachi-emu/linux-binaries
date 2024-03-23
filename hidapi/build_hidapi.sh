#!/bin/bash

# This script is meant to make it easy to rebuild packages using the
# linux-fresh yuzu-emu container.

# Run this from within the source directory

THIS=$(readlink -e $0)
USER_ID=${1}
GROUP_ID=${2}
VERSION=$(cat VERSION | sed 's/\./_/g')
BASE_NAME=$(readlink -e $(pwd) | sed 's/.*\///g')
ARCHIVE_NAME=${BASE_NAME}_${VERSION}.tar.xz


./bootstrap

mkdir build || true
cd build

../configure
make -j$(nproc)
make install DESTDIR=$(pwd)/out

cd ..


mkdir -pv ${BASE_NAME}/
mv -v build/out/usr/local/* ${BASE_NAME}/
cp -v ${THIS} ${BASE_NAME}/

tar cv ${BASE_NAME} | xz -c > ${ARCHIVE_NAME}

if [ -e ${ARCHIVE_NAME} ]; then
    echo "hidapi package can be found at $(readlink -e ${ARCHIVE_NAME})"
fi

