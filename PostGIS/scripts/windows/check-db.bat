@ECHO OFF
REM Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

SET PGHOST=%1

SET PGPORT=%2

SET PGUSER=%3

SET PGPASSWORD=%4

SET PGHOME="%5"

"%PGHOME%\bin\psql.exe" -l | findstr %6


