@ECHO off

CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86

SET vTcl_SRC_Dir=%1
SET vTcl_INST_Dir=%2
SET vTk_SRC_Dir=%3

ECHO TCL Source Dir is ... %vTcl_SRC_Dir%
ECHO TCL Install Dir is ... %vTcl_INST_Dir%
ECHO TK Source Dir is ... %vTk_SRC_Dir%

ECHO ....Starting TCL Build - 32 bit....
cd %vTcl_SRC_Dir%\win
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir%
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% install
ECHO ....End Build TCL....

ECHO ....Starting TK Build - 32 bit....
cd %vTk_SRC_Dir%\win
nmake -f makefile.vc COMPILERFLAGS=-DWINVER=0x0500 OPTS=noxp INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir%
nmake -f makefile.vc COMPILERFLAGS=-DWINVER=0x0500 OPTS=noxp INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir% install
ECHO ....End Build TK....
