#!/bin/sh

# Check the command line
if [ $# -ne 2 ];
then
    echo "Usage: $0 <Install dir> <PG_VERSION_POSTGIS>"
    exit 127
fi

INSTALLDIR="$1"
PG_VERSION_POSTGIS=$2

# Version string, for the xdg filenames
POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | sed 's/\./_/g'`

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
    "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory" \
    "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop" \
    "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop" || _warn "Failed to remove the PostGIS menu"

      
# Remove the icon resources
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-postgis.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISDocs.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISJDBCDocs.png"
echo "$0 ran to completion"
exit 0

