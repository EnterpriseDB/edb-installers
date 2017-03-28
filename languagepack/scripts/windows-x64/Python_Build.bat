@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64

SET vPythonBuildDir=%1
SET vPythonInstallDir=%2
SET vScriptsDir=%3
SET vPgBuildDir=%4
SET vPerlInstallDir=%5
SET vOpenSSLDir=%6
SET vPythonBuild=%7
 
ECHO vPythonBuildDir ----  %vPythonBuildDir%
ECHO vPythonInstallDir ---- %vPythonInstallDir%
ECHO vScriptsDir ---- %vScriptsDir%
ECHO vPythonBuild ---- %vPythonBuild%
ECHO vPerlInstallDir ---- %vPerlInstallDir%
ECHO vOpenSSLDir ---- %vOpenSSLDir%
ECHO vPgBuildDir ---- %vPgBuildDir%

ECHO "Setting Perl's installation path"
SET PATH=%vPerlInstallDir%\bin;%PATH%

IF "%vPythonBuild%"=="GETEXTERNALS" GOTO GETEXTERNALS
IF "%vPythonBuild%"=="UPGRADE" GOTO UPGRADE
IF "%vPythonBuild%"=="BUILD" GOTO BUILD
IF "%vPythonBuild%"=="INSTALL" GOTO INSTALL
GOTO EXIT

:GETEXTERNALS
ECHO Executing batach file %vPythonBuildDir%\PCbuild\get_externals.bat
CALL %vPythonBuildDir%\PCbuild\get_externals.bat
GOTO EXIT

:UPGRADE
ECHO Upgrading %vPythonBuildDir%\PCbuild\pcbuild.sln
CD %vPythonBuildDir%\PCbuild
devenv.exe "pcbuild.sln" /upgrade
GOTO EXIT

:BUILD
ECHO ....Starting to Make Python....
ECHO Generating %vPythonBuildDir%\externals\xz-5.0.5\bin_i486\liblzma.lib
CD %vPythonBuildDir%\externals\xz-5.0.5\bin_i486
REM dumpbin /exports liblzma.dll > liblzma.def
lib /def:liblzma.def /machine:x86 /out:liblzma.lib

ECHO Upgrading %vPythonBuildDir%\PCbuild\pcbuild.sln
CD %vPythonBuildDir%\PCbuild
devenv.exe "pcbuild.sln" /upgrade

ECHO Executing batach file %vPythonBuildDir%\PCbuild\build.bat
CD %vPythonBuildDir%\PCbuild\build.bat
CALL %vPythonBuildDir%\PCbuild\build.bat -e -c Release -t Build -p Win64
ECHO ....End Make Python....
GOTO EXIT

:INSTALL
ECHO copying py*.exe from %vPythonBuildDir%\PCbuild to %vPythonInstallDir%\
XCOPY /f /y %vPythonBuildDir%\PCbuild\py*.exe %vPythonInstallDir%\

ECHO copying py*.dll from %vPythonBuildDir%\PCbuild to %vPythonInstallDir%
XCOPY /f /y %vPythonBuildDir%\PCbuild\py*.dll %vPythonInstallDir%\

ECHO making DIR %vPythonInstallDir%\Include
mkdir %vPythonInstallDir%\Include

ECHO copying Files %vPythonBuildDir%\Include\* to %vPythonInstallDir%\Include\
XCOPY /e /Q /Y  %vPythonBuildDir%\Include\* %vPythonInstallDir%\Include\

ECHO making DIR %vPythonInstallDir%\Lib
mkdir %vPythonInstallDir%\Lib

ECHO copying Files %vPythonBuildDir%\Lib\* to %vPythonInstallDir%\Lib\
XCOPY /s /e /f /h %vPythonBuildDir%\Lib\* %vPythonInstallDir%\Lib\

ECHO copying Files %vPythonBuildDir%\externals\tcltk\lib\* to %vPythonInstallDir%\Lib\
XCOPY /s /e /f /h %vPythonBuildDir%\externals\tcltk\lib\* %vPythonInstallDir%\Lib\

ECHO making DIR %vPythonInstallDir%\Tools
mkdir %vPythonInstallDir%\Tools

ECHO copying Files %vPythonBuildDir%\Tools\* to %vPythonInstallDir%\Tools\
XCOPY /e /Q /Y %vPythonBuildDir%\Tools\* %vPythonInstallDir%\Tools\

ECHO copying pyconfig.h from %vPythonBuildDir%\PC\pyconfig.h to %vPythonInstallDir%\Include\
XCOPY /f /y  %vPythonBuildDir%\PC\pyconfig.h %vPythonInstallDir%\Include\

ECHO making DIR %vPythonInstallDir%\libs
mkdir %vPythonInstallDir%\libs

ECHO copying Files %vPythonBuildDir%\PCbuild\*.lib to %vPythonInstallDir%\libs\
XCOPY /f /y %vPythonBuildDir%\PCbuild\*.lib %vPythonInstallDir%\libs\

