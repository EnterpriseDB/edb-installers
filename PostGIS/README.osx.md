# Building PostGIS for macOS

This document describes how to build PostGIS for macOS from this
repository. See the [root README](../README.md) for what the installer
bundles.

The build has two independent parts:

1. **Build the PostGIS binaries**: a relocatable universal `PostGIS` tree
   built against a PostgreSQL installation. No installer tooling is needed.
2. **Generate the installer** (`.app`, shipped as a `.zip`) from those
   binaries. Only needed if you want the installer.

If you only want the binaries, stop after part 1.

## Build environment

| | |
| --- | --- |
| Build machine | macOS 15 (Sequoia). macOS binaries can only be built on macOS. |
| Output | Universal binaries (arm64 + x86_64) |
| Minimum macOS for end users | 13 |
| Toolchain | Xcode Command Line Tools (`xcode-select --install`) and [Homebrew](https://brew.sh/) |
| Docs | `brew install docbook docbook-xsl imagemagick` |
| Licenses | `brew install dos2unix` |
| Installer (part 2 only) | [BitRock InstallBuilder](https://installbuilder.com/) |

You also need a universal PostgreSQL installation (its `pg_config`, headers
and libraries) for the same major version the installer targets. The
PostgreSQL binaries archive produced by the [server build](../server/README.osx.md)
works.

## Third-party dependencies

The third-party libraries (GEOS, PROJ, GDAL, SFCGAL, CGAL, Boost, json-c,
libxml2, curl, etc.) are compiled by EDB from source as universal binaries.
The list and versions are in [`packages-osx.txt`](packages-osx.txt). To use a
different list for one PostGIS release, add `packages-osx-<major.minor>.txt`
(for example `packages-osx-3.5.txt`) and it takes precedence.

Merge them all into one common prefix, referred to below as `<dep-prefix>`.

## Part 1: Build the binaries

Download and unpack the PostGIS source tarball from
<https://download.osgeo.org/postgis/source/>, then set these variables first:

```
export PG_ARCH_OSX_CFLAGS="-mmacosx-version-min=13 -arch x86_64 -arch arm64"
export MACOSX_DEPLOYMENT_TARGET=13
export PATH="<dep-prefix>/bin:$PATH"
export CFLAGS="$PG_ARCH_OSX_CFLAGS" CXXFLAGS="$PG_ARCH_OSX_CFLAGS"
export LDFLAGS="-L<dep-prefix>/lib"
export PROJ_CFLAGS="-I<dep-prefix>/include" PROJ_LIBS="-L<dep-prefix>/lib -lproj"
```

Configure, build and install into a scratch directory (`DESTDIR`):

```
./configure --disable-extension-upgrades-install --enable-debug \
  --with-pgconfig=<pgsql>/bin/pg_config \
  --with-geosconfig=<dep-prefix>/bin/geos-config \
  --with-projdir=<dep-prefix> \
  --with-xsldir="$(brew --prefix docbook-xsl)/docbook-xsl" \
  --with-gdalconfig=<dep-prefix>/bin/gdal-config \
  --with-xml2config=<dep-prefix>/bin/xml2-config \
  --with-libiconv=<dep-prefix> \
  --with-jsondir=<dep-prefix> \
  --without-protobuf \
  --with-pcredir=<dep-prefix> \
  --with-sfcgal=<dep-prefix>/bin/sfcgal-config \
  --with-address_standardizer

make
make install PGXSOVERRIDE=0 DESTDIR=<build-stage> bindir=/bin pkglibdir=/lib/postgresql datadir=/share \
  REGRESS=1 PGSQL_DOCDIR=<build-stage>/doc PGSQL_MANDIR=<build-stage>/man \
  PGSQL_SHAREDIR=<build-stage>/share/postgresql

make -C doc html
make -C doc install PGXSOVERRIDE=0 DESTDIR=<build-stage> bindir=/bin pkglibdir=/lib datadir=/share \
  REGRESS=1 PGSQL_DOCDIR=<build-stage>/doc PGSQL_MANDIR=<build-stage>/man \
  PGSQL_SHAREDIR=<build-stage>/share/postgresql
```

Assemble the installed files and the bundled dependency libraries into one
`PostGIS` tree with this layout:

| Path | Content |
| --- | --- |
| `bin/` | `shp2pgsql`, `pgsql2shp` |
| `lib/postgresql/` | PostGIS modules (`postgis-<major>.dylib`, etc.) |
| `lib/` | Bundled `<dep-prefix>` libraries (GEOS, PROJ, GDAL, SFCGAL, Boost, ...) |
| `share/` | Extension files, plus `proj` and `gdal` data |
| `doc/postgis/` | `postgis.html` (built as `postgis-en.html` from 3.6), `style.css`, `images/`, PDF |
| `man/`, `utils/` | Man pages and the Perl utilities |

Make the result relocatable:

```
server/scripts/osx/rewrite-dylib-refs.sh <PostGIS-tree> <dep-prefix>/lib
```

To extract `.dSYM` debug symbols as well, run:

```
server/scripts/osx/create-debug-symbols.sh <PostGIS-tree> <output-dir>
```

## Part 2: Generate the installer

1. Set `STAGE` to the directory that will hold the installer staging tree,
   with the `PostGIS` tree from part 1 inside it and the debug symbols in
   `$STAGE/debug_symbols`. Put this repository next to it as
   `./packaging-config`.
2. Generate the third-party license file:

   ```
   cd packaging-config/PostGIS
   bash license.sh
   ```

   It writes `postgis_3rd_party_licenses.txt` into `$STAGE`.
3. Assemble the installer layout:

   ```
   packaging-config/PostGIS/scripts/osx/prepare-staging-directory.sh
   ```

   It adds the installer scripts, docs launcher, language file and side
   image to `$STAGE`, and copies `installer.xml.in` to `$STAGE/installer.xml`.
4. Fill in the version placeholders in `$STAGE/installer.xml`:
   `PG_CURRENT_VERSION` and `PG_MAJOR_VERSION` (the PostgreSQL major),
   `PG_VERSION_POSTGIS`, `PG_BUILDNUM_POSTGIS` and `POSTGIS_MAJOR_VERSION`.
5. Build the project with InstallBuilder for `osx` to produce the `.app`,
   and zip it.

The installer needs an existing PostgreSQL installation. It reads
`/etc/postgres-reg.ini` to find it and installs the PostGIS modules under
that PostgreSQL's `lib/postgresql`.

## Signing and notarization

The build steps above do not sign or notarize anything. The released
binaries and installer app are code-signed with EDB's Developer ID
certificate, and the installer app is notarized with Apple, as a separate
step after the build.
