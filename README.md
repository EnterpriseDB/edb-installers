# PostgreSQL Installers

This repository is the build system behind EDB's native PostgreSQL
installers for macOS and Windows. It contains everything needed to turn a
PostgreSQL source release into a signed, ready-to-run installer yourself:
the platform build scripts, the pinned dependency/version lists, and the
installer packaging definitions (BitRock InstallBuilder).

The goal is a single, repeatable pipeline that builds the PostgreSQL server
installer - and the components bundled alongside it - for both platforms.

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

## How to build

Each platform is built on its own native machine - macOS binaries can only
be built on macOS itself, Windows binaries on Windows; there's no
cross-compilation path for either.

Full, platform-specific build instructions - from setting up a clean build
machine through to a finished installer - live in:

- [`server/README.osx`](server/README.osx) for macOS
- [`server/README.windows`](server/README.windows) for Windows

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

## Security Vulnerabilities

Please report security issues affecting PostgreSQL core to
security@postgresql.org. For security concerns specific to the
EDB-packaged PostgreSQL installers, please email
disclosures@enterprisedb.com in accordance with EDB's [Public Vulnerability
Disclosure Policy](https://www.enterprisedb.com/docs/security/vulnerability-disclosure-policy/).
