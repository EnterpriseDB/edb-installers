#!/bin/bash
# Build PostgreSQL as a macOS universal binary (x86_64 + arm64).
# macOS counterpart of server/scripts/windows/compile.ps1.
#
# Usage: compile.sh <source_directory> <dep_prefix>
# Tool paths (PERL, PYTHON, TCL_CONFIG_DIR) and build flags
# (PG_STAGING, PG_SYSROOT, PG_ARCH_OSX_CFLAGS) come from the environment.

set -xe

SOURCE_DIR="$1"
DEP_PREFIX="$2"

if [ -z "$SOURCE_DIR" ] || [ -z "$DEP_PREFIX" ]; then
    echo "Usage: $0 <source_directory> <dep_prefix>"
    exit 1
fi

export PATH="$DEP_PREFIX/bin:$PATH"

mkdir -p "$PG_STAGING"
cd "$SOURCE_DIR"

DYLD_LIBRARY_PATH="$DEP_PREFIX/lib" \
PG_SYSROOT="$PG_SYSROOT" \
PERL="$PERL" \
PYTHON="$PYTHON" \
LDFLAGS="-L$DEP_PREFIX/lib" \
CFLAGS="$PG_ARCH_OSX_CFLAGS -O2" \
XML2_CONFIG="$DEP_PREFIX/bin/xml2-config" \
XML2_CFLAGS="-I$DEP_PREFIX/include/libxml2/libxml" \
XML2_LIBS="-L$DEP_PREFIX/lib -lxml2" \
ICU_LIBS="-L$DEP_PREFIX/lib -licuuc -licudata -licui18n" \
ICU_CFLAGS="-I$DEP_PREFIX/include" \
LZ4_CFLAGS="-I$DEP_PREFIX/include" \
LZ4_LIBS="-L$DEP_PREFIX/lib" \
ZSTD_CFLAGS="-I$DEP_PREFIX/include" \
ZSTD_LIBS="-L$DEP_PREFIX/lib" \
LIBCURL_CFLAGS="-I$DEP_PREFIX/include" \
LIBCURL_LIBS="-L$DEP_PREFIX/lib" \
./configure \
   --prefix="$PG_STAGING" \
   --docdir="$PG_STAGING/doc/postgresql" \
   --with-icu \
   --enable-debug \
   --with-ldap \
   --with-openssl \
   --with-perl \
   --with-python \
   --with-tcl \
   --with-tclconfig="$TCL_CONFIG_DIR" \
   --with-bonjour \
   --with-pam \
   --with-libxml \
   --with-libcurl \
   --with-uuid=e2fs \
   --with-libxslt \
   --with-libedit-preferred \
   --with-gssapi \
   --with-lz4 \
   --with-zstd \
   --with-includes="$DEP_PREFIX/include/libxml2:$DEP_PREFIX/include:$DEP_PREFIX/include/security:$DEP_PREFIX/include/openssl/"

make -j"$(sysctl -n hw.ncpu)"
make install

#build postgres docs
cd doc
export XML_CATALOG_FILES="/usr/local/etc/xml/catalog"
CFLAGS='$PG_ARCH_OSX_CFLAGS ' make || _die "Failed to build the postgres docs"
make install 

#build contrib
cd ../contrib
CFLAGS='$PG_ARCH_OSX_CFLAGS ' make  || _die "Failed to build the postgres contrib"
make install
make -C contrib/uuid-ossp CFLAGS="$PG_ARCH_OSX_CFLAGS" install

# Bundle dependency libraries and headers into staging.
cp -pR "$DEP_PREFIX"/lib/*.dylib "$PG_STAGING/lib/" 2>/dev/null || true
for h in openssl libxml2 libxslt unicode; do
    [ -d "$DEP_PREFIX/include/$h" ] && cp -R "$DEP_PREFIX/include/$h" "$PG_STAGING/include/"
done
