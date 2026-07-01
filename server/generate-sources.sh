#! /bin/sh
set -xeu
NAME=postgresql
: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}
WORKDIR=$(pwd)
TARNAME="${NAME}-${SOURCE_VERSION}"
cd ${WORKDIR}

if [ -n "${URL:-}" ]; then
  # release case: download tarball from URL
  wget -O "${TARNAME}.tar.bz2" ${URL}
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
else
  # snapshot case: create tarball from git checkout
  cp -r src/ "${TARNAME}"
  tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}/"
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
  rm -rf "${TARNAME}"
fi
