#! /bin/sh
set -xeu
NAME=postgresql
: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}

TARNAME="${NAME}-${SOURCE_VERSION}"
tar -cjf "${TARNAME}.tar.bz2" -C $(pwd)/.. src --transform "s/^src/${TARNAME}/"
md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
mv ${TARNAME}.tar.bz2 ../
