#!/bin/sh

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

# Remove the menu shortcuts
"$INSTALLDIR/phpPgAdmin/installer/xdg/xdg-desktop-menu" uninstall --mode system  \
    "$INSTALLDIR/phpPgAdmin/scripts/xdg/enterprisedb-launchPhpPgAdmin.desktop"  || _warn "Failed to remove the phpPgAdmin menu"
      
# Remove the icon resources
"$INSTALLDIR/phpPgAdmin/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32  \
    "$INSTALLDIR/phpPgAdmin/scripts/images/enterprisedb-launchPhpPgAdmin.png" || _warn "Failed to remove icon resource"

echo "$0 ran to completion"
exit 0

