#!/bin/bash
#
# Assemble the macOS InstallBuilder staging tree for PostGIS around the
# binaries already staged in $STAGE by the GitHub Actions workflow.

set -e

PK=packaging-config/PostGIS

mkdir -p "$STAGE/installer/PostGIS" "$STAGE/scripts/images" "$STAGE/i18n" "$STAGE/resources"

cp "$PK/scripts/osx/createshortcuts.sh" "$STAGE/installer/PostGIS/createshortcuts.sh"
chmod ugo+x "$STAGE/installer/PostGIS/createshortcuts.sh"

cp -p "$PK/scripts/osx/pg-launchPostGISDocs.applescript.in" "$STAGE/scripts/pg-launchPostGISDocs.applescript"
cp -p "$PK/resources/pg-launchPostGISDocs.icns" "$STAGE/scripts/images/"

cp "$PK/i18n/en.lng" "$STAGE/i18n/"
cp packaging-config/resources/pg-side.png "$STAGE/resources/"

# InstallBuilder project file (templated by the workflow's Pre-installer step)
cp "$PK/installer.xml.in" "$STAGE/installer.xml"

chmod -R ugo+rX "$STAGE"
