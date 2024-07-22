#! /bin/sh

set -xeu

NAME=postgresql

: ${VERSION:?The VERSION environment variable is required}

WORKDIR=$(pwd)/src
cd ${WORKDIR}
TARNAME="${NAME}-${VERSION}.${EXTRA_VERSION:-}"
wget https://download.postgresql.org/pub/source/v${VERSION}.${EXTRA_VERSION}/postgresql-${VERSION}.${EXTRA_VERSION}.tar.bz2
md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
mv ${TARNAME}.tar.bz2 ../
