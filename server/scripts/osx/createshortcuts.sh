#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL shortcut creation script for OSX

# Check the command line
if [ $# -ne 7 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Port> <Branding> <Install dir> <Data dir> <Temp dir>"
    exit 127
fi

VERSION=$1
USERNAME=$2
PORT=$3
BRANDING=$4
INSTALLDIR=$5
DATADIR=$6
TEMPDIR=$7

# Exit code
WARN=0

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "$TEMPDIR/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv $TEMPDIR/$$.tmp $3 || _die "Failed to move $TEMPDIR/$$.tmp to $3"
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace PG_MAJOR_VERSION $VERSION $1
    _replace PG_USERNAME $USERNAME $1
    _replace PG_PORT $PORT $1
    _replace PG_INSTALLDIR $INSTALLDIR $1
    _replace PG_DATADIR $DATADIR $1
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
	cp "$3" "$2/Contents/Resources/applet.icns"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace PG_MAJOR_VERSION $VERSION $1
    _replace PG_USERNAME $USERNAME $1
    _replace PG_PORT $PORT $1
    _replace PG_INSTALLDIR $INSTALLDIR $1
    _replace PG_DATADIR $DATADIR $1
}

# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/runpsql.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Create the menu 
FOLDER="/Applications/$BRANDING"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"
mkdir -p "$FOLDER/Documentation" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/doc-installationnotes.applescript" "$FOLDER/Documentation/Installation notes.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/doc-postgresql.applescript" "$FOLDER/Documentation/PostgreSQL documentation.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/doc-postgresql-releasenotes.applescript" "$FOLDER/Documentation/PostgreSQL release notes.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/doc-pgadmin.applescript" "$FOLDER/Documentation/pgAdmin documentation.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/doc-pljava.applescript" "$FOLDER/Documentation/PL Java users guide.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/doc-pljava-readme.applescript" "$FOLDER/Documentation/PL Java README.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/psql.applescript" "$FOLDER/SQL Shell (psql).app" "$INSTALLDIR/scripts/images/pg-psql.icns"
_compile_script "$INSTALLDIR/scripts/reload.applescript" "$FOLDER/Reload Configuration.app" "$INSTALLDIR/scripts/images/pg-reload.icns"
_compile_script "$INSTALLDIR/scripts/restart.applescript" "$FOLDER/Restart Server.app" "$INSTALLDIR/scripts/images/pg-restart.icns"
_compile_script "$INSTALLDIR/scripts/start.applescript" "$FOLDER/Start Server.app" "$INSTALLDIR/scripts/images/pg-start.icns"
_compile_script "$INSTALLDIR/scripts/stop.applescript" "$FOLDER/Stop Server.app" "$INSTALLDIR/scripts/images/pg-stop.icns"
_compile_script "$INSTALLDIR/scripts/pgadmin.applescript" "$FOLDER/pgAdmin III.app" "$INSTALLDIR/pgAdmin3.app/Contents/Resources/pgAdmin3.icns"
_compile_script "$INSTALLDIR/scripts/stackbuilder.applescript" "$FOLDER/Application Stack Builder.app" "$INSTALLDIR/scripts/images/pg-stackbuilder.icns"

# Not entirely relevant to this script, but pre-cofigure pgAdmin while we're here
# Pre-register the server with pgAdmin, if the user doesn't already have a pgAdmin preferences file
PGADMIN_CONF="$HOME/Library/Preferences/pgadmin3 Preferences"
if [ ! -e "$PGADMIN_CONF" ];
then
cat <<EOT > "$PGADMIN_CONF"
PostgreSQLPath=$INSTALLDIR/bin
PostgreSQLHelpPath=file://$INSTALLDIR/doc/postgresql/html
[Servers]
Count=1
[Servers/1]
Server=localhost
Description=PostgreSQL $VERSION
Port=$PORT
Database=postgres
Username=postgres
EOT
fi

echo "$0 ran to completion"
exit 0
