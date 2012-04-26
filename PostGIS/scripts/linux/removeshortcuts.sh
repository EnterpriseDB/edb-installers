#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 4 ];
then
    echo "Usage: $0 <Install dir> <PostGIS_Version> <PG Version> <Branding>" 
    exit 127
fi

INSTALLDIR=$1
POSTGIS_VERSION=$2
PG_VERSION=$3
BRANDING=$4

# Version string, for the xdg filenames
POSTGIS_VERSION_STR=`echo $POSTGIS_VERSION | sed 's/\./_/g'`
PG_VERSION_STR=`echo $PG_VERSION | sed 's/\./_/g'`

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
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
        mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
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
# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/PostGIS/scripts/xdg/pg-$BRANDING_STR.directory"
    rm "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory" 
fi
xdg_dir_name=menus

xdg_system_dirs="$XDG_CONFIG_DIRS"
[ -n "$xdg_system_dirs" ] || xdg_system_dirs=/etc/xdg
xdg_global_dir=
for x in `echo $xdg_system_dirs | sed 's/:/ /g'` ; do
   if [ -w $x/$xdg_dir_name ] ; then
       xdg_global_dir="$x/$xdg_dir_name"
       break
   fi
done
xdg_global_dir="$xdg_global_dir/applications-merged"

# Hack up the XDG menu files to make sure everything really does go.
_replace "<Filename>pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-postgis-$POSTGIS_VERSION_STR.menu"
_replace "<Filename>pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-postgis-$POSTGIS_VERSION_STR.menu"

echo "$0 ran to completion"
exit 0