ECHO copying Files %vPythonBuildDir%\externals\tcltk\lib\*.lib to %vPythonInstallDir%\libs\
XCOPY /f /y %vPythonBuildDir%\externals\tcltk\lib\*.lib %vPythonInstallDir%\libs\

ECHO copying Files %vPythonBuildDir%\externals\tcltk\lib\tix8.4.3\*.lib to %vPythonInstallDir%\libs\
XCOPY /f /y %vPythonBuildDir%\externals\tcltk\lib\tix8.4.3\*.lib %vPythonInstallDir%\libs\

ECHO copying Files %vPythonBuildDir%\externals\tcl-8.6.1.0\win\Release_VC12\tcldde14.lib to %vPythonInstallDir%\libs\
XCOPY /f /y %vPythonBuildDir%\externals\tcl-8.6.1.0\win\Release_VC12\tcldde14.lib %vPythonInstallDir%\libs\

ECHO copying Files %vPythonBuildDir%\externals\tcl-8.6.1.0\win\Release_VC12\tclreg13.lib to %vPythonInstallDir%\libs\
XCOPY /f /y %vPythonBuildDir%\externals\tcl-8.6.1.0\win\Release_VC12\tclreg13.lib %vPythonInstallDir%\libs\

ECHO making DIR %vPythonInstallDir%\DLLs
mkdir %vPythonInstallDir%\DLLs

ECHO copying Files %vPythonBuildDir%\PCbuild\*.pyd to %vPythonInstallDir%\DLLs\
XCOPY /f /y %vPythonBuildDir%\PCbuild\*.pyd %vPythonInstallDir%\DLLs\

ECHO copying Files %vPythonBuildDir%\PCbuild\*.dll to %vPythonInstallDir%\DLLs\
XCOPY /f /y %vPythonBuildDir%\PCbuild\*.dll %vPythonInstallDir%\DLLs\

ECHO copying Files %vOpenSSLDir%\bin\libeay32.dll to %vPythonInstallDir%\DLLs
XCOPY /f /y %vOpenSSLDir%\bin\libeay32.dll %vPythonInstallDir%\DLLs

ECHO copying Files  %vOpenSSLDir%\bin\ssleay32.dll to %vPythonInstallDir%\DLLs
XCOPY /f /y %vOpenSSLDir%\bin\ssleay32.dll %vPythonInstallDir%\DLLs

ECHO deleting Files %vPythonInstallDir%\DLLs\python3*.dll
DEL %vPythonInstallDir%\DLLs\python3*.dll

ECHO making DIR %vPythonInstallDir%\tcl
mkdir %vPythonInstallDir%\tcl

ECHO copying Folders & Files %vPythonBuildDir%\externals\tcltk\lib\* to %vPythonInstallDir%\tcl\
XCOPY /s /e /f /h %vPythonBuildDir%\externals\tcltk\lib\* %vPythonInstallDir%\tcl\

ECHO copying Files %vPythonBuildDir%\externals\tcltk\include\* to %vPythonInstallDir%\tcl\include\
XCOPY /s /e /f /h %vPythonBuildDir%\externals\tcltk\include\* %vPythonInstallDir%\tcl\include\

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
SET PATH=%vPythonInstallDir%\Scripts;D:\;%vPgBuildDir%\bin;%PATH%

REM Sometimes pip is not able to download due to network issues.
REM Hence we are tryings to hit pip URL for 5 time.

setlocal EnableDelayedExpansion
set /a "i = 1"
:ITERATOR
    if %i% leq 5 (
	echo ==========iteration !i! ==================
        %vPythonInstallDir%\Scripts\easy_install.exe pip
       IF !ERRORLEVEL! == 0 goto BREAK
        echo ====error level is !ERRORLEVEL!===========
        set /a "i = i + 1"
        goto :ITERATOR
    )
goto ERR_HANDLER

:BREAK

CD %vPythonInstallDir%\Scripts
SET LINK="/FORCE:MULTIPLE"

pip install psycopg2==2.6.2 --global-option="build_ext"
pip install Pillow==3.4.2 --global-option="build_ext" --global-option="--disable-zlib" --global-option="--disable-jpeg"

ECHO pip install -r %vScriptsDir%\..\requirements.txt
pip install -r %vScriptsDir%\..\requirements.txt

ECHO copying required dll's to %vPythonInstallDir%\Lib\site-packages\psycopg2

XCOPY /f /y %vOpenSSLDir%\bin\libeay32.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vOpenSSLDir%\bin\ssleay32.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vOpenSSLDir%\bin\libintl-8.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vOpenSSLDir%\bin\libiconv-2.dll %vPythonInstallDir%\Lib\site-packages\psycopg2
XCOPY /f /y %vPgBuildDir%\bin\libpq.dll %vPythonInstallDir%\Lib\site-packages\psycopg2

pip list >%vPythonInstallDir%\pip_packages_list.txt

ECHO ....End Install Python....
GOTO EXIT

:ERR_HANDLER
    ECHO Aborting build due to pip failed!
    endlocal
    exit /B 1
GOTO:EOF


:EXIT
    endlocal
    exit /B 0
