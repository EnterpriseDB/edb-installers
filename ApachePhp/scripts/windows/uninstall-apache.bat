@echo off
REM Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.


"@@APACHE_HOME@@\bin\httpd.exe" -k stop -n "EnterpriseDB ApachePHP"
"@@APACHE_HOME@@\bin\httpd.exe" -k uninstall -n "EnterpriseDB ApachePHP"

