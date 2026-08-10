#!/bin/bash
# Build PostgreSQL as a macOS universal binary (x86_64 + arm64).

set -xe

SOURCE_DIR="$1"
DEP_PREFIX="$2"
PYTHON_DIR="$3"
PERL_DIR="$4"
TCL_DIR="$5"

if [ -z "$SOURCE_DIR" ] || [ -z "$DEP_PREFIX" ] || [ -z "$PYTHON_DIR" ] || [ -z "$PERL_DIR" ] || [ -z "$TCL_DIR" ]; then
    echo "Usage: $0 <source_directory> <dep_prefix> <python_dir> <perl_dir> <tcl_dir>"
    exit 1
fi
export PATH="$DEP_PREFIX/bin:$PATH"

mkdir -p "$PG_STAGING"
cd "$SOURCE_DIR"

DYLD_LIBRARY_PATH="$DEP_PREFIX/lib" \
PG_SYSROOT="$PG_SYSROOT" \
PYTHON=$PYTHON_DIR/bin/python3 \
TCL_CONFIG_SH=$TCL_DIR/lib/tclConfig.sh \
PERL=$PERL_DIR/bin/perl \
LDFLAGS="-L$DEP_PREFIX/lib -Wl,-headerpad_max_install_names" \
CFLAGS="$PG_ARCH_OSX_CFLAGS -O2" \
XML2_CONFIG="$DEP_PREFIX/bin/xml2-config" \
ICU_LIBS="-L$DEP_PREFIX/lib -licuuc -licudata -licui18n" \
ICU_CFLAGS="-I$DEP_PREFIX/include" \
LZ4_CFLAGS="-I$DEP_PREFIX/include" \
LZ4_LIBS="-L$DEP_PREFIX/lib" \
./configure \
   --prefix="$PG_STAGING" \
   --docdir="$PG_STAGING/doc/postgresql" \
   --with-icu \
   --enable-debug \
   --with-perl \
   --with-python \
   --with-tcl \
   --with-ldap \
   --with-openssl \
   --with-bonjour \
   --with-pam \
   --with-libxml \
   --with-uuid=e2fs \
   --with-libxslt \
   --with-libedit-preferred \
   --with-gssapi \
   --with-lz4 \
   --with-includes="$DEP_PREFIX/include/libxml2:$DEP_PREFIX/include:$DEP_PREFIX/include/security:$DEP_PREFIX/include/openssl/"

make -j"$(sysctl -n hw.ncpu)"
make install

#build postgres docs
cd doc
export XML_CATALOG_FILES="/opt/homebrew/etc/xml/catalog"
CFLAGS="$PG_ARCH_OSX_CFLAGS" make
make install 

#build contrib
cd ../contrib
CFLAGS="$PG_ARCH_OSX_CFLAGS" make
make install

#build uuid-ossp
cd uuid-ossp
CFLAGS="$PG_ARCH_OSX_CFLAGS" make
make install

for lib in liblz4 libxml2 libxslt libuuid libedit libz libssl libcrypto \
           libintl libicui18n libicudata libicuuc libiconv libkrb5 libgss \
           libk5 libcom; do
    cp -pR "$DEP_PREFIX"/lib/${lib}*.dylib "$PG_STAGING/lib/" 2>/dev/null || true
done
for h in openssl libxml2 libxslt unicode iconv.h zlib.h zdict.h lz4*.h ; do
    cp -R "$DEP_PREFIX"/include/$h "$PG_STAGING/include/" 2>/dev/null || true
done
