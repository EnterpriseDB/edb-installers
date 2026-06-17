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
cp system_stats--*.sql system_stats.control "$PG_STAGING/share/postgresql/extension/"
cp system_stats.dylib "$PG_STAGING/lib/postgresql/"
