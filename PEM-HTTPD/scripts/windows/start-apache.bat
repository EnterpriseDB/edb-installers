@echo off
REM Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.


REM SET PYTHONHOME="@@LP_PYTHON_HOME@@"
REM SET PYTHONPATH="@@LP_PYTHON_HOME@@"
REM SET PATH="@@LP_PYTHON_HOME@@";%PATH%
SET PATH="@@APACHE_HOME@@\bin";%PATH%

"@@APACHE_HOME@@\bin\httpd.exe" -k start -n "PEMHTTPD"

