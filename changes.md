# PostgreSQL installer release 19rc2 (2026-11-12)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `lz4` to version `1.11.1`
    - Update `zlib` to version `1.4` (security fixes)
    - Update `curl` to version `8.23.0` (security fixes)
 
- **Additional dependencies (Windows)**
    - Update `wxwidgets` to version `3.2.12`
 
- **Additional dependencies (macOS)**
  - Update `krb5` to version `1.22.3`

## Bug Fixes 🐛
- **Fix:** Windows: decoupled gettext and iconv dependencies (Issues [#743](https://github.com/EnterpriseDB/edb-installers/issues/743), [#754](https://github.com/EnterpriseDB/edb-installers/issues/754))
    - `iconv` and `gettext` are now packaged as standalone components, each sourced directly from its own upstream package instead of gettext supplying both
    - Removed the obsolete `libwinpthread-1.dll`; Windows upgrades now delete the old copy from the server `bin` directory
    - Updated third-party license files: gettext and libiconv are now listed under LGPL v3, and gettext is also listed under the 3-clause BSD license to reflect its dual license
- **Fix:** Windows: binaries are now code signed. `bin\*.exe` (including `postgres.exe`, `psql.exe`, etc.) and `bin\*.dll` files are now signed. The `.ps1` and `.exe` files in the server folder are signed as well (Issues [#713](https://github.com/EnterpriseDB/edb-installers/issues/713), [#720](https://github.com/EnterpriseDB/edb-installers/issues/720), [#731](https://github.com/EnterpriseDB/edb-installers/issues/731), [#758](https://github.com/EnterpriseDB/edb-installers/issues/758))
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 19rc1 (2026-10-15)
- **Dependencies (macOS & Windows)**
    - Update `curl` to version `8.23.0`
    - Update `openssl` to version `3.5.9`
      
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 19beta4 (2026-09-24)
- **Dependencies (macOS & Windows)**
    - Update `curl` to version `8.22.0`
    - Update `libxml2` to version `2.15.4`
    - Update `icu` to version `78.3`
    - Update `openssl` to version `3.5.8`
      
- **Additional dependencies (Windows)**  
     - Update `gettext` to version `1.0`
 
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 19beta3 (2026-08-13)
- **Dependencies (macOS & Windows)**
    - Update `wxwidgets` to version `3.2.11`
    - Update `libiconv` to version `1.19`
 
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 19beta2 (2026-07-16)
- **Dependencies (macOS & Windows)**
    - Update `curl` to version `8.21.0`
    - Update `openssl` to version `3.5.7`
 
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 19beta1 (2026-06-04)
## Changes 🛠️
- pgAdmin 4 is no longer bundled with the PostgreSQL Windows & Mac installer. After PostgreSQL is installed, the installer now detects the existing pgAdmin 4 installation status on the machine and offers to download and install the latest version directly from the official pgAdmin download server.
