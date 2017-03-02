@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64

SET vPythonBuildDir=%1
SET vPythonInstallDir=%2
SET vScriptsDir=%3
SET vTclInstallDir=%4
SET vXZDir=%5
SET vOpenSSLDir=%6
 
ECHO vPythonBuildDir ----  %vPythonBuildDir%
ECHO vPythonInstallDir ---- %vPythonInstallDir%
ECHO vScriptsDir ---- %vScriptsDir%
ECHO vTclInstallDir ----  %vTclInstallDir%
ECHO vXZDir ----  %vXZDir%
ECHO vOpenSSLDir ----  %vOpenSSLDir%

CD %vPythonBuildDir%\PCbuild
devenv.exe /upgrade %vPythonBuildDir%\PCbuild\pcbuild.sln

CD %vPythonBuildDir%

ECHO Executing batach file %vPythonBuildDir%\Tools\buildbot\external-common.bat
CALL %vPythonBuildDir%\Tools\buildbot\external-common.bat

CD %vPythonBuildDir%\PCbuild
msbuild pcbuild.sln /p:Configuration=Release /p:PlatformToolset=v120_xp /p:tcltk64Dir="%vTclInstallDir%" /p:tcltk64Lib="%vTclInstallDir%\lib\tcl85.lib;%vTclInstallDir%\lib\tk85.lib" /p:lzmaDir="%vXZDir%" /p:opensslDir="%vOpenSSLDir%"

ECHO copying py*.exe from %vPythonBuildDir%\PCbuild\ to %vPythonInstallDir%\
XCOPY /f /y %vPythonBuildDir%\PCbuild\py*.exe %vPythonInstallDir%\

ECHO copying py*.exe from %vPythonBuildDir%\PCbuild\amd64 to %vPythonInstallDir%\
XCOPY /f /y %vPythonBuildDir%\PCbuild\amd64\py*.exe %vPythonInstallDir%\

ECHO copying py*.dll from %vPythonBuildDir%\PCbuild\amd64 to %vPythonInstallDir% 
XCOPY /f /y %vPythonBuildDir%\PCbuild\amd64\py*.dll %vPythonInstallDir%\

ECHO making DIR %vPythonInstallDir%\Include
mkdir %vPythonInstallDir%\Include

ECHO copying Files %vPythonBuildDir%\Include\* to %vPythonInstallDir%\Include\
XCOPY /e /Q /Y  %vPythonBuildDir%\Include\* %vPythonInstallDir%\Include\

ECHO making DIR %vPythonInstallDir%\Lib
mkdir %vPythonInstallDir%\Lib

ECHO copying Files %vPythonBuildDir%\Lib\* to %vPythonInstallDir%\Lib\
XCOPY /s /e /f /h %vPythonBuildDir%\Lib\* %vPythonInstallDir%\Lib\

ECHO making DIR %vPythonInstallDir%\Tools
mkdir %vPythonInstallDir%\Tools

ECHO copying Files %vPythonBuildDir%\Tools\* to %vPythonInstallDir%\Tools\
XCOPY /e /Q /Y %vPythonBuildDir%\Tools\* %vPythonInstallDir%\Tools\

ECHO copying errmap.h from %vPythonBuildDir%\PC\errmap.h to %vPythonInstallDir%\Include\
XCOPY /f /y %vPythonBuildDir%\PC\errmap.h %vPythonInstallDir%\Include\

ECHO copying pyconfig.h from %vPythonBuildDir%\PC\pyconfig.h to %vPythonInstallDir%\Include\
XCOPY /f /y  %vPythonBuildDir%\PC\pyconfig.h %vPythonInstallDir%\Include\

ECHO making DIR %vPythonInstallDir%\libs
mkdir %vPythonInstallDir%\libs

ECHO copying Files %vPythonBuildDir%\PCbuild\amd64\*.lib to %vPythonInstallDir%\libs\
XCOPY /f /y %vPythonBuildDir%\PCbuild\amd64\*.lib %vPythonInstallDir%\libs\

ECHO making DIR %vPythonInstallDir%\DLLs
mkdir %vPythonInstallDir%\DLLs

ECHO copying Files %vPythonBuildDir%\PCbuild\amd64\*.pyd to %vPythonInstallDir%\DLLs\
XCOPY /f /y %vPythonBuildDir%\PCbuild\amd64\*.pyd %vPythonInstallDir%\DLLs\

ECHO copying Files %vPythonBuildDir%\PCbuild\amd64\*.dll to %vPythonInstallDir%\DLLs\
XCOPY /f /y %vPythonBuildDir%\PCbuild\amd64\*.dll %vPythonInstallDir%\DLLs\

ECHO copying Files %vTclInstallDir%\bin\*.dll to %vPythonInstallDir%\DLLs\
XCOPY /f /y %vTclInstallDir%\bin\*.dll %vPythonInstallDir%\DLLs\

ECHO copying Files c:\pgbuild64\bin\libeay32.dll to %vPythonInstallDir%\DLLs\
XCOPY /f /y c:\pgbuild64\bin\libeay32.dll %vPythonInstallDir%\DLLs\

ECHO copying Files  c:\pgbuild64\bin\ssleay32.dll to %vPythonInstallDir%\DLLs\
XCOPY /f /y c:\pgbuild64\bin\ssleay32.dll %vPythonInstallDir%\DLLs\

ECHO copying Files %vPythonBuildDir%\PC\*.ico to %vPythonInstallDir%\DLLs\
XCOPY /f /y %vPythonBuildDir%\PC\*.ico %vPythonInstallDir%\DLLs\

ECHO making DIR %vPythonInstallDir%\tcl
mkdir %vPythonInstallDir%\tcl

ECHO copying Folders & Files %vTclInstallDir%\lib\* to %vPythonInstallDir%\tcl\
XCOPY /s /e /f /h %vTclInstallDir%\lib\* %vPythonInstallDir%\tcl\

ECHO making DIR %vPythonInstallDir%\tcl\include
mkdir %vPythonInstallDir%\tcl\include

ECHO copying Files %vTclInstallDir%\include\* to %vPythonInstallDir%\tcl\include\
XCOPY /s /e /f /h %vTclInstallDir%\include\* %vPythonInstallDir%\tcl\include\

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
SET PATH=%vPythonInstallDir%\Scripts;D:\edb-postgres.auto-repo-x64\output\bin;%PATH%
%vPythonInstallDir%\Scripts\easy_install.exe pip

CD %vPythonInstallDir%\Scripts
SET LINK="/FORCE:MULTIPLE"
pip install psycopg2
pip install sphinx==1.4.6

ECHO ------------------------
ECHO ----------Done----------
