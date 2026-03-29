@ECHO OFF

CALL "C:\\Program Files\\Microsoft Visual Studio\\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64

ECHO Creating build and install dirs...

SET BASE_PATH=D:\a\postgresql-packaging-foundation\postgresql-packaging-foundation

mkdir %BASE_PATH%\%SOURCE_DIR%\meson-build
mkdir %BASE_PATH%\%SOURCE_DIR%\meson-install

SET
PATH=C:\hostedtoolcache\windows\Python\%PYTHON_VERSION%\x64;C:\hostedtoolcache\windows\Python\%PYTHON_VERSION%\x64\Scripts;%BASE_PATH%\pkg-config-lite-%PKGCONFIG_VERSION%\bin;%BASE_PATH%\strawberry-perl-%PERL_VERSION%-64bit-portable\perl\bin;%BASE_PATH%\openssl\bin;%BASE_PATH%\zlib\bin;%BASE_PATH%\libxml2\bin;%BASE_PATH%\zstd\bin;%BASE_PATH%\1z4\bin;%BASE_PATH%\libxslt\bin;%BASE_PATH%\icu\bin;%BASE_PATH%\gettext\bin;%PATH%

SET PKG_CONFIG_PATH=%BASE_PATH%\zlib\lib\pkgconfig;%BASE_PATH%\libxml2\lib\pkgconfig;%BASE_PATH%\zstd\lib\pkgconfig;%BASE_PATH%\lz4\lib\pkgconfig;%BASE_PATH%\libxslt\lib\pkgconfig;%BASE_PATH%\icu\lib64\pkgconfig;C:\Users\runneradmin\AppData\Local\Apps\Tcl86\lib\pkgconfig;%BASE_PATH%\uuid\lib\pkgconfig

meson setup %BASE_PATH%\%SOURCE_DIR% %BASE_PATH%\%SOURCE_DIR%\meson-build --prefix=%BASE_PATH%\%SOURCE_DIR%\meson-install -Dnls=enabled -Duuid=ossp -Dplperl=enabled -Dssl=openssl -Dextra_include_dirs=%BASE_PATH%\gettext\include,%BASE_PATH%\openssl\include -Dextra_lib_dirs=%BASE_PATH%\gettext\lib,%BASE_PATH%\openssl\lib

cd %BASE_PATH%\%SOURCE_DIR%\meson-build
ECHO meson build dir content
dir
ninja --verbose

ninja src/interfaces/ecpg/test/compat_informix/charfuncs.c
ninja src/interfaces/ecpg/test/compat_informix/dec_test.c
ninja src/interfaces/ecpg/test/compat_informix/describe.c
ninja src/interfaces/ecpg/test/compat_informix/intoasc.c
ninja src/interfaces/ecpg/test/compat_informix/rfmtdate.c
ninja src/interfaces/ecpg/test/compat_informix/rfmtlong.c
ninja src/interfaces/ecpg/test/compat_informix/rnull.c
ninja src/interfaces/ecpg/test/compat_informix/sqlda.c
ninja src/interfaces/ecpg/test/compat_informix/test_informix.c
ninja src/interfaces/ecpg/test/compat_informix/test_informix2.c

ninja src/interfaces/ecpg/test/compat_informix/charfuncs.exe
ninja src/interfaces/ecpg/test/compat_informix/dec_test.exe
ninja src/interfaces/ecpg/test/compat_informix/describe.exe
ninja src/interfaces/ecpg/test/compat_informix/intoasc.exe
ninja src/interfaces/ecpg/test/compat_informix/rfmtdate.exe
ninja src/interfaces/ecpg/test/compat_informix/rfmtlong.exe
ninja src/interfaces/ecpg/test/compat_informix/rnull.exe
ninja src/interfaces/ecpg/test/compat_informix/sqlda.exe
ninja src/interfaces/ecpg/test/compat_informix/test_informix.exe
ninja src/interfaces/ecpg/test/compat_informix/test_informix2.exeg

ninja install
dir %BASE_PATH%\%SOURCE_DIR%\meson-install
