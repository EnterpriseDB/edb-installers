#!/bin/bash
# For each Mach-O file this:
#   - adds an LC_RPATH back to the install lib dir (@loader_path-relative),
#   - sets a dylib/bundle's own id to @rpath/<name>,
#   - rewrites absolute build-path dependencies to @rpath/<name>.
#
# Usage: rewrite-dylib-refs.sh <prefix> [extra_build_lib_dir ...]
#   <prefix>            install prefix to process (e.g. ./pgsql)
#   extra_build_lib_dir additional build-time lib dirs whose refs must be
#                       rewritten (e.g. the dependency prefix's lib dir)

set -e

PREFIX="${1:?usage: rewrite-dylib-refs.sh <prefix> [extra_build_lib_dir ...]}"
shift || true

BUILD_LIB_DIRS="$PREFIX/lib $*"

_reloc() {
    f="$1"; rpath="$2"
    [ -L "$f" ] && return 0
    file "$f" | grep -qE "Mach-O" || return 0

    if ! otool -l "$f" | grep -A2 LC_RPATH | grep -q "path $rpath "; then
        install_name_tool -add_rpath "$rpath" "$f"
    fi

    # 2. normalise a dylib/bundle's own install id
    if file "$f" | grep -qE "shared library|bundle"; then
        install_name_tool -id "@rpath/$(basename "$f")" "$f" || true
    fi

    # 3. rewrite absolute build-path dependencies -> @rpath/<name>
    otool -L "$f" | awk 'NR>1{print $1}' | while read -r dep; do
        for bp in $BUILD_LIB_DIRS; do
            case "$dep" in
                "$bp"/*)
                    install_name_tool -change "$dep" "@rpath/$(basename "$dep")" "$f" || true
                    break
                    ;;
            esac
        done
    done
}

for f in "$PREFIX"/bin/*;       do _reloc "$f" "@loader_path/../lib"; done
for f in "$PREFIX"/lib/*.dylib; do _reloc "$f" "@loader_path";        done
for f in "$PREFIX"/lib/postgresql/*.so "$PREFIX"/lib/postgresql/*.dylib; do
    [ -e "$f" ] && _reloc "$f" "@loader_path/.."
done

echo "dylib reference rewrite complete for $PREFIX"
