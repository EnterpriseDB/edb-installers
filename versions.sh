#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=15.6
PG_TARBALL_PGADMIN=8.5
PG_LP_VERSION=3.4

# Build nums
PG_BUILDNUM_PGJDBC=1
PG_BUILDNUM_PSQLODBC=1
PG_BUILDNUM_POSTGIS=1
PG_BUILDNUM_NPGSQL=1
PG_BUILDNUM_PGAGENT=1
PG_BUILDNUM_PGBOUNCER=1
PG_BUILDNUM_SQLPROTECT=1
PG_BUILDNUM_LANGUAGEPACK=1

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=15
PG_MINOR_VERSION=6.2

# Other package versions
PG_VERSION_PGJDBC=42.7.2
PG_VERSION_PSQLODBC=15.00.0000
PG_VERSION_POSTGIS=3.3.1
PG_VERSION_POSTGIS_JAVA=2.1.7.2
PG_VERSION_NPGSQL=3.2.6
PG_VERSION_PGAGENT=4.2.2
PG_VERSION_PGBOUNCER=1.22.0
PG_VERSION_SQLPROTECT=$PG_TARBALL_POSTGRESQL
PG_VERSION_PGADMIN=$PG_TARBALL_PGADMIN
PG_VERSION_SB=4.1.0
PG_LP_VERSION=3.3

PG_VERSION_PERL=5.36
PG_MINOR_VERSION_PERL=3
PG_VERSION_PERL_WINDOWS64=5.36
PG_MINOR_VERSION_PERL_WINDOWS64=3
PG_VERSION_PYTHON=3.10
PG_MINOR_VERSION_PYTHON=14
PG_VERSION_TCL=8.6
PG_MINOR_VERSION_TCL=14
PG_VERSION_NCURSES=6.0
PG_VERSION_LANGUAGEPACK=$PG_LP_VERSION
PG_VERSION_PYTHON_SETUPTOOLS=69.5.1

VCREDIST_VERSION=14.15.26706

# This is required TCL and Tk Compiling for external tools.
# As this come from source code, we need to use it from the vcproj file
PG_PYTHON_TCL_TK=8.6.9.0
PG_PYTHON_TIX=8.4.3

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=$PG_VERSION_PGJDBC.jdbc41
BASE_URL=http://sbp.enterprisedb.com
JRE_VERSIONS_LIST="$PG_MAJOR_VERSION;9.1;9.0"
