@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86

SET vPythonBuildDir=%1
SET vPythonInstallDir=%2
SET vScriptsDir=%3
SET vTclInstallDir=%4
SET vXZDir=%5
SET vOpenSSLDir=%6
SET vPgBuildDir=%7
 
ECHO vPythonBuildDir ----  %vPythonBuildDir%
ECHO vPythonInstallDir ---- %vPythonInstallDir%
ECHO vScriptsDir ---- %vScriptsDir%
ECHO vTclInstallDir ----  %vTclInstallDir%
ECHO vXZDir ----  %vXZDir%
ECHO vOpenSSLDir ----  %vOpenSSLDir%

CD %vPythonBuildDir%\PCbuild
devenv.exe /upgrade %vPythonBuildDir%\PCbuild\pcbuild.sln

REM ECHO Copying external-common.bat from scripts to %vPythonBuildDir%\PCbuild\
REM COPY /y %vScriptsDir%\external-common.bat  %vPythonBuildDir%\Tools\buildbot\

REM CD %vPythonBuildDir%

REM ECHO Executing batach file %vPythonBuildDir%\Tools\buildbot\external-common.bat
REM CALL %vPythonBuildDir%\Tools\buildbot\external-common.bat

REM ECHO Changing Directory to C:\LanguagePacks\xz-5.0.3\bin_x86-64
REM CD %vXZDir%\bin_i486
REM dumpbin	/exports liblzma.dll > liblzma.def
CD %vXZDir%\bin_i486
lib /def:liblzma.def /lib:liblzma.lib

CD %vPythonBuildDir%\PCbuild
msbuild pcbuild.sln /p:Configuration=Release /p:PlatformToolset=v120_xp /p:tcltkDir="%vTclInstallDir%" /p:tcltkLib="%vTclInstallDir%\lib\tcl85.lib;%vTclInstallDir%\lib\tk85.lib" /p:lzmaDir="%vXZDir%" /p:opensslDir="%vOpenSSLDir%"

ECHO copying py*.exe from %vPythonBuildDir%\PCbuild\ to %vPythonInstallDir%
XCOPY /f /y %vPythonBuildDir%\PCbuild\py*.exe %vPythonInstallDir%

ECHO copying py*.dll from %vPythonBuildDir%\PCbuild to %vPythonInstallDir% 
XCOPY /f /y %vPythonBuildDir%\PCbuild\py*.dll %vPythonInstallDir%

ECHO making DIR %vPythonInstallDir%\include
MKDIR %vPythonInstallDir%\include

ECHO copying Files %vPythonBuildDir%\include\* to %vPythonInstallDir%\include
XCOPY /e /Q /Y  %vPythonBuildDir%\include\* %vPythonInstallDir%\include

ECHO making DIR %vPythonInstallDir%\Lib
MKDIR %vPythonInstallDir%\Lib

ECHO copying Files %vPythonBuildDir%\Lib\* to %vPythonInstallDir%\Lib
XCOPY /s /e /f /h %vPythonBuildDir%\Lib\* %vPythonInstallDir%\Lib

ECHO making DIR %vPythonInstallDir%\Tools
MKDIR %vPythonInstallDir%\Tools

ECHO copying Files %vPythonBuildDir%\Tools\* to %vPythonInstallDir%\Tools
XCOPY /e /Q /Y %vPythonBuildDir%\Tools\* %vPythonInstallDir%\Tools

ECHO copying errmap.h from %vPythonBuildDir%\PC\errmap.h to %vPythonInstallDir%\Include
XCOPY /f /y %vPythonBuildDir%\PC\errmap.h %vPythonInstallDir%\Include

ECHO copying pyconfig.h from %vPythonBuildDir%\PC\pyconfig.h to %vPythonInstallDir%\Include
XCOPY /f /y  %vPythonBuildDir%\PC\pyconfig.h %vPythonInstallDir%\Include

ECHO making DIR %vPythonInstallDir%\libs
MKDIR %vPythonInstallDir%\libs

ECHO copying Files %vPythonBuildDir%\PCbuild\*.lib to %vPythonInstallDir%\libs
XCOPY /f /y %vPythonBuildDir%\PCbuild\*.lib %vPythonInstallDir%\libs

ECHO making DIR %vPythonInstallDir%\DLLs
MKDIR %vPythonInstallDir%\DLLs

