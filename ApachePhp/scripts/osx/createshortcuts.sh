#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir> "
    exit 127
fi

INSTALLDIR=$1

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

# Substitute values into a file ($in)
_fixup_file() {

    _replace INSTALL_DIR $INSTALLDIR $1

}

# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/enterprisedb-launchApachePhp.applescript"
_fixup_file "$INSTALLDIR/scripts/enterprisedb-startApache.applescript" 
_fixup_file "$INSTALLDIR/scripts/enterprisedb-stopApache.applescript"
_fixup_file "$INSTALLDIR/scripts/enterprisedb-restartApache.applescript" 



# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    osacompile -x -o "$2" "$1" 
	cp "$3" "$2/Contents/Resources/applet.icns"
}

# Create the menu 
FOLDER="/Applications/PostgreSQL"
mkdir -p "$FOLDER" 
mkdir -p "$FOLDER/EnterpriseDB ApachePhp" || _die "Failed to create the menu directory ($FOLDER/EnterpriseDB ApachePhp)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/enterprisedb-launchApachePhp.applescript" "$FOLDER/EnterpriseDB ApachePhp/ApachePhp.app" "$INSTALLDIR/scripts/images/enterprisedb-launchApachePhp.icns"
_compile_script "$INSTALLDIR/scripts/enterprisedb-startApache.applescript" "$FOLDER/EnterpriseDB ApachePhp/Start Apache.app" "$INSTALLDIR/scripts/images/enterprisedb-startApache.icns"
_compile_script "$INSTALLDIR/scripts/enterprisedb-stopApache.applescript" "$FOLDER/EnterpriseDB ApachePhp/Stop Apache.app" "$INSTALLDIR/scripts/images/enterprisedb-stopApache.icns"
_compile_script "$INSTALLDIR/scripts/enterprisedb-restartApache.applescript" "$FOLDER/EnterpriseDB ApachePhp/Restart Apache.app" "$INSTALLDIR/scripts/images/enterprisedb-restartApache.icns"

echo "$0 ran to completion"
exit 0
