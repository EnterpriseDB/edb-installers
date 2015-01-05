@ECHO OFF
REM Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved
IF "%1" == "CHECK_CONNECTION" %2 -l %3 || exit -1
IF "%1" == "CHECK_PGAGENT_SCHEMA" %2 -t -c "SELECT has_schema_privilege('pgagent', 'USAGE')" || exit -1
IF "%1" == "CHECK_PLPGSQL" %2 -t -c "SELECT lanname FROM pg_language WHERE lanname='plpgsql'" || exit -1
IF "%1" == "CREATE_PLPGSQL" %2 -t -c "CREATE LANGUAGE plpgsql" || exit -1
IF "%1" == "CREATE_PGAGENT_SCHEMA" %2 -t -f %3 || exit -1
IF "%1" == "UPGRADE_PGAGENT_SCHEMA" %2 -t -f %3 || exit -1
IF "%1" == "CHECK_PGAGENT_SCHEMA_VERSION_FUNCTION_EXIST" %2 -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname = 'pgagent_schema_version' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgagent') AND prorettype = (SELECT oid FROM pg_type WHERE typname = 'int2') AND proargtypes = ''" || exit -1
IF "%1" == "CHECK_CURRENT_PGAGENT_SCHEMA_VERSION" %2 -t -c "SELECT pgagent.pgagent_schema_version()" || exit -1
IF "%1" == "CREATE_PGPASS_CONF" %2 %3 %4 %5 %6 %7 %8 %9 || exit -1
