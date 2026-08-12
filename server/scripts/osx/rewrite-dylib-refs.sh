#!/bin/bash
set -e

PREFIX="${1:?usage: rewrite-dylib-refs.sh <prefix> [extra_build_lib_dir ...]}"
shift || true

EXTRA_BUILD_LIB_DIRS="$*"
BUILD_LIB_DIRS="$PREFIX/lib $EXTRA_BUILD_LIB_DIRS"

_reloc() {
    f="$1"; rpath="$2"
    [ -L "$f" ] && return 0
    file "$f" | grep -qE "Mach-O" || return 0
    # Universal static archives (.a) report as "Mach-O universal binary ...
    # [x86_64:current ar archive]" - install_name_tool can't touch them, skip.
    file "$f" | grep -qi "archive" && return 0

    if ! otool -l "$f" | grep -A2 LC_RPATH | grep -q "path $rpath "; then
        install_name_tool -add_rpath "$rpath" "$f"
    fi

    # Drop any stale absolute rpath pointing at an ephemeral build-time
    # dependency dir (e.g. $DEP_PREFIX/lib on the CI runner, passed in as an
    # extra_build_lib_dir arg). It's dead weight now that the relative
    # @loader_path rpath above is in place - dyld just skips it since it
    # never resolves on any other machine - but leaving it means shipped
    # binaries carry a dangling reference to a path that only ever existed
    # on the build runner.
    for bp in $EXTRA_BUILD_LIB_DIRS; do
        if otool -l "$f" | grep -A2 LC_RPATH | grep -q "path $bp "; then
            install_name_tool -delete_rpath "$bp" "$f" || true
        fi
    done

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

# Relocate Mach-O executables nested anywhere under lib/ (e.g. the pgxs test
# binaries pg_regress/isolationtester) that the fixed-depth globs above miss.
# The rpath is computed per file from its nesting depth so @rpath resolves
# back to $PREFIX/lib.
find "$PREFIX/lib" -type f ! -name '*.dylib' ! -name '*.so' ! -name '*.a' 2>/dev/null | while read -r f; do
    file "$f" | grep -qE "Mach-O" || continue
    dir=$(dirname "${f#"$PREFIX"/lib/}")
    up="@loader_path"
    if [ "$dir" != "." ]; then
        n=$(awk -F/ '{print NF}' <<<"$dir")
        i=0; while [ "$i" -lt "$n" ]; do up="$up/.."; i=$((i+1)); done
    fi
    _reloc "$f" "$up"
done

echo "dylib reference rewrite complete for $PREFIX"
