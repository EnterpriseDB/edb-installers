# Changelog

<!--
## [X.Y-Z] - YYYY-MM-DD

- **Security:**
- **Enhancement:**
- **Fix:**
- **Changed:**
- **Dependencies:**
  - Updated `package` to `version`
-->

## [19.0] - 2026-11-19

## [19rc2] - 2026-11-12

- **Enhancement:** Code-signed all installer and server binaries, including `bin\*.exe` (`postgres.exe`, `psql.exe`, etc.), `bin\*.dll`, `lib\*.dll`, and `.ps1`/`.exe` files in the `server` directory ([#713](https://github.com/EnterpriseDB/edb-installers/issues/713), [#720](https://github.com/EnterpriseDB/edb-installers/issues/720), [#731](https://github.com/EnterpriseDB/edb-installers/issues/731), [#758](https://github.com/EnterpriseDB/edb-installers/issues/758)).
- **Fix:** Decoupled `gettext` and `iconv` dependencies ([#743](https://github.com/EnterpriseDB/edb-installers/issues/743), [#754](https://github.com/EnterpriseDB/edb-installers/issues/754)):
  - Built `iconv` and `gettext` from unmodified upstream sources as standalone components using native Win32 threading, removing the dependency on `libwinpthread-1.dll`.
  - Removed the obsolete `libwinpthread-1.dll` and configured the installer to delete existing copies from the server `bin` directory during upgrades.
  - Updated third-party license files to list `gettext` and `libiconv` under LGPL v3, and `gettext` under the 3-clause BSD license to reflect its dual licensing.
- **Dependencies:**
  - Updated `zlib` to `1.4` (security fixes)
  - Updated `lz4` to `1.11.1`
  - Updated `curl` to `8.23.0`
  - Updated `wxWidgets` to `3.2.12`
  - Updated `krb5` to `1.22.3`

## [19rc1] - 2026-10-15

- **Dependencies:**
  - Updated `curl` to `8.23.0`
  - Updated `OpenSSL` to `3.5.9`

## [19beta4] - 2026-09-24

- **Dependencies:**
  - Updated `curl` to `8.22.0`
  - Updated `libxml2` to `2.15.4`
  - Updated `ICU` to `78.3`
  - Updated `OpenSSL` to `3.5.8`
  - Updated `gettext` to `1.0`

## [19beta3] - 2026-08-13

- **Dependencies:**
  - Updated `wxWidgets` to `3.2.11`
  - Updated `libiconv` to `1.19`

## [19beta2] - 2026-07-16

- **Dependencies:**
  - Updated `curl` to `8.21.0`
  - Updated `OpenSSL` to `3.5.7`

## [19beta1] - 2026-06-04

- **Changed:** Stopped bundling pgAdmin 4 with the PostgreSQL installer; after PostgreSQL is installed, the installer now detects existing pgAdmin 4 installations and offers to download and install the latest version directly from the official pgAdmin download server.
