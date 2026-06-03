#!/bin/sh
# Copyright (c) 2012-2026, EnterpriseDB Corporation.  All rights reserved

# Downloads the latest community pgAdmin 4 (arch-matched) and installs it to /Applications.
# Usage: install-pgadmin.sh download | install <dir> | (no args = full flow)

PGADMIN_FTP_BASE="https://ftp.postgresql.org/pub/pgadmin/pgadmin4"
PGADMIN_LISTING_URL="https://www.postgresql.org/ftp/pgadmin/pgadmin4/"

detect_arch() {
    if [ "`uname -m`" = "arm64" ]; then
        echo "arm64"
    else
        echo "x64"
    fi
}

latest_version() {
    curl -s "$PGADMIN_LISTING_URL" \
        | grep -oE 'v[0-9]+\.[0-9]+' \
        | sed 's/^v//' \
        | sort -t. -k1,1n -k2,2n \
        | tail -1
}

# Download into a private 0700 temp dir; print only the dir path on stdout (logs to stderr)
do_download() {
    DIR=`mktemp -d -t pgadmin4` || { echo "ERROR: failed to create temp directory." >&2; return 1; }
    chmod 700 "$DIR"

    ARCH=`detect_arch`
    echo "Detected architecture: `uname -m` (using pgAdmin ${ARCH} build)" >&2

    VER=`latest_version`
    if [ -z "$VER" ]; then
        echo "ERROR: Unable to determine the latest pgAdmin 4 version." >&2
        rm -rf "$DIR"
        return 1
    fi
    echo "Latest pgAdmin 4 version: ${VER}" >&2

    DMG_NAME="pgadmin4-${VER}-${ARCH}.dmg"
    DMG_URL="${PGADMIN_FTP_BASE}/v${VER}/macos/${DMG_NAME}"
    echo "Downloading ${DMG_URL}" >&2
    if ! curl -L "$DMG_URL" -o "${DIR}/${DMG_NAME}" >&2; then
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

    DMG_PATH=`ls "$DIR"/*.dmg 2>/dev/null | head -1`
    if [ -z "$DMG_PATH" ] || [ ! -f "$DMG_PATH" ]; then
        echo "ERROR: No pgAdmin DMG found in ${DIR}." >&2
        rm -rf "$DIR"
        return 1
    fi

    MOUNT_DIR=`hdiutil attach "$DMG_PATH" -nobrowse -noverify 2>/dev/null | grep -o '/Volumes/.*' | head -1`
    if [ -z "$MOUNT_DIR" ]; then
        echo "ERROR: Failed to mount pgAdmin 4 disk image (${DMG_PATH})." >&2
        rm -rf "$DIR"
        return 1
    fi

    rm -rf "/Applications/pgAdmin 4.app"
    cp -R "$MOUNT_DIR/pgAdmin 4.app" /Applications/
    STATUS=$?

    hdiutil detach "$MOUNT_DIR" -quiet
    rm -rf "$DIR"

    if [ $STATUS -ne 0 ]; then
        echo "ERROR: Failed to copy pgAdmin 4 to /Applications." >&2
        return 1
    fi
    echo "pgAdmin 4 installed successfully." >&2
    return 0
}

case "$1" in
    download)
        do_download
        exit $?
        ;;
    install)
        do_install "$2"
        exit $?
        ;;
    *)
        DIR=`do_download` || exit 1
        do_install "$DIR"
        exit $?
        ;;
esac
