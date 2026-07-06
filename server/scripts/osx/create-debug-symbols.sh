#!/bin/bash
# Extract .dSYM debug symbols from every Mach-O in the staging tree into a
# separate symbols dir, then strip the shipped binaries. Mirrors legacy
# create_debug_symbols.sh. Run after build, before signing (strip breaks sigs).
#
# Usage: create-debug-symbols.sh <staging_dir> <symbols_out_dir>
set -e

STAGING="${1:?usage: create-debug-symbols.sh <staging_dir> <symbols_out_dir>}"
OUT="${2:?usage: create-debug-symbols.sh <staging_dir> <symbols_out_dir>}"

mkdir -p "$OUT"
cd "$STAGING"
find . -type f ! -type l | while read -r f; do
    file "$f" | grep -q "Mach-O" || continue
    mkdir -p "$OUT/$(dirname "$f")"
    dsymutil "$f" -o "$OUT/${f}.dSYM" 2>/dev/null || true
    strip -S "$f" 2>/dev/null || true
done
echo "debug symbols written to $OUT"
echo "---Printing the output of pgbuild end.."
ls -la "$STAGING/lib"
