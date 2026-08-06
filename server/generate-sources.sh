#! /bin/sh
set -xe
NAME=postgresql
: ${VERSION:?The VERSION environment variable is required}
: ${EXTRA_VERSION:?The EXTRA_VERSION environment variable is required}

CONF_ARGS="--without-icu --without-readline"
WORKDIR=$(pwd)
TARNAME="${NAME}-${VERSION}.${EXTRA_VERSION}"

if [ -n "${URL:-}" ]; then
  # release case: download tarball from URL
  echo "Downloading source tarball from: ${URL}"
  wget -O "${TARNAME}.tar.bz2" ${URL}
  echo "Tarball downloaded: ${TARNAME}.tar.bz2"
  echo "Tarball md5sum: $(md5sum ${TARNAME}.tar.bz2)"
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
else
  # snapshot case: build docs and create tarball
  echo "Source commit hash: $(git -C src rev-parse HEAD)"
  echo "Source branch/ref: $(git -C src rev-parse --abbrev-ref HEAD)"

  # install doc build dependencies
  sudo apt-get install -y docbook-xsl docbook-xml xsltproc libxml2-utils

  # build HTML docs
  cd src
  ./configure $CONF_ARGS
  make -C doc/src/sgml html
  cd ${WORKDIR}

  # create tarball
  cp -r src/ "${TARNAME}"
  tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}/"
  echo "Tarball created: ${TARNAME}.tar.bz2"
  echo "Tarball md5sum: $(md5sum ${TARNAME}.tar.bz2)"
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
  rm -rf "${TARNAME}"
fi
