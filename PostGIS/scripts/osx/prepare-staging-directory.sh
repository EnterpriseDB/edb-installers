#!/bin/bash
#
# Assemble the macOS InstallBuilder staging tree for PostGIS in $STAGE:
# the PostGIS tree (modules, tools, docs and bundled dependency libraries)
# from a `make install DESTDIR` build, plus the installer scripts and project.
#
# Expects STAGE, BUILD_STAGE, DEP_PREFIX and POSTGIS_VERSION in the environment,
# the PostGIS source in ./postgis-$POSTGIS_VERSION and this repository in
# ./packaging-config.

set -xe

SRC="$PWD/postgis-$POSTGIS_VERSION"
PGIS="$STAGE/PostGIS"
rm -rf "$STAGE"; mkdir -p "$PGIS"/{bin,lib/postgresql,share,doc/postgis,man,utils}

# Modules and data
[ -d "$BUILD_STAGE/lib/postgresql" ] || { echo "ERROR: no lib/postgresql under DESTDIR"; exit 1; }
cp -pR "$BUILD_STAGE/lib/postgresql/." "$PGIS/lib/postgresql/"
[ -d "$BUILD_STAGE/share" ] || { echo "ERROR: no share under DESTDIR"; exit 1; }
cp -pR "$BUILD_STAGE/share/." "$PGIS/share/"

# Command line tools
for b in shp2pgsql pgsql2shp; do
  f="$(find "$BUILD_STAGE" -type f -name "$b" | head -1)"
  [ -n "$f" ] || { echo "ERROR: $b not installed"; exit 1; }
  cp -p "$(dirname "$f")"/* "$PGIS/bin/"
done

# Docs and utilities
# only the rendered images; static ones are symlinks and the dir also holds the generator build
mkdir -p "$PGIS/doc/postgis/images"
find "$SRC/doc/html/images" -maxdepth 1 \( -name '*.png' -o -name '*.gif' \) -exec cp -pL {} "$PGIS/doc/postgis/images/" \;
# 3.6+ names it postgis-en.html
HTML="$SRC/doc/html/postgis-en.html"; [ -f "$HTML" ] || HTML="$SRC/doc/html/postgis.html"
cp -p "$HTML" "$PGIS/doc/postgis/postgis.html"
cp -p "$SRC/doc/html/style.css" "$PGIS/doc/postgis/" || echo "WARNING: doc/html/style.css not found"
PDF=""
for f in "$SRC"/doc/postgis-${POSTGIS_VERSION}*.pdf; do [ -f "$f" ] && PDF="$f" && break; done
if [ -n "$PDF" ]; then cp -p "$PDF" "$PGIS/doc/postgis/"; else echo "WARNING: PostGIS pdf not found in doc/"; fi
cp -pR "$SRC/doc/man" "$PGIS/"
cp "$SRC"/utils/*.pl "$PGIS/utils/"

# Dependent libs and data
copy_libs() {  # <required: 1|0> <dir> <glob>...
  req="$1"; dir="$2"; shift 2
  for g in "$@"; do
    if ls "$dir"/$g >/dev/null 2>&1; then
      cp -pR "$dir"/$g "$PGIS/lib/"
    elif [ "$req" = 1 ]; then
      echo "ERROR: no $g in $dir"; exit 1
    fi
  done
}
copy_libs 1 "$DEP_PREFIX/lib" 'libgeos*.dylib' 'libproj*.dylib' 'libgdal*.dylib' 'libcurl*.dylib' \
  'libpcre2*.dylib' 'libjson-c.*dylib' 'libtiff.*dylib' 'libjpeg.*dylib' 'libpng*.*dylib' \
  'libexpat*.*dylib' 'libsqlite*.*dylib' 'libgmp*.*dylib' 'libmpfr*.*dylib' 'libSFCGAL*.*dylib'
# boost may be in its own prefix
copy_libs 0 "$DEP_PREFIX/lib" 'libboost*.*dylib'
copy_libs 0 "$DEP_PREFIX/boost/lib" 'libboost*.*dylib'
cp -pR "$DEP_PREFIX/share/proj" "$PGIS/share/"
cp -pR "$DEP_PREFIX/share/gdal" "$PGIS/share/"

# ---------------------------------------------------------------------------
# Installer scripts and project
# ---------------------------------------------------------------------------
PK=packaging-config/PostGIS

mkdir -p "$STAGE/installer/PostGIS" "$STAGE/scripts/images" "$STAGE/i18n" "$STAGE/resources"

cp "$PK/scripts/osx/createshortcuts.sh" "$STAGE/installer/PostGIS/createshortcuts.sh"
chmod ugo+x "$STAGE/installer/PostGIS/createshortcuts.sh"

cp -p "$PK/scripts/osx/pg-launchPostGISDocs.applescript.in" "$STAGE/scripts/pg-launchPostGISDocs.applescript"
cp -p "$PK/resources/pg-launchPostGISDocs.icns" "$STAGE/scripts/images/"

cp "$PK/i18n/en.lng" "$STAGE/i18n/"
cp packaging-config/resources/pg-side.png "$STAGE/resources/"

# InstallBuilder project file (templated by the workflow's Pre-installer step)
cp "$PK/installer.xml.in" "$STAGE/installer.xml"

chmod -R ugo+rX "$STAGE"
