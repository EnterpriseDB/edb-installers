# PostgreSQL installer release 16.15-3 (2026-09-01)
## Changes 🛠️
- **Dependencies (Windows)**
    - Update OpenSSL DLLs with version `3.5.8` in pgAdmin 4\runtime

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.15-2 (2026-08-31)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `openssl` version to `3.5.8`

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.15-1 (2026-08-13)
## Changes 🛠️
- Update `pgAdmin4` to version `9.17`

- **Dependencies (macOS & Windows)**
    - Update `openssl` version to `3.5.7`
    - Update `wxwidgets` to version `3.2.11`
    - Update `curl` to version `8.21.0`

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.14-2 (2026-06-11)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `openssl` version to `3.0.21`

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.14-1 (2026-05-14)
## Changes 🛠️
- Update `pgAdmin4` to version `9.15`

- **Dependencies (macOS & Windows)**
    - Update `libxml2` to version `2.15.3`
    - Update `wxwidgets` to version `3.2.10`
    - Update `curl` to version `8.20.0`

- **Dependencies (macOS)**
    - Update `libiconv` to version `1.19`
    - Update `e2fsprogs` to version `1.47.4`
    - Update `expat` to version `2.8.0`
      
## Bug Fixes 🐛
- **Fix:** Updated the Windows packages to include all missing license files in standalone binary archives. (Issue #553)

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.13-3 (2026-04-15)
## Changes 🛠️
- Update `pgAdmin4` to version `9.14`
  
- **Dependencies (MacOS & Windows)**
    - Update `openssl` version to `3.0.20`
    - Update `curl` to version `8.19.0`

-  **Dependencies (MacOS)**
    - Update `libpng` version to `1.6.57`

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.13-2 (2026-03-06)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `libxml2` version to `2.15.2`

-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.13-1 (2026-02-26)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `zlib` version to `1.3.2`
 
## Bug Fixes 🐛
- **Fix:** Prioritize local bin directory for database initialization while executing initdb.exe, Modified initcluster.ps1 to create a controlled execution environment by adding the local $InstallDir\bin folder to the start of the PATH variable. This changes the search priority to ensure initdb.exe finds the matching latest version postgres.exe and avoids version mismatch errors from legacy system files. (Issue #407) (Issue #531)
        
--------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.12-1 (2026-02-12)
## Changes 🛠️
- Update `pgAdmin4` to version `9.12`
 
-  **Dependencies (MacOS)**
    - Update `libpng` to version `1.6.55`
    - Update `wxwidgets` to version `3.2.9`
    - Update `openssl` to version `3.0.19`
 
 ## Bug Fixes 🐛
- **Fix:** Digitally signed getlocales.ps1 and inicluster.ps1 to resolve PowerShell execution policy errors (UnauthorizedAccess) during PostgreSQL installation on windows machine. (Issue #438) (Issue #452) (Issue #459) (Issue #488)
 
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.11-3 (2026-02-09)
## Changes 🛠️

- **Dependencies (Windows)**
    - Update `openssl` to version `3.0.19`
    - Update `wxwidgets` to version `3.2.9`

## Bug Fixes 🐛
- **Fix:** Updated the installer to detect the --extract-only command line switch to resolve an issue where unnecessary registry entries were being created in the Windows Uninstall list during extraction (Issue #405)

--------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.11-2 (2025-12-12)
## Changes 🛠️
- Update `pgAdmin4` to version `9.11`

- **Dependencies (MacOS & Windows)**
    - Update `libxslt` to version `1.1.45`
    - Update `libxml2` to version `2.15.1`

--------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.11-1 (2025-11-13)
## Changes 🛠️
- Update `pgAdmin4` to version `9.9`

- **Dependencies (MacOS & Windows)**
    - Update `libxslt` to version `1.1.43-2`.
      This includes security patch CVE-2025-7424, which addresses a type confusion vulnerability in xmlNode.psvi when handling stylesheet and source nodes.

- **Additional dependencies (MacOS)**
    - Update `curl` to version `8.17.0`
    - Update `pcre` to version `10.47`
    - Update `libedit` to version `20251016-3.1`
    - Update `krb5` to version `1.22.1`

## Bug Fixes 🐛
- **Fix:** Updated dependency checks to ensure the latest required VCRedist package is correctly identified and installed, even if an older version is present on the user's system. (Issue #407)

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.10-2 (2025-10-09)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `openssl` to version `3.0.18`
    - Update `curl` to version `8.16.0`

 - **Additional dependencies (MacOS)**
     - Update `pcre2` to version `10.46`
     - Update `libxml2` to version `2.14.6`
     - Update `expat` to version `2.7.3`
       
 - **Additional dependencies (Windows)**  
     - Update `libxml2` to version `2.13.9`

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 16.10-1 (2025-08-14)
## Changes 🛠️
- **Dependencies (macOS & Windows)**
    - Update `pgAdmin4` to version `9.6`
    - Update `curl` to version `8.15.0`
    - Update `openssl` to version `3.0.17`

- **Additional dependencies (macOS)**
    - Update `libpng2` to version `1.6.50`
    - Update `e2fsprogs` to version `1.47.3`
    - Update `libxml2` to version `2.14.5`

- **Additional dependencies (Windows)**
    - Update `libxml2` to version `2.13.8-2`. This includes security patches/commits from HEAD of 2.13 (Upto a489aca8) to 2.13.8


## Bug Fixes 🐛
- **Fix:** Improvements in DoCmd function in initcluster script (Issue #347)
- **Fix:** Use call operator to run icacls.exe in the initcluster.ps1 (Issue #332)
- **Fix:** Update the function in initcluster.ps1 to suppress the warning messages username SID is not available (Issue #318)
- **Fix:** Update initcluster.ps1 to convert "English, <Country> with English_<Country>" before passing to initdb.exe
