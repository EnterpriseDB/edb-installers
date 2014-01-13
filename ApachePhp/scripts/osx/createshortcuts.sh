#!/bin/sh
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 3 ]; 
then
    echo "Usage: $0 <Install dir> <Branding> <Temp dir>"
    exit 127
fi

INSTALLDIR=$1
BRANDING=$2
TEMPDIR=$3
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
    sed -e "s^$1^$2^g" $3 > "$TEMPDIR/$$.tmp" 
    mv $TEMPDIR/$$.tmp $3 
}

# Substitute values into a file ($in)
_fixup_file() {

    _replace INSTALL_DIR $INSTALLDIR $1

}

# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/pg-launchApachePhp.applescript"



# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    osacompile -x -o "$2" "$1" 
	cp "$3" "$2/Contents/Resources/applet.icns"
}

# Create the menu 
mkdir -p "$FOLDER/EnterpriseDB ApachePhp" || _die "Failed to create the menu directory ($FOLDER/EnterpriseDB ApachePhp)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/pg-launchApachePhp.applescript" "$FOLDER/EnterpriseDB ApachePhp/ApachePhp.app" "$INSTALLDIR/scripts/images/pg-launchApachePhp.icns"

echo "$0 ran to completion"
exit 0
