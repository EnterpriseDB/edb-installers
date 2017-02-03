@ECHO OFF
REM Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved
"@@PHP_PATH@@\php.exe" -r "echo addcslashes('@@PATH@@', '\\');"
