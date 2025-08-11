# PostgreSQL installer release 17.6-2 (2025-08-30)
## Changes
- **Dependencies (macOS & Windows)**
    - Update `pgAdmin4` to version `9.6`.
    - Update `libxml2` to version `2.14.5`.
    - Update `curl` to version `8.15.0`.

- **Additional dependencies (macOS)**
    - Update `libpng2` to version `1.6.50`.
    - Update `e2fsprogs` to version `1.47.3`.


## Bug Fixes 
- **Fix:** Improvements in DoCmd function in initcluster script (Issue #347)
- **Fix:** disable wrapInScript for getlocales.ps1 as it was failing in few conditions (Issue #343)
- **Fix:** Use call operator to run icacls.exe in the initcluster.ps1 (Issue #332)
- **Fix:** Update the function in initcluster.ps1 to suppress the warning messages username SID is not available (Issue #318)
