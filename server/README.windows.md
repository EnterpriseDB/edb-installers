# Building PostgreSQL for Windows

This document describes how to build PostgreSQL for Windows from this
repository, from a clean build machine to a finished package. See the
[root README](../README.md) for what the installer bundles.

The build has two independent parts:

1. **Build the PostgreSQL binaries**: an installed `PG_install` tree built
   with Meson and Ninja. No installer tooling is needed.
2. **Generate the installer** (`.exe`) from those binaries. Only needed if
   you want the installer.

If you only want the binaries, stop after part 1.

## Build environment

| | |
| --- | --- |
| Build machine | Windows 11 (64-bit) or Windows Server 2022/2025. Windows binaries are built on Windows using Meson; there is no cross-compilation path from macOS/Linux. |
| Output | x64 binaries |
| Compiler | Visual Studio 2022 or newer with the "Desktop development with C++" workload |
| Python | Python 3.10+ (check "Add Python to PATH" during installation) |
| Build system | Meson and Ninja: `pip install meson ninja` |
| Perl | [Strawberry Perl](https://strawberryperl.com/) (required for script generation and builds) |
| Flex & Bison | [win_flex_bison](https://github.com/lexxmark/winflexbison). Download, extract to a dedicated folder (e.g. `C:\3rd_Party_Libraries\win_flex_bison`), and add that path to your system `PATH`. |
| Docs | MSYS packages installed by `meson-doc.sh` (`libxml2`, `libxslt`, `docbook-xml`, `docbook-xsl`, via `pacman`) |
| Installer (part 2 only) | [BitRock InstallBuilder](https://installbuilder.com/) |

Run all build commands from the **"x64 Native Tools Command Prompt for VS
\<version\>"** (as Administrator) so the compiler environment variables
(`cl.exe`) are loaded.

## Third-party dependencies

The third-party libraries are compiled by EDB from source as universal binaries. The list and versions are in
[`packages-win64.txt`](packages-win64.txt).

The bundled gettext and iconv libraries are LGPL-licensed. These two, and
the uuid library, are used as released upstream and are not modified.

For optional features (full-featured build), install libraries such as
OpenSSL, Zlib, ICU or LibXML2 using [vcpkg](https://vcpkg.io/):

```
vcpkg install zlib:x64-windows openssl:x64-windows icu:x64-windows
```

## Repository preparation

Make sure Git handles CRLF line endings correctly, to avoid flex/bison
parser errors:

```
git config core.autocrlf true
git rm --cached -r .
git reset --hard
```

## Part 1: Build the binaries

`scripts/windows/meson.bat` sets up `PATH`/`PKG_CONFIG_PATH` for the
dependency prefixes and runs `meson setup` for PostgreSQL. Equivalently,
run the steps by hand:

| Step | Purpose | Command |
| --- | --- | --- |
| 1. Configure | Set up the build directory | See the two variants below |
| 2. Compile and deploy | Build and install into the install tree. `scripts/windows/compile.ps1` drives this and also copies the resulting dependency DLLs/libs/headers into the install tree. | `ninja -C build install` |
| 3. Test (optional) | Run regression tests | `meson test -C build` |
| 4. Initialize and start (optional) | Create a cluster and start the server | See below |

### Step 1: Configure

| Variant | Use when | Command |
| --- | --- | --- |
| Minimal | No external compression/SSL dependencies | See below |
| Full-featured | vcpkg dependencies are installed | See below |

Minimal build:

```
meson setup build --prefix=C:\PG_install ^
  -DFLEX=C:\3rd_Party_Libraries\win_flex_bison\win_flex.exe ^
  -DBISON=C:\3rd_Party_Libraries\win_flex_bison\win_bison.exe ^
  -Dreadline=disabled ^
  -Dzlib=disabled
```

Full-featured build:

```
meson setup build --prefix=C:\PG_install ^
  -DFLEX=C:\3rd_Party_Libraries\win_flex_bison\win_flex.exe ^
  -DBISON=C:\3rd_Party_Libraries\win_flex_bison\win_bison.exe ^
  -Dcmake_prefix_path=C:\vcpkg\installed\x64-windows
```

### Step 4: Initialize and start the database

```
cd C:\PG_install\bin
initdb.exe -D C:\PG_install\data -U administrator --auth=trust
pg_ctl.exe -D C:\PG_install\data -l C:\PG_install\data\server.log start
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
| `meson.bat` | Sets up `PATH`/`PKG_CONFIG_PATH` for the dependency prefixes and runs `meson setup` for PostgreSQL. |
| `compile.ps1` | Drives the actual build (`ninja install`) and copies the resulting dependency DLLs/libs/headers into the install tree. |
| `prepare-staging-directory.sh` | Assembles the built files into the installer's staging layout. |
| `meson-doc.sh` | Installs the MSYS packages (libxml2, libxslt, docbook-xml, docbook-xsl) needed to build the bundled documentation. |
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

| Symptom | Cause | Fix |
| --- | --- | --- |
| Flex EOF errors ("end of file in string") | Unix line endings in `.l` files | Re-run the [repository preparation](#repository-preparation) Git commands. |
| Permission errors on `initdb` | The admin user lacks access to the data directory | Grant explicit access (see below). |

```
takeown /f C:\PG_install\data /r /d y
icacls C:\PG_install\data /grant Administrator:(OI)(CI)F /t
```
