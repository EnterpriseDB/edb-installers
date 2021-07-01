@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64

SET vPerlBuildDir=%1
SET vPerlInstallDir=%2
SET vPgBuildDir=%3
SET vPerlModule=%4

ECHO %vPerlBuildDir%
ECHO %vPerlInstallDir%
ECHO %vPgBuildDir%
ECHO %vPerlModule%

SET PATH=%vPgBuildDir%\bin;%vPgBuildDir%\lib;C:\pgBuild64\bin;C:\pgBuild64\lib;%PATH%

IF "%vPerlModule%"=="PERL" GOTO PERL
IF "%vPerlModule%"=="DBI" GOTO DBI
IF "%vPerlModule%"=="DBD" GOTO DBD
IF "%vPerlModule%"=="CPANMINUS" GOTO CPANMINUS
IF "%vPerlModule%"=="IPC" GOTO IPC
IF "%vPerlModule%"=="WIN32PROCESS" GOTO WIN32PROCESS
IF "%vPerlModule%"=="INSTALL" GOTO INSTALL
GOTO END

:PERL
ECHO ....Starting to Make Perl....
CD %vPerlBuildDir%\win32
nmake -f makefile
nmake install
ECHO ....End Make Perl....
GOTO END

:DBI
SET PATH=%vPerlInstallDir%\bin\;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBI....
cpanm -f -n install DBI
ECHO ....End Install DBI....
GOTO END

:DBD
SET PATH=%vPgBuildDir%\bin\;%vPerlInstallDir%\bin;%PATH%
SET POSTGRES_LIB=%vPgBuildDir%\lib\
SET POSTGRES_INCLUDE=%vPgBuildDir%\include\
SET POSTGRES_HOME=%vPgBuildDir%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBD::PG....
cpanm -f -n install DBD::Pg
ECHO ....End Install DBD::PG....
GOTO END

:CPANMINUS
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install App::cpanminus....
cpan install App::cpanminus
ECHO ....End Install App::cpanminus....
GOTO END

:IPC
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install IPC::Run....
cpanm -f -n install IPC::Run
ECHO ....End Install IPC::Run....
GOTO END

:WIN32PROCESS
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install Win32::Process....
cpan install Win32::Process
ECHO ....End Install Win32::Process....
GOTO END

:INSTALL
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Uninstall install module...
cpanm -f --uninstall install
ECHO ....End Uninstall install module...
:END
