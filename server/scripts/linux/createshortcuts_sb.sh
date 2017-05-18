#!/bin/sh
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server shortcut creation script for Linux

# Check the command line
if [ $# -ne 4 ];
then
    echo "Usage: $0 <Major.Minor version> <Branding> <Install dir> <Temp dir>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3
TEMPDIR=$4

# Exit code
WARN=0

# Working directory
WD=`pwd`

# Version string, for the xdg filenames
VERSION_STR=`echo $VERSION | sed 's/\./_/g'`

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgreSQL $VERSION" ];
then
    BRANDING_STR="postgresql-$VERSION_STR"
    DOC_BRANDING_STR="documentation-$VERSION_STR"
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
    DOC_BRANDING_STR=$BRANDING_STR"_documentation"
    BRANDED=1
fi

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
    sed -e "s^$1^$2^g" $3 > "$TEMPDIR/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
	mv $TEMPDIR/$$.tmp $3 || _die "Failed to move $TEMPDIR/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace PG_VERSION_STR $VERSION_STR $1
    _replace PG_MAJOR_VERSION $VERSION $1
    _replace PG_INSTALLDIR "$INSTALLDIR" $1
    _replace PG_BRANDING "$BRANDING" $1
}

# We need to remove any old shortcuts created by the Beta/RC installers, as they 
# used a version numbering scheme that could confuse XDG

if [ "x$VERSION_STR" = "x$VERSION" ];
then
    VERSION=""
    DevServer=1
fi

if [ -f "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory" ];
then
   "$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
          "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory" \
          "$INSTALLDIR/scripts/xdg/pg-stackbuilder-$VERSION_STR.desktop"
fi

if [ "x$DevServer" = "x1" ];
then
    VERSION=$VERSION_STR
fi


# Create the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
	"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 $i
done

# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/launchstackbuilder.sh"
_fixup_file "$INSTALLDIR/scripts/runstackbuilder.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pg-stackbuilder-$VERSION_STR.desktop"

"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
  "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
    "$INSTALLDIR/scripts/xdg/pg-stackbuilder-$VERSION_STR.desktop" || _warn "Failed to create the top level menu for stack-builder"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   find /usr/share/applications -iname \*${LANG}\*cache | while read filename; do
      /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > $filename
   done
fi

echo "$0 ran to completion"
exit 0
