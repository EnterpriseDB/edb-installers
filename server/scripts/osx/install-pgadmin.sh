#!/bin/sh
# Copyright (c) 2012-2026, EnterpriseDB Corporation.  All rights reserved

# Downloads the latest community pgAdmin 4 (arch-matched) and installs it to /Applications.
# Usage: install-pgadmin.sh download | install <dir> | (no args = full flow)

PGADMIN_FTP_BASE="https://ftp.postgresql.org/pub/pgadmin/pgadmin4"
PGADMIN_LISTING_URL="https://www.postgresql.org/ftp/pgadmin/pgadmin4/"

detect_arch() {
    if [ "$(uname -m)" = "arm64" ]; then
        echo "arm64"
    else
        echo "x64"
    fi
}

latest_version() {
    curl -sS "$PGADMIN_LISTING_URL" \
        | grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' \
        | sed 's/^v//' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -1
}

# Read an app bundle's version label (CFBundleShortVersionString). $1 = path to
# the .app. Prints nothing if the bundle or its Info.plist is absent.
read_plist_version() {
    plist="$1/Contents/Info.plist"
    [ -f "$plist" ] || return 0
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null
}

# Print the pgAdmin 4 version currently installed on this machine (empty = none).
# A community install in /Applications wins; otherwise fall back to the newest
# bundled app left under /Library/PostgreSQL by an older (<=18) PostgreSQL.
do_installed_version() {
    V=$(read_plist_version "/Applications/pgAdmin 4.app")
    if [ -n "$V" ]; then
        printf '%s' "$V"
        return 0
    fi

    best=""
    for app in /Library/PostgreSQL/*/"pgAdmin 4.app"; do
        [ -d "$app" ] || continue
        v=$(read_plist_version "$app")
        [ -z "$v" ] && continue
        if [ -z "$best" ]; then
            best="$v"
        else
            best=$(printf '%s\n%s\n' "$best" "$v" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
        fi
    done
    printf '%s' "$best"
    return 0
}

# Download into a private 0700 temp dir; print only the dir path on stdout (logs to stderr).
# $1 = version to fetch; if empty, resolve it from the FTP listing ourselves.
do_download() {
    VER="$1"
    DIR=$(mktemp -d -t pgadmin4) || { echo "ERROR: failed to create temp directory." >&2; return 1; }
    chmod 700 "$DIR"

    ARCH=$(detect_arch)
    echo "Detected architecture: $(uname -m) (using pgAdmin ${ARCH} build)" >&2

    # Resolve the version once: prefer the one the installer already computed and
    # passed in; only query the FTP listing here if nothing was supplied.
    if [ -z "$VER" ]; then
        VER=$(latest_version)
    fi
    if [ -z "$VER" ]; then
        echo "ERROR: Unable to determine the latest pgAdmin 4 version." >&2
        rm -rf "$DIR"
        return 1
    fi
    echo "pgAdmin 4 version to install: ${VER}" >&2

    DMG_NAME="pgadmin4-${VER}-${ARCH}.dmg"
    DMG_URL="${PGADMIN_FTP_BASE}/v${VER}/macos/${DMG_NAME}"
    echo "Downloading ${DMG_URL}" >&2
    if ! curl -fL "$DMG_URL" -o "${DIR}/${DMG_NAME}" >&2; then
        echo "ERROR: Failed to download pgAdmin 4 from ${DMG_URL}" >&2
        rm -rf "$DIR"
        return 1
    fi

    printf '%s' "$DIR"
    return 0
}

# Mount the DMG in $1, copy the app to /Applications, unmount, remove the dir
do_install() {
    DIR="$1"
    if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
        echo "ERROR: invalid work directory: ${DIR}" >&2
        return 1
    fi

    DMG_PATH=$(ls "$DIR"/*.dmg 2>/dev/null | head -1)
    if [ -z "$DMG_PATH" ] || [ ! -f "$DMG_PATH" ]; then
        echo "ERROR: No pgAdmin DMG found in ${DIR}." >&2
        rm -rf "$DIR"
        return 1
    fi

    # Clean up the mount and temp dir on interruption (set before mounting).
    MOUNT_DIR=""
    trap 'hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null; rm -rf "$DIR"' INT TERM

    MOUNT_DIR=$(hdiutil attach "$DMG_PATH" -nobrowse 2>/dev/null | grep -o '/Volumes/.*' | head -1)
    if [ -z "$MOUNT_DIR" ]; then
        echo "ERROR: Failed to mount pgAdmin 4 disk image (${DMG_PATH})." >&2
        rm -rf "$DIR"
        return 1
    fi

    # Verify the expected app bundle is present before touching /Applications.
    SRC_APP="$MOUNT_DIR/pgAdmin 4.app"
    if [ ! -d "$SRC_APP" ]; then
        echo "ERROR: 'pgAdmin 4.app' not found in mounted volume (${MOUNT_DIR})." >&2
        hdiutil detach "$MOUNT_DIR" -quiet
        rm -rf "$DIR"
        return 1
    fi

    # Stage the copy first; only touch /Applications once it succeeds,
    # so a failed copy never leaves the user with a broken pgAdmin.
    STAGE_APP="/Applications/.pgAdmin 4.app.new"
    rm -rf "$STAGE_APP"
    cp -R "$SRC_APP" "$STAGE_APP"
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
        # Overlay onto any existing install with cp instead of deleting it first
        cp -R "$STAGE_APP/" "/Applications/pgAdmin 4.app"
        STATUS=$?
    fi
    rm -rf "$STAGE_APP"

    hdiutil detach "$MOUNT_DIR" -quiet
    rm -rf "$DIR"

    if [ $STATUS -ne 0 ]; then
        echo "ERROR: Failed to copy pgAdmin 4 to /Applications (check permissions)." >&2
        return 1
    fi
    echo "pgAdmin 4 installed successfully." >&2
    return 0
}

case "$1" in
    download)
        do_download "$2"
        exit $?
        ;;
    install)
        do_install "$2"
        exit $?
        ;;
    installed-version)
        do_installed_version
        exit 0
        ;;
    latest-version)
        latest_version
        exit 0
        ;;
    *)
        DIR=$(do_download) || exit 1
        do_install "$DIR"
        exit $?
        ;;
esac
