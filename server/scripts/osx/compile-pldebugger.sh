#!/bin/bash
# Build the pldebugger extension against the staged PostgreSQL.
#
# Usage: compile-pldebugger.sh <pldebugger_directory>
# PG_STAGING and PG_ARCH_OSX_CFLAGS come from the environment.

set -xe

PLDEBUGGER_DIR="$1"

if [ -z "$PLDEBUGGER_DIR" ]; then
    echo "Usage: $0 <pldebugger_directory>"
    exit 1
fi

cd "$PLDEBUGGER_DIR"
PATH="$PG_STAGING/bin:$PATH" make USE_PGXS=1 CFLAGS="$PG_ARCH_OSX_CFLAGS"
PATH="$PG_STAGING/bin:$PATH" make install USE_PGXS=1
cp README-pldebugger.md "$PG_STAGING/doc/" 2>/dev/null || true
