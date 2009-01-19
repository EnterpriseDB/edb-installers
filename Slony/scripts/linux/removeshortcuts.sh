#!/bin/sh

# Check the command line
if [ $# -ne 4 ];
then
    echo "Usage: $0 <Install dir> <Slony_Version> <PG Version> <Branding>"
    exit 127
fi

INSTALLDIR="$1"
SLONY_VERSION=$2
PG_VERSION=$3
BRANDING=$4

# Version string, for the xdg filenames
SLONY_VERSION_STR=`echo $SLONY_VERSION | cut -f1,2 -d "." | sed 's/\./_/g'`
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

# Remove the menu shortcuts
"$INSTALLDIR/Slony/installer/xdg/xdg-desktop-menu" uninstall --mode system   \
    "$INSTALLDIR/Slony/scripts/xdg/pg-$BRANDING_STR.directory" \
    "$INSTALLDIR/Slony/scripts/xdg/pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop" || _warn "Failed to remove the Slony docs menu item"
      
# Remove the icon resources
"$INSTALLDIR/Slony/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/Slony/scripts/images/launch-SlonyDocs.png"

# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
fi

echo "$0 ran to completion"
exit 0

