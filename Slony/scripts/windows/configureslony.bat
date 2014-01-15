@ECHO OFF
REM Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

REM Copying the lib files to pkglibdir
move %1\lib\slony1_funcs*.dll @@PKG_LIBDIR@@
move %1\lib\slevent.dll @@PKG_LIBDIR@@

REM Creating file removal scripts to run at the time of uninstallation
REM Remove these files installed in the lib directory 
echo @ECHO OFF > %1/Slony/installer/Slony/removeFiles.bat
echo "cd @@PKG_LIBDIR@@ && del /S /Q slevent.dll slony1_funcs*.dll" >> %1/Slony/installer/Slony/removeFiles.bat
echo "cd @@SHARE_DIR@@ && FOR /F %%%%A IN ('dir /b slony1_*.*sql') DO (del /S /Q %%%%A)" >> %1/Slony/installer/Slony/removeFiles.bat

cd %1\share\Slony && move * @@SHARE_DIR@@ && cd %1\share && rd /S /Q Slony

