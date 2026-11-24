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

### Build-time dependencies

The third-party libraries are compiled by EDB from source as universal
binaries. They are listed in [`packages-osx-3.6.txt`](packages-osx-3.6.txt)
and [`packages-osx-3.7.txt`](packages-osx-3.7.txt), one file per PostGIS
release. Merge all packages of the file into one common prefix, referred to
below as `<dep-prefix>`.

### Run-time dependencies

Libraries linked by the installed PostGIS modules (`otool -L`), all through
`@rpath` with `@loader_path/..` as the rpath:

| Module | Linked libraries |
|---|---|
| `postgis-3` | `libgeos_c`, `libproj`, `libjson-c`, `libxml2`, `libz`, `libiconv`, `libgmp`, `libSFCGAL`, plus `libSystem` and `libc++` from macOS |
| `postgis_raster-3` | `libgdal`, `libgeos_c`, `libproj`, plus `libSystem` from macOS |

## Part 1: Build the binaries

Download and unpack the PostGIS source tarball from
<https://download.osgeo.org/postgis/source/>, then set these variables
first:

```
export PG_ARCH_OSX_CFLAGS="-mmacosx-version-min=13 -arch x86_64 -arch arm64"
export MACOSX_DEPLOYMENT_TARGET=13
```

`scripts/osx/compile.sh` configures, builds and installs PostGIS (with docs)
into a scratch directory (`<build-stage>`):

```
PostGIS/scripts/osx/compile.sh <source-dir> <dep-prefix> <pgsql-dir> <build-stage>
```

| Argument | Meaning |
| --- | --- |
| `source-dir` | Unpacked PostGIS source |
| `dep-prefix` | The merged third-party dependency prefix |
| `pgsql-dir` | The universal PostgreSQL installation (contains `bin/pg_config`) |
| `build-stage` | Scratch `DESTDIR` for `make install` |

Then assemble the installed files and the bundled dependency libraries into
one `PostGIS` tree under `<stage>`. This is done by
`scripts/osx/prepare-staging-directory.sh`, which also lays out the
installer files (see part 2). Run it from a working directory that contains
`postgis-<version>` (the source) and this repository as `./packaging-config`,
with `STAGE`, `BUILD_STAGE`, `DEP_PREFIX`, `PGSQL` and `POSTGIS_VERSION` set.

The `PostGIS` tree has this layout:

| Path | Content |
| --- | --- |
| `bin/` | `shp2pgsql`, `pgsql2shp` |
| `lib/postgresql/` | PostGIS modules (`postgis-<major>.dylib`, etc.) |
| `lib/` | Runtime libraries: those the modules and tools link, transitively, from `<dep-prefix>`, except the ones the PG server already provides (`<pgsql-dir>/lib`) |
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

## Part 2: Create the installer `osx.zip`

Starting from the `$STAGE` tree of part 1 (with the `PostGIS` tree and
`debug_symbols` in it, and this repository as `./packaging-config`):

1. Generate the third-party license file into `$STAGE`:

   ```
   (cd packaging-config/PostGIS && bash license.sh)
   ```

2. Fill in the placeholders in `$STAGE/installer.xml` and point its paths at
   the staging root:

   ```
   X="$STAGE/installer.xml"
   sed -i '' "s/PG_CURRENT_VERSION/<pg-major>/g; s/PG_MAJOR_VERSION/<pg-major>/g" "$X"
   sed -i '' "s/PG_VERSION_POSTGIS/<postgis-version>/g; s/PG_BUILDNUM_POSTGIS/<build-number>/g" "$X"
   sed -i '' "s/POSTGIS_MAJOR_VERSION/<postgis-major>/g" "$X"
   sed -i '' 's|staging/osx|osx|g; s|\.\./resources|osx/resources|g; s|i18n/|osx/i18n/|g' "$X"
   ```

3. Build the project with InstallBuilder for `osx`, with the staging root as
   the working directory, to produce the installer `.app`.
4. The `.app` needs the privilege-elevation applet that runs as root. Build
   the project a second time from a copy of `installer.xml` with
   `<requireInstallationByRootUser>${admin_rights}</requireInstallationByRootUser>`
   changed to `...>1<...`, and copy that app's
   `Contents/MacOS/PostGIS_PG<pg-major>` over the same file in the first app.
5. Replace `Contents/MacOS/installbuilder.sh` in the app with
   `resources/extract_installbuilder.osx`, with `@@PROJECTNAME@@` replaced by
   `PostGIS_PG<pg-major>`, and make it executable.
6. Name the app `postgis-<version>-osx.app` and zip it:

   ```
   ditto -c -k --keepParent postgis-<version>-osx.app postgis-<version>-osx.zip
   ```

The installer needs an existing PostgreSQL installation. It reads
`/etc/postgres-reg.ini` to find it and installs the PostGIS modules under
that PostgreSQL's `lib/postgresql`.

## Signing and notarization

The build steps above do not sign or notarize anything. The released
binaries and installer app are code-signed with EDB's Developer ID
certificate, and the installer app is notarized with Apple, as a separate
step after the build.
