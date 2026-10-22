# Building PostgreSQL for macOS

This document describes how the macOS PostgreSQL build is produced. See the
[root README](../README.md) for what the installer bundles.

The build has two independent parts:

1. **Build the PostgreSQL binaries** (a relocatable universal `pgsql` tree,
   which is also what the binaries archive contains). No installer tooling
   is needed.
2. **Generate the installer** (`.dmg`) from those binaries. Only needed if
   you want the installer.

If you only want the binaries, stop after part 1.

## Build environment

| | |
| --- | --- |
| Build machine | macOS 15 (Sequoia). macOS binaries can only be built on macOS. |
| Output | Universal binaries (arm64 + x86_64) |
| Minimum macOS for end users | 14 |
| Toolchain | Xcode Command Line Tools (`xcode-select --install`) and [Homebrew](https://brew.sh/) |
| Docs | `brew install docbook docbook-xsl`. `compile.sh` expects the XML catalog at `/opt/homebrew/etc/xml/catalog`, the Homebrew location on Apple Silicon. |
| Installer (part 2 only) | [BitRock InstallBuilder](https://installbuilder.com/) |

Language interpreters PostgreSQL is built against (versions are pinned in
[`version.txt`](version.txt)):

- **Python**: the official universal2 installer from python.org. It must be
  the `Python.framework` layout, so a Homebrew Python will not work.
- **Perl and Tcl**: from the EDB Language Pack.

## Third-party dependencies

The third-party libraries (OpenSSL, curl, ICU, libxml2, krb5, etc.) are
compiled by EDB from source as universal binaries. The pinned list and
versions are in [`packages-osx.txt`](packages-osx.txt).

Merge them all into one common prefix. The `compile.sh` step below takes
that prefix as its `<dep-prefix>` argument.

## Part 1: Build the binaries

`scripts/osx/compile.sh` configures, builds and installs PostgreSQL (with
contrib modules, docs, and the bundled dependency libraries) into
`$PG_STAGING`.

Set these first:

```
export PG_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
export PG_ARCH_OSX_CFLAGS="-mmacosx-version-min=14 -arch x86_64 -arch arm64"
export PG_STAGING=/path/to/pgbuild
```

Then run it:

```
server/scripts/osx/compile.sh <source-dir> <dep-prefix> <python-framework> <perl-dir> <tcl-dir>
```

| Argument | Meaning |
| --- | --- |
| `source-dir` | Unpacked PostgreSQL source (fetch it with `generate-sources.sh`) |
| `dep-prefix` | The merged third-party dependency prefix |
| `python-framework` | `/Library/Frameworks/Python.framework` |
| `perl-dir` | Perl root, containing `bin/perl` |
| `tcl-dir` | Tcl root, containing `lib/tclConfig.sh` |

Make the result relocatable:

```
server/scripts/osx/rewrite-dylib-refs.sh "$PG_STAGING" <dep-prefix>/lib
```

`$PG_STAGING` is now the binaries tree and can be zipped as it is.

Notes:

- The CI binaries archive adds a few more things to this tree: prebuilt
  extensions, `stackbuilder.app` and license files. It is also code-signed.
  The output of the steps above is unsigned.
- `scripts/osx/create-debug-symbols.sh "$PG_STAGING" <output-dir>` extracts
  `.dSYM` debug symbols, if you want them.

## Part 2: Generate the installer

1. Run `scripts/osx/prepare-staging-directory.sh`. It assembles the binaries
   into the installer layout (server, command line tools, StackBuilder) and
   copies the InstallBuilder project files. It expects the CI checkout
   layout (the build output in `./pgsql` and this repo under
   `./packaging-config`), so it is easiest to run through the GitHub
   workflow.
2. Fill in the version placeholders in the copied `installer.xml`,
   `pgserver-osx.xml`, `commandlinetools-osx.xml` and `stackbuilder-osx.xml`.
3. Build with InstallBuilder to produce the `.dmg`.
