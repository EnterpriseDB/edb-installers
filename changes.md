# PostgreSQL - Release v17.6-1 (2025-08-14)
## Changes
- **Dependencies (macOS & windows)**
    - Updated `pgAdmin4` to version `9.6`.
    - Updated `libxml2` to version `2.14.5`.
    - Updated `curl` to version `8.15.0`.

- **Dependencies (macOS)**
    - Updated `libpng2` to version `1.6.50`.
    - Updated `e2fsprogs` to version `1.47.3`.


## Bug Fixes 
- **Fix:** Improvements in DoCmd function in initcluster script (Issue #347)
- **Fix:** disable wrapInScript for getlocales.ps1 as it was failing in few conditions (Issue #343)
- **Fix:** Use call operator to run icacls.exe in the initcluster.ps1 (Issue #332)
- **Fix:** Update the function in initcluster.ps1 to suppress the warning messages username SID is not available (Issue #318)
