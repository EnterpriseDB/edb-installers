@REM call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86

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
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir%
nmake -f makefile.vc INSTALLDIR=%vTcl_INST_Dir% TCLDIR=%vTcl_SRC_Dir% install
echo ....End Build TK...
