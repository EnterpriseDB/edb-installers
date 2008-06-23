#!/bin/sh

# PostgreSQL server shortcut removal script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir>"
    exit 127
fi

INSTALLDIR=$1

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

# Remove the menu shortcuts - just the server menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
	  "$INSTALLDIR/scripts/xdg/pg-postgresql.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-help.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-psql.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-reload.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-restart.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-start.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-stop.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-website.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-pgadmin.desktop" || _warn "Failed to recreate the top level menu"
	  
# Remove the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
	"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 $i
done

echo "$0 ran to completion"
exit 0
