#! /bin/sh
set -xeu
NAME=postgresql
: ${VERSION:?The VERSION environment variable is required}
: ${EXTRA_VERSION:?The EXTRA_VERSION environment variable is required}
WORKDIR=$(pwd)
TARNAME="${NAME}-${VERSION}.${EXTRA_VERSION}"
cd ${WORKDIR}

if [ -n "${URL:-}" ]; then
  # release case: download tarball from URL
  echo "Downloading source tarball from: ${URL}"
  wget -O "${TARNAME}.tar.bz2" ${URL}
  echo "Tarball downloaded: ${TARNAME}.tar.bz2"
  echo "Tarball md5sum: $(md5sum ${TARNAME}.tar.bz2)"
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
else
  # snapshot case: create tarball from git checkout
  echo "Source commit hash: $(git -C src rev-parse HEAD)"
  echo "Source branch/ref: $(git -C src rev-parse --abbrev-ref HEAD)"
  cp -r src/ "${TARNAME}"
  tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}/"
  echo "Tarball created: ${TARNAME}.tar.bz2"
  echo "Tarball md5sum: $(md5sum ${TARNAME}.tar.bz2)"
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
  rm -rf "${TARNAME}"
fi
