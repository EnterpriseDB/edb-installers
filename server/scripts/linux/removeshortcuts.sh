#!/bin/sh

# PostgreSQL server shortcut removal script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 3 ]; 
then
    echo "Usage: $0 <Install dir> <Version> <Branding>"
    exit 127
fi

INSTALLDIR=$1
VERSION=$2
BRANDING=$3

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
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
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

# Remove the menu shortcuts
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system --noupdate \
	  "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-documentation-$VERSION_STR.directory" \
          "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION_STR.desktop" || _warn "Failed to remove the documentation menu"

"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
	  "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-restart-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-start-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-stop-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-pgadmin-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-stackbuilder-$VERSION_STR.desktop" || _warn "Failed to remove the top level menu"
	  
# Remove the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
	"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 $i
done

# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
fi

echo "$0 ran to completion"
exit 0
