#!/bin/bash
#
# Configure, build and install PostGIS (with docs) into <build-stage> via DESTDIR.
#
# Usage: compile.sh <source-dir> <dep-prefix> <pgsql-dir> <build-stage>
#
# Expects PG_ARCH_OSX_CFLAGS and MACOSX_DEPLOYMENT_TARGET to be set, and
# docbook-xsl to be installed with Homebrew.

set -xe

SRC="$1"; DEP_PREFIX="$2"; PGSQL="$3"; BUILD_STAGE="$4"

cd "$SRC"

export PATH="$DEP_PREFIX/bin:$PATH"
export CFLAGS="$PG_ARCH_OSX_CFLAGS" CXXFLAGS="$PG_ARCH_OSX_CFLAGS"
export LDFLAGS="-L$DEP_PREFIX/lib"
export PROJ_CFLAGS="-I$DEP_PREFIX/include" PROJ_LIBS="-L$DEP_PREFIX/lib -lproj"
XSLDIR="$(brew --prefix docbook-xsl)/docbook-xsl"

# PostGIS 3.7 dropped address_standardizer
ADDR_STD=(); [ -d extensions/address_standardizer ] && ADDR_STD=(--with-address_standardizer)

./configure --disable-extension-upgrades-install --enable-debug \
  --with-pgconfig="$PGSQL/bin/pg_config" \
  --with-geosconfig="$DEP_PREFIX/bin/geos-config" \
  --with-projdir="$DEP_PREFIX" \
  --with-xsldir="$XSLDIR" \
  --with-gdalconfig="$DEP_PREFIX/bin/gdal-config" \
  --with-xml2config="$DEP_PREFIX/bin/xml2-config" \
  --with-libiconv="$DEP_PREFIX" \
  --with-jsondir="$DEP_PREFIX" \
  --without-protobuf \
  --with-pcredir="$DEP_PREFIX" \
  --with-sfcgal="$DEP_PREFIX/bin/sfcgal-config" \
  "${ADDR_STD[@]}"

rm -rf "$BUILD_STAGE"; mkdir -p "$BUILD_STAGE"

# Legacy topology Makefile workaround
[ -f topology/Makefile ] && sed -i '' '/prefix = /,+2 s/^/#/' topology/Makefile

INSTALL_ARGS=(PGXSOVERRIDE=0 DESTDIR="$BUILD_STAGE" REGRESS=1
  PGSQL_DOCDIR="$BUILD_STAGE/doc" PGSQL_MANDIR="$BUILD_STAGE/man"
  PGSQL_SHAREDIR="$BUILD_STAGE/share/postgresql")

make
make install "${INSTALL_ARGS[@]}" bindir=/bin pkglibdir=/lib/postgresql datadir=/share

make -C doc
make -C doc images
make -C doc html
make -C doc install "${INSTALL_ARGS[@]}" bindir=/bin pkglibdir=/lib datadir=/share

find "$BUILD_STAGE" -maxdepth 6 \( -type f -o -type l \) | head -150
