#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# StackBuilderPlus shortcut creation script for OSX

if [ $# -ne 1 ];
then
    echo "Usage: $0 <TEMP_DIR>"
    exit 127
fi

TEMP_DIR=$1

# Check the command line
BRANDING="@@BRANDING@@"
INSTALLDIR=@@INSTALL_DIR@@

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
    sed -e "s^$1^$2^g" $3 > "$TEMP_DIR/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv $TEMP_DIR/$$.tmp $3 || _die "Failed to move $TEMP_DIR/$$.tmp to $3"
}

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace INSTALL_DIR $INSTALLDIR $1
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
	cp "$3" "$2/Contents/Resources/applet.icns"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    chmod ugo+x "$1"
}

_fixup_file "$INSTALLDIR/scripts/launchStackBuilderPlus.sh"

chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Create the menu 
FOLDER="/Applications/$BRANDING"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/stackbuilderplus.applescript" "$FOLDER/StackBuilder Plus.app" "$INSTALLDIR/scripts/images/edb-stackbuilderplus.icns"

echo "$0 ran to completion"
exit 0
