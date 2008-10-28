#!/bin/sh

# Check the command line
if [ $# -ne 3 ]; 
then
    echo "Usage: $0 <Install dir> <PG_MAJOR_VERSION> <PG_VERSION_POSTGIS>"
    exit 127
fi

INSTALLDIR="$1"
VERSION=$2
PG_VERSION_POSTGIS=$3

# Version string, for the xdg filenames
PG_VERSION_STR=`echo $VERSION | sed 's/\./_/g'`
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

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" "$3" > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp "$3" || _die "Failed to move /tmp/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    _replace PG_MAJOR_VERSION "$VERSION" "$1"
}

# Create the icon resources
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-postgresql.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-postgis.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISDocs.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISJDBCDocs.png"

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/PostGIS/installer/PostGIS/"*.sh
_fixup_file "$INSTALLDIR/PostGIS/scripts/launchPostGISDocs.sh"
_fixup_file "$INSTALLDIR/PostGIS/scripts/launchJDBCDocs.sh"

chmod ugo+x "$INSTALLDIR/PostGIS/scripts/launchPostGISDocs.sh"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/launchJDBCDocs.sh"

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory"

chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory"

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/PostGIS/installer/xdg/xdg-desktop-menu" install --mode system \
         "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory" \
         "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory" \
    "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop" \
    "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop"  || _warn "Failed to create the PostGIS menu"

echo "$0 ran to completion"
exit 0
