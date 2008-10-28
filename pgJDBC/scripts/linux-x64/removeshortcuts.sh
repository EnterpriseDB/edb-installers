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
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
        "$INSTALLDIR/scripts/xdg/pg-launchpgJDBC.desktop"  || _warn "Failed to Remove the pgJDBC menu"
      
# Remove the icon resources
echo "$0 ran to completion"
exit 0