ECHO copying Files %vPythonBuildDir%\PCbuild\*.pyd to %vPythonInstallDir%\DLLs
XCOPY /f /y %vPythonBuildDir%\PCbuild\*.pyd %vPythonInstallDir%\DLLs

ECHO copying Files %vPythonBuildDir%\PCbuild\*.dll to %vPythonInstallDir%\DLLs
XCOPY /f /y %vPythonBuildDir%\PCbuild\*.dll %vPythonInstallDir%\DLLs

ECHO copying Files %vTclInstallDir%\bin\*.dll to %vPythonInstallDir%\DLLs
XCOPY /f /y %vTclInstallDir%\bin\*.dll %vPythonInstallDir%\DLLs

ECHO copying Files %vOpenSSLDir%\bin\libeay32.dll to %vPythonInstallDir%\DLLs
XCOPY /f /y %vOpenSSLDir%\bin\libeay32.dll %vPythonInstallDir%\DLLs

ECHO copying Files  %vOpenSSLDir%\bin\ssleay32.dll to %vPythonInstallDir%\DLLs
XCOPY /f /y %vOpenSSLDir%\bin\ssleay32.dll %vPythonInstallDir%\DLLs

ECHO copying Files %vPythonBuildDir%\PC\*.ico to %vPythonInstallDir%\DLLs
XCOPY /f /y %vPythonBuildDir%\PC\*.ico %vPythonInstallDir%\DLLs

ECHO making DIR %vPythonInstallDir%\tcl
MKDIR %vPythonInstallDir%\tcl

ECHO copying Folders & Files %vTclInstallDir%\lib\* to %vPythonInstallDir%\tcl
XCOPY /s /e /f /h %vTclInstallDir%\lib\* %vPythonInstallDir%\tcl

ECHO making DIR %vPythonInstallDir%\tcl\include
MKDIR %vPythonInstallDir%\tcl\include

ECHO copying Files %vTclInstallDir%\include\* to %vPythonInstallDir%\tcl\include
XCOPY /s /e /f /h %vTclInstallDir%\include\* %vPythonInstallDir%\tcl\include

SET PYTHONHOME=%vPythonInstallDir%
SET PYTHONPATH=%vPythonInstallDir%;%vPythonInstallDir%\Lib;%vPythonInstallDir%\DLLs
SET PATH=%PYTHONHOME%;%PYTHONPATH%;%PATH%

ECHO PYTHONHOME -------- %PYTHONHOME% 
ECHO PYTHONPATH -------- %PYTHONPATH%
ECHO PATH -------- %PATH%

ECHO Changing Directory to %vScriptsDir%\distribute-0.6.49
CD %vScriptsDir%\distribute-0.6.49
python setup.py install

ECHO Changing Directory to %vPythonInstallDir%\Scripts
CD %vPythonInstallDir%\Scripts
SET PATH=%vPythonInstallDir%\Scripts;%vPgBuildDir%\bin;%PATH%
%vPythonInstallDir%\Scripts\easy_install.exe pip

CD %vPythonInstallDir%\Scripts
SET LINK="/FORCE:MULTIPLE"
pip install psycopg2==2.6
pip install Flask
pip install Jinja2
pip install MarkupSafe
pip install Werkzeug
pip install itsdangerous
pip install Flask-Login
pip install Flask-Security
pip install Flask-WTF
pip install simplejson
rem pip install Pillow
pip install pytz
pip install sphinx "babel<2.0"
pip install cython

ECHO copying required dll's to %vPythonInstallDir%\Lib\site-packages\psycopg2 

XCOPY /f /y %vOpenSSLDir%\bin\libeay32.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vOpenSSLDir%\bin\ssleay32.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vOpenSSLDir%\bin\libintl-8.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vOpenSSLDir%\bin\libiconv-2.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vPgBuildDir%\bin\libpq.dll %vPythonInstallDir%\Lib\site-packages\psycopg2

ECHO copying Pillow binaries to %vPythonInstallDir%
XCOPY /Y /E /Q %vScriptsDir%\EnterpriseDB\LanguagePack\9.5\i386\Python-3.3\Lib\site-packages\* %vPythonInstallDir%\Lib\site-packages\
XCOPY /s /e /f /h %vScriptsDir%\EnterpriseDB\LanguagePack\9.5\i386\Python-3.3\Scripts\* %vPythonInstallDir%\Scripts\

ECHO ------------------------
ECHO ----------Done----------
