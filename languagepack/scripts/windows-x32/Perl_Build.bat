@ECHO off 

CALL "C:\Program Files\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
 
SET vPerlBuildDir=%1
SET vPerlInstallDir=%2
SET vPerlModule=%3

ECHO %vPerlBuildDir%
ECHO %vPerlInstallDir%
ECHO %vPerlModule%

SET INCLUDE=%ProgramFiles%\Microsoft SDKs\Windows\7.1A\Include;%INCLUDE%
SET PATH=%ProgramFiles%\Microsoft SDKs\Windows\7.1A\Bin;D:\pginstaller.auto\output\bin;D:\pginstaller.auto\output\lib;C:\pgBuild32\bin;C:\pgBuild32\lib;%PATH%
REM SET PATH=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Bin;D:\pginstaller.auto\output\bin;D:\pginstaller.auto\output\lib;C:\pgBuild32\bin;C:\pgBuild32\lib;%PATH%
SET LIB=%ProgramFiles%\Microsoft SDKs\Windows\7.1A\Lib;%LIB%
SET CL=/D_USING_V120_SDK71_
SET LINK=/SUBSYSTEM:CONSOLE,5.02

IF "%vPerlModule%"=="PERL" GOTO PERL
IF "%vPerlModule%"=="DBI" GOTO DBI
IF "%vPerlModule%"=="DBD" GOTO DBD
IF "%vPerlModule%"=="cpanminus" GOTO cpanminus
IF "%vPerlModule%"=="IPC" GOTO IPC
GOTO END

:PERL
ECHO ....Starting to Make Perl....
CD %vPerlBuildDir%\win32
nmake -f makefile
nmake install
ECHO ....End Make Perl....
GOTO END

:DBI
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBI....
cpan -f -n install DBI
ECHO ....End Install DBI....
GOTO END

:IPC
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install IPC::Run...
cpanm -f -n install IPC::Run
ECHO ....End Install IPC::Run...

:DBD
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install DBD::PG....
cpanm -f -n install DBD::Pg
ECHO ....End Install DBD::PG....

:cpanminus
SET PATH=%vPerlInstallDir%\bin;%PATH%
CD %vPerlInstallDir%\bin
ECHO ....Starting to Install App::cpanminus....
cpan install App::cpanminus
ECHO ....End Install App::cpanminus....

:END
