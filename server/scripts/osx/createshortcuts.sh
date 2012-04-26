#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL shortcut creation script for OSX

# Check the command line
if [ $# -ne 9 ]; 
then
echo "Usage: $0 <Major.Minor version> <OSUsername> <SuperUsername> <Port> <Branding> <Install dir> <Data dir> <DisableStackBuilder> <ServiceName>"
    exit 127
fi

VERSION=$1
OSUSERNAME=$2
USERNAME=$3
PORT=$4
BRANDING=$5
INSTALLDIR=$6
DATADIR=$7
DISABLE_STACKBUILDER=$8
SERVICENAME=$9

# Exit code
WARN=0

# Make sure correct value is passed for DISABLE_STACKBUILDER
DISABLE_STACKBUILDER=`echo $DISABLE_STACKBUILDER | tr '[A-Z]' '[a-z]'`
if [ "x$DISABLE_STACKBUILDER" = "x1" -o "x$DISABLE_STACKBUILDER" = "xtrue" -o "x$DISABLE_STACKBUILDER" = "xon" ];
then
    DISABLE_STACKBUILDER=1
else
    DISABLE_STACKBUILDER=0
fi

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
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace PG_MAJOR_VERSION $VERSION $1
    _replace PG_USERNAME $USERNAME $1
    _replace PG_OSUSERNAME $OSUSERNAME $1
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
    _replace PG_OSUSERNAME $OSUSERNAME $1
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

# Do not create stack-builder shortcut, if DISABLE_STACKBUILDER is equal to 1
if [ $DISABLE_STACKBUILDER -eq 0 ]; then
    _compile_script "$INSTALLDIR/scripts/stackbuilder.applescript" "$FOLDER/Application Stack Builder.app" "$INSTALLDIR/scripts/images/pg-stackbuilder.icns"
fi

echo "$0 ran to completion"
exit 0
