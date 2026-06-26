#!/bin/bash
#
# Assemble the macOS InstallBuilder staging tree from the universal binaries
# already built into ./pgsql by the GitHub Actions workflow.

set -e

S=packaging-config/installer/server/staging/osx
PGSERVER=$S/server
CLT=$S/commandlinetools
SB=$S/stackbuilder
RES=packaging-config/server/resources
OSX_SCRIPTS=packaging-config/server/scripts/osx

mkdir -p "$PGSERVER" "$CLT/bin" "$CLT/lib" "$CLT/share/man/man1" "$SB"

# ---------------------------------------------------------------------------
# Server component: the full built tree lives under ./pgsql (dependency dylibs
# and system_stats already bundled into pgsql/lib by the workflow).
# ---------------------------------------------------------------------------
cp -pR pgsql/bin     "$PGSERVER/"
cp -pR pgsql/lib     "$PGSERVER/"
cp -pR pgsql/include "$PGSERVER/"
cp -pR pgsql/share   "$PGSERVER/"
[ -d pgsql/doc ] && cp -pR pgsql/doc "$PGSERVER/" || mkdir -p "$PGSERVER/doc"

cp packaging-config/resources/license.txt "$PGSERVER/server_license.txt"
cp "$RES/installation-notes.html" "$PGSERVER/doc/"
cp "$RES/edblogo.png"             "$PGSERVER/doc/"

