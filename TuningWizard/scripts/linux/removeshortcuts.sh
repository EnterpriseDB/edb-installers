#!/bin/sh

# PostgreSQL server shortcut removal script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir>"
    exit 127
fi

INSTALLDIR="$1"

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
    "$INSTALLDIR/scripts/xdg/pg-launchTuningWizard.desktop" || _warn "Failed to remove the TuningWizard menu"

      
# Remove the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/pg-launchTuningWizard.png"
echo "$0 ran to completion"
exit 0

