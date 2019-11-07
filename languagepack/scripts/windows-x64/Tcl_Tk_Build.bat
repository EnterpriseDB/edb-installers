@ECHO off

@REM CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64


SET vTcl_SRC_Dir=%1
SET vTcl_INST_Dir=%2
SET vTk_SRC_Dir=%3

ECHO TCL Source Dir is ... %vTcl_SRC_Dir%
ECHO TCL Install Dir is ... %vTcl_INST_Dir%
ECHO TK Source Dir is ... %vTk_SRC_Dir%

ECHO ....Starting TCL Build - 64 bit....
CD %vTcl_SRC_Dir%\win
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir%
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% install
ECHO ....End Build TCL....

ECHO ....Starting TK Build - 64 bit....
CD %vTk_SRC_Dir%\win
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir%
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir% install
ECHO ....End Build TK....
