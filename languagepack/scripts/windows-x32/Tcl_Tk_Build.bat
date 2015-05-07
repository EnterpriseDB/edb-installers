call "C:\Program Files\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86

set INCLUDE=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Include;%INCLUDE%
set PATH=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Bin;%PATH%
set LIB=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Lib;%LIB%
set CL=/D_USING_V120_SDK71_
set LINK=/SUBSYSTEM:CONSOLE,5.01

set vTcl_SRC_Dir=%1
set vTcl_INST_Dir=%2
set vTk_SRC_Dir=%3

echo TCL Source Dir is ... %vTcl_SRC_Dir%
echo TCL Install Dir is ... %vTcl_INST_Dir%
echo TK Source Dir is ... %vTk_SRC_Dir%

echo ....Starting TCL Build - 32 bit....
cd %vTcl_SRC_Dir%\win
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir%
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% install
echo ....End Build TCL....

echo ....Starting TK Build - 32 bit....
cd %vTk_SRC_Dir%\win
nmake -f makefile.vc COMPILERFLAGS=-DWINVER=0x0500 OPTS=noxp INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir%
nmake -f makefile.vc COMPILERFLAGS=-DWINVER=0x0500 OPTS=noxp INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir% install
echo ....End Build TK...
