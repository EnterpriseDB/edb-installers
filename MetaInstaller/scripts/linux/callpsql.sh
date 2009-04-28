#!/bin/bash

export PGPASSWORD=$3

if [ "$4" = "CHECK_PGAGENT_SCHEMA" ]; then
 $1/bin/psql -U $2 -d postgres -t -c "SELECT has_schema_privilege('pgagent', 'USAGE')"
fi

if [ "$4" = "CHECK_PLPGSQL" ]; then
 $1/bin/psql -U $2 -d postgres -t -c "SELECT lanname FROM pg_language WHERE lanname='plpgsql'"
fi

if [ "$4" = "CREATE_PLPGSQL" ]; then
 $1/bin/psql -U $2 -d postgres -t -c "CREATE LANGUAGE plpgsql"
fi

if [ "$4" = "CHECK_PGAGENT_SCHEMA_VERSION_FUNCTION_EXIST" ]; then
 $1/bin/psql -U $2 -d postgres -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname = 'pgagent_schema_version' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgagent') AND prorettype = (SELECT oid FROM pg_type WHERE typname = 'int2') AND proargtypes = ''"
fi

if [ "$4" = "CHECK_CURRENT_PGAGENT_SCHEMA_VERSION" ]; then
 $1/bin/psql -U $2 -d postgres -t -c "SELECT pgagent.pgagent_schema_version()"
fi
