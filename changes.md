# PostgreSQL installer release 13.22-1 (2025-08-14)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `pgAdmin4` to version `9.6`.
    - Update `libxml2` to version `2.14.5`.
    - Update `curl` to version `8.15.0`.
    - Update `openssl` to version `3.0.17`.

- **Additional dependencies (macOS)**
    - Update `libpng2` to version `1.6.50`.
    - Update `e2fsprogs` to version `1.47.3`.


## Bug Fixes 🐛
- **Fix:** Improvements in DoCmd function in initcluster script (Issue #347)
- **Fix:** Use call operator to run icacls.exe in the initcluster.ps1 (Issue #332)
- **Fix:** Update the function in initcluster.ps1 to suppress the warning messages username SID is not available (Issue #318)
- **Fix:** Update initcluster.ps1 to convert "English, <Country> with English_<Country>" before passing to initdb.exe
