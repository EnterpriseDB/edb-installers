#!/bin/sh

# PostgreSQL server shortcut removal script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Install dir> <Branding>"
    exit 127
fi

INSTALLDIR=$1
BRANDING=$2

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgreSQL" ];
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
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
      "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
      "$INSTALLDIR/scripts/xdg/pg-launchOdbcDocs.desktop"  || _warn "Failed to Remove the pgODBC menu"
      
# Remove the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/launch-OdbcDocs.png"

# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
fi

echo "$0 ran to completion"
exit 0

