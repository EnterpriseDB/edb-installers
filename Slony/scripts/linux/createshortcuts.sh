#!/bin/sh
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <Install dir> <PG Version> <Slony Version> <Branding> <Temp dir>"
    exit 127
fi

INSTALLDIR="$1"
PG_VERSION=$2
SLONY_VERSION=$3
BRANDING=$4
TEMPDIR=$5

# Version string, for the xdg filenames
PG_VERSION_STR=`echo $PG_VERSION | sed 's/\./_/g'`
SLONY_VERSION_STR=`echo $SLONY_VERSION | cut -f1,2 -d "." | sed 's/\./_/g'`

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
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    _replace PG_MAJOR_VERSION "$PG_VERSION" "$1"
	_replace PG_BRANDING "$BRANDING" "$1"
}

# Create the icon resources
"$INSTALLDIR/Slony/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/Slony/scripts/images/pg-postgresql.png"
"$INSTALLDIR/Slony/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/Slony/scripts/images/pg-launchSlonyDocs.png"

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/Slony/installer/Slony/"*.sh
_fixup_file "$INSTALLDIR/Slony/scripts/launchSlonyDocs.sh"

chmod ugo+x "$INSTALLDIR/Slony/scripts/launchSlonyDocs.sh"

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/Slony/scripts/xdg/pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/Slony/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/Slony/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory" "$INSTALLDIR/Slony/scripts/xdg/pg-$BRANDING_STR.directory"
fi

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/Slony/installer/xdg/xdg-desktop-menu" install --mode system  \
    "$INSTALLDIR/Slony/scripts/xdg/pg-$BRANDING_STR.directory" \
    "$INSTALLDIR/Slony/scripts/xdg/pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop"  || _warn "Failed to create the Slony menu"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0
