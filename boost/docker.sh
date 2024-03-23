#!/bin/bash
set -e

THIS=$(readlink -e $0)
PKG_NAME=$1
VERSION=$2

cd /src/${PKG_NAME}_${VERSION}
/bin/bash /src/${PKG_NAME}_${VERSION}/bootstrap.sh
./b2 --prefix=/src/${PKG_NAME}-${VERSION}/usr/local install

cp $THIS /src/${PKG_NAME}-${VERSION}
