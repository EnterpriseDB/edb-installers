#! /bin/sh
set -xe
NAME=postgresql
: ${VERSION:?The VERSION environment variable is required}
: ${EXTRA_VERSION:?The EXTRA_VERSION environment variable is required}

CONF_ARGS="--without-icu"
MAKE_ARGS="distdir=postgresql-${VERSION}.${EXTRA_VERSION}"
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
  # snapshot case: build docs and create tarball using docker
  echo "Source commit hash: $(git -C src rev-parse HEAD)"
  echo "Source branch/ref: $(git -C src rev-parse --abbrev-ref HEAD)"

  USERMAP=$(docker run --rm -v "$WORKDIR":"$WORKDIR" ghcr.io/enterprisedb/platform/postgresql-builder stat -c %u:%g "$WORKDIR")
  docker run --rm -i -u $USERMAP -w ${WORKDIR} -v ${WORKDIR}:${WORKDIR}:rw ghcr.io/enterprisedb/platform/postgresql-builder /bin/bash <<-EOF
    cd src
    set -xe
    ./configure $CONF_ARGS
    make -s dist $MAKE_ARGS
    for file in *.tar.*; do md5sum \${file} > \${file}.md5; done
    cp *.tar.bz2 ${WORKDIR}
EOF

  echo "Tarball created: ${TARNAME}.tar.bz2"
  echo "Tarball md5sum: $(md5sum ${TARNAME}.tar.bz2)"
  md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
fi
