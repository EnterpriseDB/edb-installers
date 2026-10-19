@ECHO OFF

CALL "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64
IF ERRORLEVEL 1 EXIT /B 1

ECHO Creating build and install dirs...

SET BASE_PATH=D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation

mkdir %BASE_PATH%\%SOURCE_DIR%\meson-build
mkdir %BASE_PATH%\%SOURCE_DIR%\meson-install

REM Auto-detect Tcl (override by setting TCL_DIR in the workflow)
IF NOT DEFINED TCL_DIR (
  FOR /D %%d IN ("%LOCALAPPDATA%\Apps\Tcl*") DO SET "TCL_DIR=%%d"
)
IF NOT DEFINED TCL_DIR (
  ECHO ERROR: No Tcl install found under %LOCALAPPDATA%\Apps
  EXIT /B 1
)
IF NOT EXIST "%TCL_DIR%\lib" (
  ECHO ERROR: Tcl lib directory not found: %TCL_DIR%\lib
  EXIT /B 1
)
IF NOT EXIST "%TCL_DIR%\include\tcl.h" (
  ECHO ERROR: tcl.h not found in %TCL_DIR%\include
  EXIT /B 1
)
IF NOT EXIST "%TCL_DIR%\lib\pkgconfig\tcl.pc" (
  ECHO ERROR: tcl.pc not found in %TCL_DIR%\lib\pkgconfig
  EXIT /B 1
)
ECHO Using Tcl from: %TCL_DIR%

SET PATH=C:\hostedtoolcache\windows\Python\%PYTHON_VERSION%\x64;C:\hostedtoolcache\windows\Python\%PYTHON_VERSION%\x64\Scripts;%BASE_PATH%\pkg-config-lite-%PKGCONFIG_VERSION%\bin;%BASE_PATH%\strawberry-perl-%PERL_VERSION%-64bit-portable\perl\bin;%BASE_PATH%\openssl\bin;%BASE_PATH%\zlib\bin;%BASE_PATH%\libxml2\bin;%BASE_PATH%\zstd\bin;%BASE_PATH%\lz4\bin;%BASE_PATH%\libxslt\bin;%BASE_PATH%\icu\bin;%BASE_PATH%\gettext\bin;%BASE_PATH%\uuid\bin;%TCL_DIR%\bin;%PATH%

SET PKG_CONFIG_PATH=%BASE_PATH%\zlib\lib\pkgconfig;%BASE_PATH%\libxml2\lib\pkgconfig;%BASE_PATH%\zstd\lib\pkgconfig;%BASE_PATH%\lz4\lib\pkgconfig;%BASE_PATH%\libxslt\lib\pkgconfig;%BASE_PATH%\icu\lib64\pkgconfig;%TCL_DIR%\lib\pkgconfig;%BASE_PATH%\uuid\lib\pkgconfig

meson setup %BASE_PATH%\%SOURCE_DIR% %BASE_PATH%\%SOURCE_DIR%\meson-build ^
  --prefix=%BASE_PATH%\%SOURCE_DIR%\meson-install ^
  -Dnls=enabled ^
  -Duuid=ossp ^
  -Dplperl=enabled ^
  -Dpltcl=enabled ^
  -Dssl=openssl ^
  -Dextra_include_dirs=%BASE_PATH%\gettext\include,%BASE_PATH%\openssl\include ^
  -Dextra_lib_dirs=%BASE_PATH%\gettext\lib,%BASE_PATH%\openssl\lib
IF ERRORLEVEL 1 (
  ECHO ERROR: meson setup failed
  EXIT /B 1
)

cd %BASE_PATH%\%SOURCE_DIR%\meson-build
ECHO meson build dir content
dir

ninja --verbose
IF ERRORLEVEL 1 (
  ECHO ERROR: ninja build failed
  EXIT /B 1
)

ninja install
IF ERRORLEVEL 1 (
  ECHO ERROR: ninja install failed
  EXIT /B 1
)

dir %BASE_PATH%\%SOURCE_DIR%\meson-install
