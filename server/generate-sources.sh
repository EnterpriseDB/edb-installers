#! /bin/sh
set -xeu
NAME=postgresql
: ${VERSION:?The VERSION environment variable is required}
TARNAME="${NAME}-${VERSION}.${EXTRA_VERSION:-}"
mv postgresql-source "${TARNAME}"
tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}"
rm -rf "${TARNAME}"
