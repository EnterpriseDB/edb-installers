#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 6 ]; 
then
    echo "Usage: $0 <Install dir> <PG Version> <Slony Version> <Branding> <Docdir> <Temp dir>" 
    exit 127
fi

INSTALLDIR=$1
PG_VERSION=$2
SLONY_VERSION=$3
BRANDING=$4
DOCDIR=$5
TEMPDIR=$6

FOLDER="/Applications/$BRANDING/PostGIS"

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
    sed -e "s^$1^$2^g" $3 > "$TEMPDIR/$$.tmp" 
    mv $TEMPDIR/$$.tmp $3 
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace DOC_DIR "$DOCDIR" "$1"
    osacompile -x -o "$2" "$1" 
    cp "$3" "$2/Contents/Resources/applet.icns"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR $INSTALLDIR $1
}

# Create the menu 
mkdir -p "$FOLDER" 

# Create the scripts
_compile_script "$INSTALLDIR/PostGIS/scripts/pg-launchJdbcDocs.applescript" "$FOLDER/JDBC Docs.app" "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISJDBCDocs.icns"
_compile_script "$INSTALLDIR/PostGIS/scripts/pg-launchPostGISDocs.applescript" "$FOLDER/PostGIS Docs.app" "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISDocs.icns"

echo "$0 ran to completion"
exit 0
