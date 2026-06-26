#!/bin/bash
# Usage: compile-tcl.sh <tcl_src_dir> <dep_prefix>
set -e

TCL_SRC="${1:?usage: compile-tcl.sh <tcl_src_dir> <dep_prefix>}"
DEP_PREFIX="${2:?usage: compile-tcl.sh <tcl_src_dir> <dep_prefix>}"

mkdir -p "$DEP_PREFIX"
cp -a "$TCL_SRC"/. "$DEP_PREFIX"/

for cfg in "$DEP_PREFIX"/lib/tclConfig.sh "$DEP_PREFIX"/lib/tkConfig.sh; do
    [ -f "$cfg" ] && sed -i '' "s|@@TCL_PREFIX@@|$DEP_PREFIX|g" "$cfg"
done

[ -f "$DEP_PREFIX/lib/tclConfig.sh" ] || { echo "FATAL: tclConfig.sh not found in prebuilt Tcl"; exit 1; }

echo "TCL_CONFIG_DIR=$DEP_PREFIX/lib" >> "${GITHUB_ENV:-/dev/null}"
echo "staged Tcl: TCL_CONFIG_DIR=$DEP_PREFIX/lib"
