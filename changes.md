# PostgreSQL installer release 18beta3 (2025-08-14)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `pgAdmin4` to version `9.6`
    - Update `curl` to version `8.15.0`
    - Update `openssl` to version `3.5.2`
 
- **Additional dependencies (MacOS)**
    - Update `libpng2` to version `1.6.50`
    - Update `e2fsprogs` to version `1.47.3`
    - Update `libxml2` to version `2.14.5`
 
- **Additional dependencies (Windows)**
    - Update `libxml2` to version `2.13.8-2`. This includes security patches/commits from HEAD of 2.13 (Upto a489aca8) to 2.13.8

## Bug Fixes 🐛
- **Fix:** Improvements in DoCmd function in initcluster script (Issue #347)
- **Fix:** Use call operator to run icacls.exe in the initcluster.ps1 (Issue #332)
- **Fix:** Update initcluster.ps1 to convert "English, <Country> with English_<Country>" before passing to initdb.exe
