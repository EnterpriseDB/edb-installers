#! /bin/sh

set -xeu

NAME=postgresql

: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}

WORKDIR=$(pwd)/src
cd ${WORKDIR}
TARNAME="${NAME}-${SOURCE_VERSION}"
wget -O "${TARNAME}.tar.gz" ${URL}
md5sum "${TARNAME}.tar.gz" > "${TARNAME}.tar.gz.md5"
mv ${TARNAME}.tar.gz ../
