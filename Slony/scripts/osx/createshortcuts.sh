#!/bin/sh

# Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <Install dir> <PG Version> <Slony Version> <Branding>"
    exit 127
fi

INSTALLDIR=$1/Slony
PG_VERSION=$2
SLONY_VERSION=$3
BRANDING=$4

FOLDER="/Applications/$BRANDING"

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
    mv /tmp/$$.tmp $3 
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    osacompile -x -o "$2" "$1" 
    cp "$3" "$2/Contents/Resources/applet.icns"
}

# Create the menu 
mkdir -p "$FOLDER" 

# Create the scripts
_compile_script "$INSTALLDIR/scripts/pg-launchSlonyDocs.applescript" "$FOLDER/Slony Documentation.app" "$INSTALLDIR/scripts/images/pg-launchSlonyDocs.icns"

echo "$0 ran to completion"
exit 0
