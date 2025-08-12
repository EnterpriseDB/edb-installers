# PostgreSQL installer release 18beta3 (2025-08-14)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `pgAdmin4` to version `9.6`.
    - Update `libxml2` to version `2.14.5`.
    - Update `curl` to version `8.15.0`.
    - Update `openssl` to version `3.5.2`.

## Bug Fixes 🐛
- **Fix:** Improvements in DoCmd function in initcluster script (Issue #347)
- **Fix:** Use call operator to run icacls.exe in the initcluster.ps1 (Issue #332)
- **Fix:** Update initcluster.ps1 to convert "English, <Country> with English_<Country>" before passing to initdb.exe
