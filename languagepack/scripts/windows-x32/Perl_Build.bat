@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86

SET vPerlBuildDir=%1
SET vPerlInstallDir=%2
SET vPerlModule=%3

ECHO %vPerlBuildDir%
ECHO %vPerlInstallDir%
ECHO %vPerlModule%

SET SHELL=
SET PATH=D:\pginstaller.auto\output\bin;D:\pginstaller.auto\output\lib;C:\pgBuild32\lib;C:\pgBuild32\dmake;C:\MinGW\mingw-w64\mingw32\bin;C:\pgBuild32\bin;%PATH%

IF "%vPerlModule%"=="PERL" GOTO PERL
IF "%vPerlModule%"=="DBI" GOTO DBI
IF "%vPerlModule%"=="DBD" GOTO DBD
IF "%vPerlModule%"=="cpanminus" GOTO cpanminus
IF "%vPerlModule%"=="IPC" GOTO IPC
GOTO END

:PERL
ECHO ....Starting to Make Perl....
CD %vPerlBuildDir%\win32
dmake -f makefile.mk
dmake -f makefile.mk install

ECHO generating perl524.lib from %vPerlBuildDir%\win32\perl524.def in %vPerlInstallDir%\lib\CORE
lib /def:%vPerlBuildDir%\win32\perl524.def /out:%vPerlInstallDir%\lib\CORE\perl524.lib /machine:x86

ECHO deleting perl524.exp from %vPerlInstallDir%\lib\CORE
DEL %vPerlInstallDir%\lib\CORE\perl524.exp

ECHO copying libgcc_s_seh-1.dll from C:\MinGW\mingw-w64\mingw32\bin to %vPerlInstallDir%\bin
XCOPY /f /y C:\MinGW\mingw-w64\mingw32\bin\libgcc_s_sjlj-1.dll %vPerlInstallDir%\bin

ECHO copying libstdc++-6.dll from C:\MinGW\mingw-w64\mingw32\bin to %vPerlInstallDir%\bin
XCOPY /f /y C:\MinGW\mingw-w64\mingw32\bin\libstdc++-6.dll %vPerlInstallDir%\bin

ECHO ....End Make Perl....
GOTO END

:DBI
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBI....
cpan install DBI
ECHO ....End Install DBI....
GOTO END

:DBD
SET PATH=%vPerlInstallDir%\bin;%PATH%
set
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBD::PG....
cpanm -f -n install DBD::Pg
ECHO ....End Install DBD::PG....

:cpanminus
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install cpanminus....
cpan install App::cpanminus
ECHO ....End Install cpanminus....

:IPC
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install IPC::Run....
cpanm -f -n install IPC::Run
ECHO ....End Install IPC::Run....

:END
