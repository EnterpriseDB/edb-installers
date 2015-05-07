@echo off 

call "C:\Program Files\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
 
set vPerlBuildDir=%1
set vPerlInstallDir=%2

echo %vPerlBuildDir%
echo %vPerlInstallDir%

set INCLUDE=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Include;%INCLUDE%
set PATH=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Bin;D:\edb-postgres.auto-repo\output\bin;D:\edb-postgres.auto-repo\output\lib;C:\pgBuild32\bin;C:\pgBuild32\lib;%PATH%
set LIB=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Lib;%LIB%
set CL=/D_USING_V120_SDK71_
set LINK=/SUBSYSTEM:CONSOLE,5.01

cd %vPerlBuildDir%\win32
echo ....Starting to Make Perl...
nmake -f makefile
echo ....End Make Perl...

cd %vPerlBuildDir%\win32
echo ....Starting to Install Perl...
nmake install
echo ....End Install Perl...

set PATH=%vPerlInstallDir%\bin;%PATH%

cd %vPerlInstallDir%\bin
echo ....Starting to Install CPAN DBI ...
cpan install DBI
 echo ....End Install DBI ...

cd %vPerlInstallDir%\bin
echo ....Starting to Install CPAN DBD::PG ...
cpan install DBD::Pg
echo ....End Install DBD::PG ...
