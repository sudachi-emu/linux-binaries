#!/bin/bash

# Kicks off the build script using the linux-fresh build container.

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <Source directory> <Build script>"
    exit
fi
UID=`id -u`
GID=`id -g`

SRC_DIR=$(readlink -e $1)
SRC_DIR_BASENAME=$(basename ${SRC_DIR})
SCRIPT=$(readlink -e $2)
SCRIPT_BASENAME=$(basename ${SCRIPT})

cp ${SCRIPT} ${SRC_DIR}
docker run -v ${SRC_DIR}:/${SRC_DIR_BASENAME} -w /${SRC_DIR_BASENAME} -u root -t yuzuemu/build-environments:linux-fresh /bin/bash /${SRC_DIR_BASENAME}/${SCRIPT_BASENAME} ${UID} ${GID}
exit
SRC_DIR=${SRC_DIR}/qtwebengine
docker run -v ${SRC_DIR}:/${SRC_DIR_BASENAME} -w /${SRC_DIR_BASENAME} -u root -t yuzuemu/build-environments:linux-fresh /bin/bash /${SRC_DIR_BASENAME}/${SCRIPT_BASENAME} ${UID} ${GID}

