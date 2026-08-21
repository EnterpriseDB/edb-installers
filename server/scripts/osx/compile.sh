#!/bin/bash
# Build PostgreSQL as a macOS universal binary (x86_64 + arm64).

set -xe

SOURCE_DIR="$1"
DEP_PREFIX="$2"
PYTHON_FRAMEWORK="$3"
PERL_DIR="$4"
TCL_DIR="$5"

if [ -z "$SOURCE_DIR" ] || [ -z "$DEP_PREFIX" ] || [ -z "$PYTHON_FRAMEWORK" ] || [ -z "$PERL_DIR" ] || [ -z "$TCL_DIR" ]; then
    echo "Usage: $0 <source_directory> <dep_prefix> <python_framework_dir> <perl_dir> <tcl_dir>"
    exit 1
fi
export PATH="$DEP_PREFIX/bin:$PATH"

mkdir -p "$PG_STAGING"
cd "$SOURCE_DIR"

DYLD_LIBRARY_PATH="$DEP_PREFIX/lib" \
PG_SYSROOT="$PG_SYSROOT" \
PYTHON="$PYTHON_FRAMEWORK/Versions/Current/bin/python3" \
PERL="$PERL_DIR/bin/perl" \
TCL_CONFIG_SH="$TCL_DIR/lib/tclConfig.sh" \
LDFLAGS="-L$DEP_PREFIX/lib -Wl,-headerpad_max_install_names" \
CFLAGS="$PG_ARCH_OSX_CFLAGS -O2" \
XML2_CONFIG="$DEP_PREFIX/bin/xml2-config" \
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
   --with-python \
   --with-perl \
   --with-tcl \
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

# sysconfig reports the concrete version path, not Current, so plpython3
# links against a fixed Python version by default. Repoint it at Current so
# any python.org install >=3.9 on the end user's Mac satisfies it.
PLPY="$PG_STAGING/lib/postgresql/plpython3.dylib"
if [ -f "$PLPY" ]; then
    OLD_DEP=$(otool -L "$PLPY" | awk 'NR>1{print $1}' | grep -m1 'Python.framework')
    if [ -z "$OLD_DEP" ]; then
        echo "ERROR: no Python.framework dependency in plpython3.dylib"
        exit 1
    fi

    # Replace whatever version folder is there (e.g. "3.14") with "Current"
    NEW_DEP=$(echo "$OLD_DEP" | sed -E 's#/Versions/[^/]+/#/Versions/Current/#')

    install_name_tool -change "$OLD_DEP" "$NEW_DEP" "$PLPY"
fi

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
for h in openssl libxml2 libxslt unicode iconv.h zlib.h zdict.h lz4*.h zstd*.h; do
    cp -R "$DEP_PREFIX"/include/$h "$PG_STAGING/include/" 2>/dev/null || true
done
