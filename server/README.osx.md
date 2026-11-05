# Building PostgreSQL for Windows

This document describes how to build PostgreSQL for Windows from this
repository, from a clean build machine to a finished package. See the
[root README](../README.md) for what the installer bundles.

To install PostgreSQL on Windows rather than build it, see the
[installation documentation](https://www.enterprisedb.com/docs/supported-open-source/postgresql/installing/windows/).

The build has two independent parts:

1. **Build the PostgreSQL binaries**: an installed `pgsql` tree built with
   the MSVC build scripts (`src/tools/msvc`) and Visual Studio. No installer
   tooling is needed.
2. **Generate the installer** (`.exe`) from those binaries. Only needed if
   you want the installer.

If you only want the binaries, stop after part 1.

## Build environment

| | |
| --- | --- |
| Build machine | Windows 11 (64-bit) or Windows Server 2022/2025. Windows binaries are built on Windows using the MSVC build; there is no cross-compilation path from macOS/Linux. |
| Output | x64 binaries |
| Compiler | Visual Studio 2022 (platform toolset v143) with the "Desktop development with C++" workload |
| Python | Python 3.11.x |
| Build system | MSVC build scripts (`src/tools/msvc`, driven by Perl) and MSBuild |
| Perl | Perl 5.38.x; required for script generation and builds |
| Tcl | Tcl 8.6.x |
| Flex & Bison | MSYS packages `bison` and `flex`; make sure they are on your `PATH`. |
| Installer (part 2 only) | [BitRock InstallBuilder](https://installbuilder.com/) |

Run all build commands from the **"x64 Native Tools Command Prompt for VS
2022"** (as Administrator) so the compiler environment variables
(`cl.exe`) are loaded.

## Third-party dependencies

Third-party dependencies bundled with this distribution are built from source; see [`packages-win64.txt`](packages-win64.txt) for the complete list of components and versions. The gettext, libiconv, and uuid libraries are compiled directly from pristine, unmodified upstream source releases. Licensing terms for all bundled components—including the GNU Lesser General Public License (LGPL) covering gettext and libiconv—are documented in commandlinetools_3rd_party_licenses.txt installed by the installer.

For optional features (full-featured build), install libraries such as
OpenSSL, Zlib, ICU or LibXML2 using [vcpkg](https://vcpkg.io/):

```
vcpkg install zlib:x64-windows openssl:x64-windows icu:x64-windows
```

Any dependency that is not available through vcpkg must be installed or built
separately, and its directory passed to `compile.ps1`.

## Repository preparation

Make sure Git handles CRLF line endings correctly, to avoid flex/bison
parser errors:

```
git config core.autocrlf true
git rm --cached -r .
git reset --hard
```

## Part 1: Build the binaries

`scripts/windows/compile.ps1` drives the build. It takes the PostgreSQL
source directory followed by the dependency directories, runs the MSVC build
and install, and also copies the resulting dependency DLLs/libs/headers into
the install tree.

| Step | Purpose | Command |
| --- | --- | --- |
| 1. Compile and deploy | Build and install into the install tree (`pgsql`) | See below |
| 2. Initialize and start (optional) | Create a cluster and start the server | See below |

### Step 1: Compile and deploy

```
scripts\windows\compile.ps1 <postgresql-source-dir> <libxml2> <libxslt> <openssl> <python> <zlib> <uuid> <perl> <lz4> <zstd> <icu> <gettext> <tcl> <wxwidgets> <iconv>
```

For example:

```
scripts\windows\compile.ps1 postgresql-16.x ^
  .\libxml2 .\libxslt .\openssl .\python .\zlib .\uuid ^
  .\perl .\lz4 .\zstd .\icu .\gettext ^
  .\tcl .\wxwidgets .\iconv
```

What `compile.ps1` does, in order:

1. Generates `src\tools\msvc\config.pl` with the dependency paths.
2. Runs `clean.bat`, `build.bat release` and `install.bat` into `pgsql`.
3. Copies the dependency DLLs, libs, headers and docs into `pgsql`.

The installed tree is created in `pgsql`. Flex and Bison are not set by the
script; they must already be on `PATH`, and the HTML docs must already be built
under `doc\src\sgml\html` in the source tree.

### Step 2: Initialize and start the database

```
cd pgsql\bin
initdb.exe -D ..\data -U administrator --auth=trust
pg_ctl.exe -D ..\data -l ..\data\server.log start
```

### Bundled helper binaries

Besides PostgreSQL itself, two small native helpers and one extension are
built from source via Visual Studio project files, using the shared
`vc-build-x64.bat` wrapper:

```
vc-build-x64.bat <project.vcxproj> Release x64 <output-dir> <toolset>
```

| Project | Purpose |
| --- | --- |
| `createuser/createuser.vcxproj` | Creates the Windows service account PostgreSQL runs as. |
| `validateuser/validateuser.vcxproj` | Validates a Windows account's credentials during interactive install. |
| `system_stats` (via `compile-system_stats.ps1`) | Builds the `system_stats` extension the same way, against its own `.vcxproj` (checked out separately; see the root README's ["What the server installer bundles"](../README.md#what-the-server-installer-bundles) section). |

## Part 2: Generate the installer

| Step | What happens |
| --- | --- |
| 1. Stage | `prepare-staging-directory.sh` assembles everything (PostgreSQL binaries, bundled extensions, licenses, docs) into the layout the Windows installer packages up. |
| 2. Fill in placeholders | `installer.xml.in` is pre-processed into `installer.xml` with version numbers etc. substituted in. |
| 3. Build | [BitRock InstallBuilder](https://installbuilder.com/) builds `installer.xml` into the `.exe` installer. |

## Part 3: Sign the output
 
The final installer `.exe` and `archive.zip` are signed with our signature.
The aim is to sign the output files themselves, so that users can verify
that what they download comes from us and has not been changed since it was
built.

### pgAdmin

| PostgreSQL version | pgAdmin 4 handling |
| --- | --- |
| 14-18 | Bundled directly into the installer package (see the root README). |
| 19+ | Not bundled. `install-pgadmin.bat` resolves the latest pgAdmin 4 release from `https://www.postgresql.org/ftp/pgadmin/pgadmin4/` and installs it separately. |

## Script reference (`scripts/windows/`)

Build-time scripts:

| Script | Purpose |
| --- | --- |
| `compile.ps1` | Drives the actual build (generates `config.pl`, runs the MSVC build and install), copies the resulting dependency DLLs/libs/headers into the install tree. |
| `prepare-staging-directory.sh` | Assembles the built files into the installer's staging layout. |
| `vc-build-x64.bat` | Shared helper that invokes MSBuild against a given `.vcxproj`, configuration, platform and output directory. |
| `compile-system_stats.ps1` | Builds the `system_stats` extension via `vc-build-x64.bat`. |
| `createuser/`, `validateuser/` | Visual Studio projects for the `createuser`/`validateuser` native helpers. |
| `getlocales.ps1` | Enumerates the system's available locales (BCP-47 codes and long names) for the installer's locale selection dropdown. |

Installer-time scripts (run on the end user's machine, not during the build):

| Script | Purpose |
| --- | --- |
| `initcluster.ps1` | Runs `initdb` to create the data directory/cluster. |
| `install-pgadmin.bat` | Downloads and installs the latest pgAdmin 4 release (PostgreSQL 19+ path). |
| `runpsql.bat` | Launches `psql` connected to the local server, prompting for connection details. |

Shared (`scripts/common/`):

| Script | Purpose |
| --- | --- |
| `loadplLanguages.sh` / `plLanguages.config` | Cross-platform: drives which PL language interpreters (Python/Perl/Tcl) get loaded into a newly-initialized cluster. |

## Troubleshooting

### Permission errors on `initdb`

`initdb` can fail with a permission error because the Administrator account
does not have access to the data directory. To fix it, take ownership of the
data directory and grant the Administrator account full access to it:

```
takeown /f pgsql\data /r /d y
icacls pgsql\data /grant Administrator:(OI)(CI)F /t
```
