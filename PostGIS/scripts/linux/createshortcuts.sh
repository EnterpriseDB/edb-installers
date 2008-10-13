#!/bin/sh

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Install dir> <PG_MAJOR_VERSION>"
    exit 127
fi

INSTALLDIR="$1"
VERSION=$2

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
cd "$INSTALLDIR/PostGIS/scripts/images"
for i in `ls *.png`
do
    "$INSTALLDIR/PostGIS/installer/xdg/xdg-icon-resource" install --size 32 --novendor $i
done

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/PostGIS/installer/PostGIS/"*.sh
_fixup_file "$INSTALLDIR/PostGIS/scripts/launchPostGISDocs.sh"
_fixup_file "$INSTALLDIR/PostGIS/scripts/launchJDBCDocs.sh"

chmod ugo+x "$INSTALLDIR/PostGIS/scripts/launchPostGISDocs.sh"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/launchJDBCDocs.sh"

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchPostGISDocs.desktop"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchJDBCDocs.desktop"
_fixup_file "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$VERSION.directory"

chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchPostGISDocs.desktop"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchJDBCDocs.desktop"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-postgis.directory"
chmod ugo+x "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$VERSION.directory"

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/PostGIS/installer/xdg/xdg-desktop-menu" install --mode system \
         "$INSTALLDIR/PostGIS/scripts/xdg/pg-postgresql-$VERSION.directory" \
         "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-postgis.directory" \
    "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchPostGISDocs.desktop" \
    "$INSTALLDIR/PostGIS/scripts/xdg/enterprisedb-launchJDBCDocs.desktop"  || _warn "Failed to create the PostGIS menu"

echo "$0 ran to completion"
exit 0
