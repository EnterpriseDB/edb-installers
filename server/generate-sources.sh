#! /bin/sh
set -xeu
NAME=postgresql
: ${VERSION:?The VERSION environment variable is required}
TARNAME="${NAME}-${VERSION}.${EXTRA_VERSION:-}"
mv postgresql-source "${TARNAME}"

# Run configure on Linux to generate pg_config.h for MSVC compatibility
cd "${TARNAME}"
./configure
cd ..

tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}"
rm -rf "${TARNAME}"
