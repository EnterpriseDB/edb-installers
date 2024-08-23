@ECHO OFF

CALL "C:\\Program Files\\Microsoft Visual Studio\\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64

ECHO pg source = %SOURCE_DIR%
ECHO python version = %PYTHON_VERSION%
ECHO perl version = %PERL_VERSION%
ECHO pkgconfig version = %PKGCONFIG_VERSION%

ECHO Creating build and install dirs...

mkdir D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR%\meson-build
mkdir D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR%\meson-install

SET BASE_PATH=D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation

SET
PATH=C:\hostedtoolcache\windows\Python\%PYTHON_VERSION%\x64;C:\hostedtoolcache\windows\Python\%PYTHON_VERSION%\x64\Scripts;%BASE_PATH%\pkg-config-lite-%PKGCONFIG_VERSION%\bin;%BASE_PATH%\strawberry-perl-%PERL_VERSION%-64bit-portable\perl\bin;%BASE_PATH%\openssl\bin;%BASE_PATH%\zlib\bin;%BASE_PATH%\libxml2\bin;%BASE_PATH%\zstd\bin;%BASE_PATH%\1z4\bin;%BASE_PATH%\libxslt\bin;%BASE_PATH%\icu\bin;%PATH%

SET PKG_CONFIG_PATH=%BASE_PATH%\zlib\lib\pkgconfig;%BASE_PATH%\libxml2\lib\pkgconfig;%BASE_PATH%\zstd\lib\pkgconfig;%BASE_PATH%\lz4\lib\pkgconfig;%BASE_PATH%\libxslt\lib\pkgconfig;%BASE_PATH%\icu\lib64\pkgconfig;C:\Users\runneradmin\AppData\Local\Apps\Tcl86\lib\pkgconfig;%BASE_PATH%\uuid\lib\pkgconfig

meson setup D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR% D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR%\meson-build --prefix=D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR%\meson-install -Dnls=enabled -Duuid=ossp -Dplperl=enabled -Dssl=openssl -Dextra_include_dirs=D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\gettext\include,D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\openssl\include -Dextra_lib_dirs=D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\gettext\lib,D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\openssl\lib

cd D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR%\meson-build
ECHO meson build dir content
dir
ninja --verbose

ninja install
dir D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation\%SOURCE_DIR%\meson-install
