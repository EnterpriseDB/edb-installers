#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 6 ]; 
then
    echo "Usage: $0 <Install dir> <PG Version> <PostGIS Version> <Branding> <Docdir> <Temp dir>" 
    exit 127
fi

INSTALLDIR=$1
PG_VERSION=$2
POSTGIS_VERSION=$3
BRANDING=$4
DOCDIR=$5
TEMPDIR=$6

# Version string, for the xdg filenames
PG_VERSION_STR=`echo $PG_VERSION | sed 's/\./_/g'`
POSTGIS_VERSION_STR=`echo $POSTGIS_VERSION | sed 's/\./_/g'`

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgreSQL $PG_VERSION" ];
then
    BRANDING_STR="postgresql-$PG_VERSION_STR"
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
	BRANDED=1
fi


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
    sed -e "s^$1^$2^g" "$3" > "$TEMPDIR/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv $TEMPDIR/$$.tmp "$3" || _die "Failed to move $TEMPDIR/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace DOC_DIR "$DOCDIR" "$1"
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    _replace PG_MAJOR_VERSION "$PG_VERSION" "$1"
    _replace PG_BRANDING "$BRANDING" "$1"
    _replace PG_VERSION_STR "$PG_VERSION_STR" "$1"
    _replace POSTGIS_VERSION_STR "$POSTGIS_VERSION_STR" "$1"
}

# Create the icon resources
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-postgresql-$PG_VERSION_STR.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-postgis-$POSTGIS_VERSION_STR-$PG_VERSION_STR.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.png"
"$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/PostGIS/scripts/images/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.png"

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/PostGIS/installer/PostGIS/"*.sh
_fixup_file "$INSTALLDIR/PostGIS/scripts/launchPostGISDocs.sh"
_fixup_file "$INSTALLDIR/PostGIS/scripts/launchJDBCDocs.sh"

chmod ugo+x "$INSTALLDIR/PostGIS/scripts/launchPostGISDocs.sh"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/launchJDBCDocs.sh"

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR-$PG_VERSION_STR.directory"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory"

chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR-$PG_VERSION_STR.directory"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory" "$INSTALLDIR/PostGIS/scripts/xdg/pg-$BRANDING_STR.directory"
fi


# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/PostGIS/installer/xdg/xdg-desktop-menu" install --mode system \
         "$INSTALLDIR/PostGIS/scripts/xdg/pg-$BRANDING_STR.directory" \
         "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR-$PG_VERSION_STR.directory" \
	 "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop" \
    "$INSTALLDIR/PostGIS/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop" \

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0
