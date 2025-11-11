# PostgreSQL installer release 18.1-1 (2025-11-13)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `pgAdmin4` to version `9.9`
    - Update `libxslt` to version `2.14.3-2`.
      This includes security patch CVE-2025-7424, which addresses a type confusion vulnerability in xmlNode.psvi when handling
      stylesheet and source nodes.

- **Additional dependencies (MacOS)**
    - Update `curl` to version `8.17.0`
    - Update `pcre` to version `10.47`
    - Update `libedit` to version `20251016-3.1`
 
## Bug Fixes 🐛
- **Fix:** Updated dependency checks to ensure the latest required VCRedist package
           is correctly identified and installed, even if an older version is present
           on the user's system. (Issue #407)

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 18.0-2 (2025-10-08)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `openssl` to version `3.5.4`

- **Additional dependencies (MacOS)**
    - Update `expat` to version `2.7.3`
 
## Bug Fixes 🐛
- **Fix:** Restored CFLAGS flag to re-enable Universal Binary (arm64/x86_64) support in MacOS. (Issue #409)

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 18.0-1 (2025-09-25)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `pgAdmin4` to version `9.8`
    - Update `openssl` to version `3.5.3`
    - Update `curl` to version `8.16.0`
 
- **Additional dependencies (MacOS)**
    - Update `expat` to version `2.7.2`
    - Update `libxml2` to version `2.14.6`
 
- **Additional dependencies (Windows)**
    - Update `libxml2` to version `2.13.9`

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 18rc1 (2025-09-04)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
    - Update `pgAdmin4` to version `9.7`
 
- **Additional dependencies (MacOS)**
    - Update `gettext` to version `0.26`
    - Update `pcre2` to version `10.46`
    - Update `krb5` to version `1.22.1`      

----------------------------------------------------------------------------------------------------------------------------------

# PostgreSQL installer release 18beta3 (2025-08-14)
## Changes 🛠️
- **Dependencies (MacOS & Windows)**
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
