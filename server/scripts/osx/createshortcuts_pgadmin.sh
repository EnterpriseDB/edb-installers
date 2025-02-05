#!/bin/sh
# Copyright (c) 2012-2025, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL shortcut creation script for OSX

# Check the command line
if [ $# -ne 4 ]; 
then
echo "Usage: $0 <Major.Minor version> <Branding> <Install dir> <Temp dir>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3
TEMPDIR=$4

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
    _replace PG_INSTALLDIR $INSTALLDIR $1
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
	cp "$3" "$2/Contents/Resources/applet.icns"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace PG_MAJOR_VERSION $VERSION $1
    _replace PG_INSTALLDIR $INSTALLDIR $1
}

# Fixup the scripts
#_fixup_file "$INSTALLDIR/scripts/runpsql.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Create the menu 
FOLDER="/Applications/$BRANDING"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"
mkdir -p "$FOLDER/Documentation" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
#_compile_script "$INSTALLDIR/scripts/doc-installationnotes.applescript" "$FOLDER/Documentation/Installation notes.app" "$INSTALLDIR/scripts/images/pg-help.icns"
#_compile_script "$INSTALLDIR/scripts/doc-postgresql.applescript" "$FOLDER/Documentation/PostgreSQL documentation.app" "$INSTALLDIR/scripts/images/pg-help.icns"
#_compile_script "$INSTALLDIR/scripts/doc-postgresql-releasenotes.applescript" "$FOLDER/Documentation/PostgreSQL release notes.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/doc-pgadmin.applescript" "$FOLDER/Documentation/pgAdmin documentation.app" "$INSTALLDIR/scripts/images/pg-help.icns"
_compile_script "$INSTALLDIR/scripts/pgadmin.applescript" "$FOLDER/pgAdmin 4.app" "$INSTALLDIR/pgAdmin 4.app/Contents/Resources/app.icns"

echo "$0 ran to completion"
exit 0
