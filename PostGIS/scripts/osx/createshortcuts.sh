#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir> "
    exit 127
fi

INSTALLDIR=$1
FOLDER="/Applications/PostgreSQL/PostGIS"

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
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" 
    cp /tmp/$$.tmp $3 
    cat /tmp/$$.tmp >> /tmp/tmp1.txt
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
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
_compile_script "$INSTALLDIR/PostGIS/scripts/enterprisedb-launchJdbcDocs.applescript" "$FOLDER/PostgreSQL JDBC Home Page.app" "$INSTALLDIR/PostGIS/scripts/images/enterprisedb-launchJdbcDocs.icns"
_compile_script "$INSTALLDIR/PostGIS/scripts/enterprisedb-launchPostGISDocs.applescript" "$FOLDER/PostGIS Docs.app" "$INSTALLDIR/PostGIS/scripts/images/enterprisedb-launchPostGISDocs.icns"

echo "$0 ran to completion"
exit 0
