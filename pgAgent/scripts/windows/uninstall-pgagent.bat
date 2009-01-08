@echo off
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.

SET INSTALL_DIR="%1"

rem Uninstall the pgAGent service
"%INSTALL_DIR%\bin\pgagent.exe" REMOVE pgagent

