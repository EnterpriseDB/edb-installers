#!/bin/bash
# Build the system_stats extension against the staged PostgreSQL.
#
# Usage: compile-system_stats.sh <system_stats_directory>
# PG_STAGING and PG_ARCH_OSX_CFLAGS come from the environment.

set -xe

SYSTEM_STATS_DIR="$1"

if [ -z "$SYSTEM_STATS_DIR" ]; then
    echo "Usage: $0 <system_stats_directory>"
    exit 1
fi

cd "$SYSTEM_STATS_DIR"
PATH="$PG_STAGING/bin:$PATH" make USE_PGXS=1 CFLAGS="$PG_ARCH_OSX_CFLAGS"
PATH="$PG_STAGING/bin:$PATH" make install USE_PGXS=1
# Use pg_config for the authoritative install paths. For a source build whose
# prefix already contains "pgsql"/"postgres", PostgreSQL does NOT append the
# "/postgresql" suffix, so these resolve to $PG_STAGING/share/extension and
# $PG_STAGING/lib (not the .../postgresql/ subdirectories).
cp system_stats--*.sql system_stats.control "$("$PG_STAGING/bin/pg_config" --sharedir)/extension/"
cp system_stats.dylib "$("$PG_STAGING/bin/pg_config" --pkglibdir)/"
