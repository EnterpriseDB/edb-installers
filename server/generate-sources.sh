#! /bin/sh

set -xeu

NAME=postgresql

: ${VERSION:?The VERSION environment variable is required}

WORKDIR=$(pwd)/src
cd ${WORKDIR}
TARNAME="${NAME}-${VERSION}.${EXTRA_VERSION:-}"
wget ${URL}
md5sum "postgresql-15-snapshot.tar.bz2" > "${TARNAME}.tar.bz2.md5"
mv postgresql-15-snapshot.tar.bz2 ../
