@ECHO OFF
SET PGPASSWORD=%3
IF "%4" == "CHECK_PGAGENT_SCHEMA" %1\bin\psql.exe -U %2 -d postgres -t -c "SELECT has_schema_privilege('pgagent', 'USAGE')" || exit -1
IF "%4" == "CHECK_PLPGSQL" %1\bin\psql.exe -U %2 -d postgres -t -c "SELECT lanname FROM pg_language WHERE lanname='plpgsql'" || exit -1
IF "%4" == "CREATE_PLPGSQL" %1\bin\psql.exe -U %2 -d postgres -t -c "CREATE LANGUAGE plpgsql" || exit -1
IF "%4" == "CHECK_PGAGENT_SCHEMA_VERSION_FUNCTION_EXIST" %1\bin\psql.exe -U %2 -d postgres -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname = 'pgagent_schema_version' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgagent') AND prorettype = (SELECT oid FROM pg_type WHERE typname = 'int2') AND proargtypes = ''" || exit -1
IF "%4" == "CHECK_CURRENT_PGAGENT_SCHEMA_VERSION" %1\bin\psql.exe -U %2 -d postgres -t -c "SELECT pgagent.pgagent_schema_version()" || exit -1

