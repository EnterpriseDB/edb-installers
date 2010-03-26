#!/bin/sh

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Install dir> <Branding>"
    exit 127
fi

INSTALLDIR=$1
BRANDING=$2
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

# Substitute values into a file ($in)
_fixup_file() {

    _replace INSTALL_DIR $INSTALLDIR $1

}

# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/pg-launchApachePhp.applescript"
_fixup_file "$INSTALLDIR/scripts/pg-startApache.applescript" 
_fixup_file "$INSTALLDIR/scripts/pg-stopApache.applescript"
_fixup_file "$INSTALLDIR/scripts/pg-restartApache.applescript" 



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
_compile_script "$INSTALLDIR/scripts/pg-startApache.applescript" "$FOLDER/EnterpriseDB ApachePhp/Start Apache.app" "$INSTALLDIR/scripts/images/pg-startApache.icns"
_compile_script "$INSTALLDIR/scripts/pg-stopApache.applescript" "$FOLDER/EnterpriseDB ApachePhp/Stop Apache.app" "$INSTALLDIR/scripts/images/pg-stopApache.icns"
_compile_script "$INSTALLDIR/scripts/pg-restartApache.applescript" "$FOLDER/EnterpriseDB ApachePhp/Restart Apache.app" "$INSTALLDIR/scripts/images/pg-restartApache.icns"

echo "$0 ran to completion"
exit 0
