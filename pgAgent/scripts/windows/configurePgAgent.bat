@ECHO OFF
IF "%1" == "CHECK_CONNECTION" %2 -l
IF "%1" == "CHECK_PGAGENT_SCHEMA" %2 -t -c "SELECT has_schema_privilege('pgagent', 'USAGE')"
IF "%1" == "CHECK_PLPGSQL" %2 -t -c "SELECT lanname FROM pg_language WHERE lanname='plpgsql'"
IF "%1" == "CREATE_PLPGSQL" %2 -t -c "CREATE LANGUAGE plpgsql"
IF "%1" == "CREATE_PGAGENT_SCHEMA" %2 -t -f %3
