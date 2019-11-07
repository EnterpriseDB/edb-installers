#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=9.4.24
PG_TARBALL_PGADMIN=1.20.0
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=1.0.2s
PG_TARBALL_ZLIB=1.2.8
PG_TARBALL_GEOS=3.4.2

# Build nums
PG_BUILDNUM_POSTGIS=6
PG_BUILDNUM_SLONY=2
PG_BUILDNUM_NPGSQL=2
PG_BUILDNUM_PGAGENT=1
PG_BUILDNUM_PGMEMCACHE=3
PG_BUILDNUM_MIGRATIONTOOLKIT=1
PG_BUILDNUM_REPLICATIONSERVER=2
PG_BUILDNUM_SQLPROTECT=3
PG_BUILDNUM_LANGUAGEPACK=5

# Tags for source checkout
PG_TAG_REPLICATIONSERVER=''
PG_TAG_MIGRATIONTOOLKIT=''

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=9.4
PG_MINOR_VERSION=24.3

# Other package versions
PG_VERSION_APACHE=2.4.25
PG_VERSION_POSTGIS=2.1.8
PG_VERSION_PGJDBC=9.4.1208
PG_VERSION_SLONY=2.2.6
PG_VERSION_PGAGENT=3.4.0
PG_VERSION_PGMEMCACHE=2.2.0
PG_VERSION_PGBOUNCER=1.5.4
PG_VERSION_MIGRATIONTOOLKIT=48.0.0
PG_VERSION_REPLICATIONSERVER=5.0
PG_VERSION_SQLPROTECT=$PG_TARBALL_POSTGRESQL

PG_VERSION_PERL=5.16
PG_MINOR_VERSION_PERL=3
PG_VERSION_PYTHON=3.3
PG_MINOR_VERSION_PYTHON=4
PG_VERSION_TCL=8.5
PG_MINOR_VERSION_TCL=17
PG_VERSION_LANGUAGEPACK=$PG_MAJOR_VERSION

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=$PG_VERSION_PGJDBC.jdbc41
BASE_URL=http://sbp.enterprisedb.com
JRE_VERSIONS_LIST="$PG_MAJOR_VERSION;9.1;9.0"
