#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=8.3.18
PG_TARBALL_PGADMIN=1.8.4
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=0.9.8i
PG_TARBALL_ZLIB=1.2.3
PG_TARBALL_GEOS=3.1.1
PG_TARBALL_PROJ=4.6.1

# Build nums
PG_BUILDNUM_POSTGIS=1
PG_BUILDNUM_SLONY=1


# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build. 

PG_MAJOR_VERSION=8.3
PG_MINOR_VERSION=18.2

# Other package versions
PG_VERSION_POSTGIS=1.3.6
PG_VERSION_SLONY=1.2.22

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=8.3-604.jdbc2
PG_VERSION_PGJDBC=8.3-604
