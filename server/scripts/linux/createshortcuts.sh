#!/bin/sh

# PostgreSQL server shortcut creation script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Port> <Install dir> <Data dir>"
    exit 127
fi

VERSION=$1
USERNAME=$2
PORT=$3
INSTALLDIR=$4
DATADIR=$5

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
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
	mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace PG_MAJOR_VERSION $VERSION $1
    _replace PG_USERNAME $USERNAME $1
    _replace PG_PORT $PORT $1
    _replace PG_INSTALLDIR $INSTALLDIR $1
    _replace PG_DATADIR $DATADIR $1
}

# Create the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
	"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 $i
done

# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/launchbrowser.sh"
_fixup_file "$INSTALLDIR/scripts/launchpgadmin.sh"
_fixup_file "$INSTALLDIR/scripts/launchpsql.sh"
_fixup_file "$INSTALLDIR/scripts/launchsvrctl.sh"
_fixup_file "$INSTALLDIR/scripts/runpsql.sh"
_fixup_file "$INSTALLDIR/scripts/serverctl.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pg-postgresql.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-website.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-help.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-psql.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-reload.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-restart.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-start.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-stop.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-pgadmin.desktop"

# Create the menu shortcuts - first the top level, then the server menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system \
      "$INSTALLDIR/scripts/xdg/pg-postgresql.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-website.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-server.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-help.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-psql.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-reload.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-restart.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-start.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-stop.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-pgadmin.desktop" || _warn "Failed to create the server menu"

echo "$0 ran to completion"
exit 0