# ---------------------------------------------------------------------------
# Command Line Tools: the shared lib dir and the client binaries are moved out
# of the server component into commandlinetools (matches build-osx.sh layout;
# both components install into the same prefix so binaries still resolve their
# dylibs via @loader_path/../lib).
# ---------------------------------------------------------------------------
mv "$PGSERVER/lib"/* "$CLT/lib/"
rmdir "$PGSERVER/lib" 2>/dev/null || true

CLT_BINS="psql pg_basebackup pg_dump pg_dumpall pg_restore createdb clusterdb \
          createuser dropuser dropdb pg_isready vacuumdb reindexdb pgbench vacuumlo"
for b in $CLT_BINS; do
  for f in "$PGSERVER/bin/$b"*; do
    [ -e "$f" ] && mv "$f" "$CLT/bin/"
  done
done
for m in $CLT_BINS; do
  [ -e "$PGSERVER/share/man/man1/$m.1" ] && mv "$PGSERVER/share/man/man1/$m.1" "$CLT/share/man/man1/" || true
done

# ---------------------------------------------------------------------------
# Server installer scripts
# ---------------------------------------------------------------------------
mkdir -p "$PGSERVER/installer/server"
if [ -f "$OSX_SCRIPTS/getlocales/getlocales.osx" ]; then
  cp "$OSX_SCRIPTS/getlocales/getlocales.osx" "$PGSERVER/installer/server/getlocales"
  chmod ugo+x "$PGSERVER/installer/server/getlocales"
else
  echo "WARNING: getlocales.osx not found - compile it before staging (cc -arch x86_64 -arch arm64 ... getlocales.c)"
fi
cp "$OSX_SCRIPTS/prerun_checks.sh"        "$PGSERVER/installer/prerun_checks.sh"
cp "$OSX_SCRIPTS/createuser.sh"           "$PGSERVER/installer/server/createuser.sh"
cp "$OSX_SCRIPTS/initcluster.sh"          "$PGSERVER/installer/server/initcluster.sh"
cp "$OSX_SCRIPTS/createshortcuts.sh"      "$PGSERVER/installer/server/createshortcuts.sh"
cp "$OSX_SCRIPTS/createshortcuts_server.sh" "$PGSERVER/installer/server/createshortcuts_server.sh"
cp "$OSX_SCRIPTS/loadmodules.sh"          "$PGSERVER/installer/server/loadmodules.sh"
cp "$OSX_SCRIPTS/install-pgadmin.sh"      "$PGSERVER/installer/server/install-pgadmin.sh"
cp "$OSX_SCRIPTS/set-service-tcl-env.sh"  "$PGSERVER/installer/server/set-service-tcl-env.sh"
chmod ugo+x "$PGSERVER/installer/prerun_checks.sh" "$PGSERVER/installer/server/"*.sh

# Server menu-pick scripts (applescripts) and icons
mkdir -p "$PGSERVER/scripts/images"
cp "$RES/pg-help.icns"   "$PGSERVER/scripts/images/"
cp "$RES/pg-reload.icns" "$PGSERVER/scripts/images/"
for a in doc-installationnotes doc-postgresql doc-postgresql-releasenotes doc-pgadmin \
         psql reload pgadmin stackbuilder; do
  cp "$OSX_SCRIPTS/$a.applescript.in" "$PGSERVER/scripts/$a.applescript"
done

# ---------------------------------------------------------------------------
# Command Line Tools installer scripts / launch scripts
# ---------------------------------------------------------------------------
mkdir -p "$CLT/installer/server" "$CLT/scripts/images"
cp "$OSX_SCRIPTS/createshortcuts_clt.sh" "$CLT/installer/server/createshortcuts_clt.sh"
cp "$OSX_SCRIPTS/runpsql.sh"             "$CLT/scripts/runpsql.sh"
cp "$RES/pg-psql.icns"                   "$CLT/scripts/images/"
chmod ugo+x "$CLT/installer/server/createshortcuts_clt.sh" "$CLT/scripts/runpsql.sh"

# ---------------------------------------------------------------------------
# StackBuilder: DISABLED on this branch. The stackbuilder.app bundle is not
# built/fetched in CI yet, and the stackbuilder component is commented out of
# installer.xml.in, so we do not stage it. The empty "$SB" directory is still
# created above so license.sh's StackBuilder pushd does not fail.
# ---------------------------------------------------------------------------
# mkdir -p "$SB/installer/server" "$SB/scripts/images"
# cp "$OSX_SCRIPTS/createshortcuts_sb.sh" "$SB/installer/server/createshortcuts_sb.sh"
# cp "$RES/pg-stackbuilder.icns"          "$SB/scripts/images/"
# chmod ugo+x "$SB/installer/server/createshortcuts_sb.sh"
# if [ -d stackbuilder.app ]; then
#   cp -pR stackbuilder.app "$SB/stackbuilder.app"
# elif [ -d SB/stackbuilder.app ]; then
#   cp -pR SB/stackbuilder.app "$SB/stackbuilder.app"
# else
#   echo "WARNING: stackbuilder.app not found - stackbuilder component will be incomplete"
# fi

# ---------------------------------------------------------------------------
# Installer-level assets: side/splash images, i18n language files and the
# shared include scripts referenced from installer.xml.
# ---------------------------------------------------------------------------
mkdir -p "$S/resources" "$S/scripts"
cp packaging-config/resources/pg-side.png   "$S/resources/"
cp packaging-config/resources/pg-splash.png "$S/resources/"
cp -r packaging-config/server/i18n "$S/"
cp packaging-config/scripts/determineLinuxInitSystem.xml "$S/scripts/"
cp packaging-config/scripts/linuxServiceAction.xml       "$S/scripts/"

# ---------------------------------------------------------------------------
# InstallBuilder project files (templated by the workflow's Pre-installer step)
# ---------------------------------------------------------------------------
cp packaging-config/server/installer.xml.in        "$S/installer.xml"
cp packaging-config/server/pgserver.xml.in         "$S/pgserver-osx.xml"
cp packaging-config/server/commandlinetools.xml.in "$S/commandlinetools-osx.xml"

# StackBuilder is not built/fetched for macOS yet, but installer.xml includes
# stackbuilder-<platform>.xml and the project references the 'stackbuilder'
# component throughout. Emit a hidden, unselected, empty stub component for osx
# only so the include resolves and nothing is installed/launched. (Windows/Linux
# keep the real stackbuilder.xml.in via their own staging, so this stays
# safe to merge into REL_*.) Replace with the real component once StackBuilder
# is built for macOS.
cat > "$S/stackbuilder-osx.xml" <<'EOF'
<component>
    <name>stackbuilder</name>
    <description>Stack Builder</description>
    <canBeEdited>0</canBeEdited>
    <selected>0</selected>
    <show>0</show>
</component>
EOF

echo "--- staging/osx contents ---"
ls -la "$S"
