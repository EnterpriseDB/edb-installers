@echo off
REM Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.

rem Go to the directory from where it has been called

rem Install the server

SET PYTHONHOME="@@LP_PYTHON_HOME@@"
SET PYTHONPATH="@@LP_PYTHON_HOME@@"
SET PATH="@@LP_PYTHON_HOME@@";%PATH%

"@@APACHE_HOME@@\bin\httpd.exe" -k install -n "EnterpriseDB ApachePHP"

