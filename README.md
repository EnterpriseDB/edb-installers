# PostgreSQL Installers

This repository is the build system behind EDB's native PostgreSQL
installers for macOS and Windows. It contains everything needed to turn a
PostgreSQL source release into a signed, ready-to-run installer: the
platform build scripts, the pinned dependency/version lists, the installer
packaging definitions (BitRock InstallBuilder), and the CI workflows that
drive it all.

The goal is a single, repeatable pipeline that builds the PostgreSQL server
installer - and the components bundled alongside it - for both platforms,
without manual intervention.

This document currently focuses on the **server** installer (PostgreSQL
itself and what ships with it).

## What the server installer bundles

Installing "PostgreSQL" via these installers gets you more than just the
database server:

- **PostgreSQL server** - built with `--with-python`, `--with-perl` and
  `--with-tcl` support, plus the command-line client tools (psql, pg_dump,
  pg_restore, etc.).
- **EDB Language Pack** - bundles the Python, Perl and Tcl interpreters
  PostgreSQL's PL/Python, PL/Perl and PL/Tcl need, so those procedural
  languages work out of the box without the user installing interpreters
  themselves.
- **StackBuilder** - a companion app, installed alongside the server, that
  provides a graphical interface for downloading and installing additional
  applications, drivers, utilities and their dependencies after the fact.
- **system_stats** and **pldebugger** - built from their upstream
  ([EnterpriseDB/system_stats](https://github.com/EnterpriseDB/system_stats),
  [EnterpriseDB/pldebugger](https://github.com/EnterpriseDB/pldebugger))
  sources and bundled directly into the server package as ready-to-use
  extensions.
- **pgAdmin 4** - bundled directly into the server installer for
  PostgreSQL 14 through 18. Starting with PostgreSQL 19, pgAdmin 4 is no
  longer part of the server installer; the installer instead
  downloads/installs the latest community pgAdmin 4 build separately.

Exact bundled versions (PostgreSQL minor version, package revision,
Language Pack, etc.) are pinned per build in `server/version.txt`.

## Repository layout

- **`server/`** - the server installer itself:
  - [`README.osx`](server/README.osx) - full macOS build walkthrough.
  - [`README.windows`](server/README.windows) - full Windows build
    walkthrough.
  - `scripts/osx/`, `scripts/windows/` - the per-platform build and
    installer-time scripts (see the platform READMEs above for the full
    script-by-script reference).
  - `scripts/common/` - cross-platform scripts, including
    `loadplLanguages.sh`/`plLanguages.config`, which drive which PL
    interpreters get loaded into a cluster.
  - `generate-sources.sh` - fetches/repackages the PostgreSQL source
    tarball for the pinned version.
  - `installer.xml.in`, `pgserver.xml.in`, `stackbuilder.xml.in`,
    `commandlinetools.xml.in` - BitRock InstallBuilder definitions for the
    installer and its components.
  - `version.txt` - pins the PostgreSQL major/minor version, package
    revision, and bundled component versions for a build.
  - `packages-osx.txt` / `packages-win64.txt` - pin the exact version of
    every third-party library PostgreSQL is built against, per platform.
  - `license.sh` - generates the combined third-party license file shipped
    with the installer.
  - `i18n/` - installer message catalogs (one file per language).
  - `resources/` - graphics, license text, and other static assets.
- **`resources/`, `scripts/`** (top level) - resources and scripts shared
  across the server installer build.

Builds are driven per-platform via GitHub Actions - macOS binaries are
built on a macOS runner, Windows binaries on a Windows runner (macOS
binaries can only be built on macOS itself - there's no cross-compilation
path, see [`server/README.osx`](server/README.osx)). There is no central
Jenkins/VM-orchestrated build reaching out over SSH/NFS to remote build
machines anymore; that legacy approach has been retired.

## Building the installers

Full, platform-specific build instructions - from setting up a clean build
machine through to a finished installer - live here:

- **[`server/README.osx`](server/README.osx)** - macOS: build machine
  setup, building the pinned third-party dependencies, Python/Perl/Tcl
  interpreters, building PostgreSQL itself, and a full reference of every
  script in `scripts/osx/`.
- **[`server/README.windows`](server/README.windows)** - Windows: build
  machine setup, the Meson-based PostgreSQL build, building the bundled
  native helpers (`createuser`, `validateuser`, `system_stats`), and a
  full reference of every script in `scripts/windows/`.

## Parallel installation and registration

PostgreSQL supports installing multiple major versions side by side on the
same machine (e.g. 17, 18 and 19 all installed at once, each in its own
directory - `/Library/PostgreSQL/<version>` on macOS, the equivalent on
Windows). Each version's installer, service and data directory are fully
independent of the others.

So that other tools - StackBuilder in particular - can discover what's
installed, each server installer registers itself on install and
deregisters on uninstall:

- **macOS/Linux** - the installer writes an entry to `/etc/postgres-reg.ini`.
- **Windows** - the installer writes the equivalent entries to the Windows
  registry.

It's up to each package's uninstaller to decide what to leave behind:
version numbers should always be cleared, but data that's still useful
after uninstall (e.g. a server's data directory, port or superuser name)
may be retained.
