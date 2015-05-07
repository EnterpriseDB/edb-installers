@ECHO off

CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64

SET PROCESSOR_ARCHITECTURE=AMD64 
SET INCLUDE=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Include;%INCLUDE%
SET PATH=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Bin\x64;%PATH%
SET LIB=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Lib\x64;%LIB%
SET CL=/D_USING_V120_SDK71_
SET LINK=/SUBSYSTEM:CONSOLE,5.02

SET vTcl_SRC_Dir=%1
SET vTcl_INST_Dir=%2
SET vTk_SRC_Dir=%3

ECHO TCL Source Dir is ... %vTcl_SRC_Dir%
ECHO TCL Install Dir is ... %vTcl_INST_Dir%
ECHO TK Source Dir is ... %vTk_SRC_Dir%

ECHO ....Starting TCL Build - 64 bit....
cd %vTcl_SRC_Dir%\win
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir%
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% install
ECHO ....End Build TCL....

ECHO ....Starting TK Build - 64 bit....
cd %vTk_SRC_Dir%\win
nmake -f makefile.vc COMPILERFLAGS=-DWINVER=0x0500 OPTS=noxp INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir%
nmake -f makefile.vc COMPILERFLAGS=-DWINVER=0x0500 OPTS=noxp INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir% install
ECHO ....End Build TK....
