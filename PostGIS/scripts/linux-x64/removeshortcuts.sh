#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir>"
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

# Remove the menu shortcuts
"$INSTALLDIR/PostGIS/installer/xdg/xdg-desktop-menu" uninstall --mode system \
    "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-postgis.directory" \
    "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchPostGISDocs.desktop" \
    "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchJDBCDocs.desktop" || _warn "Failed to remove the PostGIS menu"

      
# Remove the icon resources
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/PostGIS/scripts/images/enterprisedb-postgis.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/PostGIS/scripts/images/launch-PostGISDocs.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/PostGIS/scripts/images/launch-JDBCDocs.png"
echo "$0 ran to completion"
exit 0

