#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir> "
    exit 127
fi

INSTALLDIR="$1"

# Exit code
WARN=0

# Working directory
WD=`pwd`

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
    sed -e "s^$1^$2^g" "$3" > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp "$3" || _die "Failed to move /tmp/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
}

# Create the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-postgres.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-apachephp.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-launchApachePhp.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-startApache.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-stopApache.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-restartApache.png"

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/installer/ApachePhp/"*.sh
_fixup_file "$INSTALLDIR/scripts/launchApachePhp.sh"
chmod ugo+x "$INSTALLDIR/scripts/launchApachePhp.sh"

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pg-launchApachePhp.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-startApache.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-stopApache.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-restartApache.desktop"

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system \
         "$INSTALLDIR/scripts/xdg/pg-postgres.directory" \
         "$INSTALLDIR/scripts/xdg/pg-apachephp.directory" \
    "$INSTALLDIR/scripts/xdg/pg-launchApachePhp.desktop" \
    "$INSTALLDIR/scripts/xdg/pg-startApache.desktop" \
    "$INSTALLDIR/scripts/xdg/pg-stopApache.desktop" \
    "$INSTALLDIR/scripts/xdg/pg-restartApache.desktop"  || _warn "Failed to create the ApachePhp menu"

echo "$0 ran to completion"
exit 0
