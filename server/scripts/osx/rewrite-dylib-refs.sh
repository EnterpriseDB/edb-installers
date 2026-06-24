#!/bin/bash
#
# Make a built PostgreSQL tree relocatable on macOS (counterpart of the legacy
# build-osx.sh _rewrite_so_refs function). Run AFTER the build, BEFORE staging.
#
# PostgreSQL bakes the build-time $libdir into libpq's install id and into every
# binary/module that links it, so at the final install location the absolute
# build paths don't exist and dyld fails with e.g.:
#   dyld: Library not loaded: /Users/runner/.../pgsql/lib/libpq.5.dylib
#
# For each Mach-O file this:
#   - adds an LC_RPATH back to the install lib dir (@loader_path-relative),
#   - sets a dylib/bundle's own id to @rpath/<name>,
#   - rewrites absolute build-path dependencies to @rpath/<name>.
#
# It does NOT sign anything. install_name_tool invalidates code signatures, so
# the caller MUST (ad-hoc) re-sign the binaries in a separate step afterwards -
# on Apple Silicon an invalid signature makes the binary fail to launch.
#
# Usage: rewrite-dylib-refs.sh <prefix> [extra_build_lib_dir ...]
#   <prefix>            install prefix to process (e.g. ./pgsql)
#   extra_build_lib_dir additional build-time lib dirs whose refs must be
#                       rewritten (e.g. the dependency prefix's lib dir)

set -e

PREFIX="${1:?usage: rewrite-dylib-refs.sh <prefix> [extra_build_lib_dir ...]}"
shift || true

# Build lib dirs whose absolute references should become @rpath. $PREFIX/lib is
# always included; pass the dependency prefix lib dir(s) as extra arguments.
BUILD_LIB_DIRS="$PREFIX/lib $*"

_reloc() {
    f="$1"; rpath="$2"
    [ -L "$f" ] && return 0
    file "$f" | grep -qE "Mach-O" || return 0

    # 1. rpath back to the install lib dir (skip if already present).
    # No '|| true' here: if there isn't enough Mach-O header padding to add the
    # rpath, fail the build loudly rather than silently shipping a binary that
    # can't find its libraries at runtime. If this ever triggers, add
    # -Wl,-headerpad_max_install_names to the build LDFLAGS in compile.sh.
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
