# PostgreSQL installer release 17.8-1 (2025-02-12)
## Changes 🛠️
- Update `pgAdmin4` to version `9.12`
   
-  **Dependencies (MacOS)**
    - Update `libpng` to version `1.6.55`
    - Update `openssl` to version `3.0.19`
    - Update `wxwidgets` to version `3.2.9`
 
-------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 17.7-3 (2025-02-09)

- **Dependencies (Windows)**
    - Update `openssl` to version `3.0.19`
    - Update `wxwidgets` to version `3.2.9`
 
## Bug Fixes 🐛
- **Fix:** Updated the installer to detect the --extract-only command line switch to resolve an issue where unnecessary registry entries were being created in the Windows Uninstall list during extraction. (Issue #405)
      
----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 17.7-2 (2025-12-12)
## Changes 🛠️
- Update `pgAdmin4` to version `9.11`

- **Dependencies (MacOS & Windows)**
    - Update `libxslt` to version `1.1.45`
    - Update `libxml2` to version `2.15.1`

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 17.7-1 (2025-11-13)
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

# PostgreSQL installer release 17.6-2 (2025-10-09)
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

-----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 17.6-1 (2025-08-14)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `pgAdmin4` to version `9.6`
    - Update `curl` to version `8.15.0`
    - Update `openssl` to version `3.0.17`

- **Additional dependencies (MacOS)**
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
