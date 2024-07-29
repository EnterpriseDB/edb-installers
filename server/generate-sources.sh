#! /bin/sh

set -xeu

NAME=postgresql

: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}

WORKDIR=$(pwd)/src
cd ${WORKDIR}
TARNAME="${NAME}-${SOURCE_VERSION}"
wget ${URL}
md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
mv ${TARNAME}.tar.bz2 ../