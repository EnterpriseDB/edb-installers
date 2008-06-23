#!/bin/sh

# PostgreSQL shortcut creation script for OSX
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Port> <Install dir> <Data dir>"
    exit 127
fi

VERSION=$1
USERNAME=$2
PORT=$3
INSTALLDIR=$4
DATADIR=$5

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
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
	mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
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
FOLDER="/Applications/PostgreSQL $VERSION"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/help.applescript" "$FOLDER/Online Documentation.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/psql.applescript" "$FOLDER/SQL Shell (psql).app" "$INSTALLDIR/scripts/images/pg-psql.icns"
_compile_script "$INSTALLDIR/scripts/reload.applescript" "$FOLDER/Reload Configuration.app" "$INSTALLDIR/scripts/images/pg-reload.icns"
_compile_script "$INSTALLDIR/scripts/restart.applescript" "$FOLDER/Restart Server.app" "$INSTALLDIR/scripts/images/pg-restart.icns"
_compile_script "$INSTALLDIR/scripts/start.applescript" "$FOLDER/Start Server.app" "$INSTALLDIR/scripts/images/pg-start.icns"
_compile_script "$INSTALLDIR/scripts/stop.applescript" "$FOLDER/Stop Server.app" "$INSTALLDIR/scripts/images/pg-stop.icns"
_compile_script "$INSTALLDIR/scripts/website.applescript" "$FOLDER/PostgreSQL Website.app" "$INSTALLDIR/scripts/images/pg-website.icns"
_compile_script "$INSTALLDIR/scripts/pgadmin.applescript" "$FOLDER/pgAdmin III.app" "$INSTALLDIR/pgAdmin3.app/Contents/Resources/pgAdmin3.icns"

echo "$0 ran to completion"
exit 0
