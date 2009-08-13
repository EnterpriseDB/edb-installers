#!/bin/sh

# StackBuilderPlus shortcut creation script for OSX
# Ashesh Vashi, EnterpriseDB

# Check the command line
PG_VERSION=@@PG_VERSION@@
BRANDING=@@BRANDING@@
INSTALLDIR=@@INSTALL_DIR@@

PG_VERSION_STR=`echo $PG_VERSION | sed 's/\./_/g'`

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
    _replace INSTALL_DIR $INSTALLDIR $1
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
	cp "$3" "$2/Contents/Resources/applet.icns"
}

chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Create the menu 
FOLDER="/Applications/$BRANDING"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/stackbuilderplus.applescript" "$FOLDER/Application Stack Builder Plus - PG_$PG_VERSION_STR.app" "$INSTALLDIR/scripts/images/edb-stackbuilderplus.icns"

echo "$0 ran to completion"
exit 0
