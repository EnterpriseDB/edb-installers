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
_fixup_file "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-documentation-$VERSION.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-restart-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-start-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-stop-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-pgadmin-$VERSION.desktop"

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
      "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-restart-$VERSION.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-start-$VERSION.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-stop-$VERSION.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-pgadmin-$VERSION.desktop" || _warn "Failed to create the top level menu"

"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system \
      "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory" \
      "$INSTALLDIR/scripts/xdg/pg-documentation-$VERSION.directory" \
          "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION.desktop" || _warn "Failed to create the documentation menu"

# Not entirely relevant to this script, but pre-cofigure pgAdmin while we're here
# Pre-register the server with pgAdmin, if the user doesn't already have a pgAdmin preferences file
PGADMIN_CONF=$HOME/.pgadmin3
if [ ! -e "$PGADMIN_CONF" ];
then
cat <<EOT > "$PGADMIN_CONF"
PostgreSQLPath=$INSTALLDIR/bin
PostgreSQLHelpPath=file://$INSTALLDIR/doc/postgresql/html
[Servers]
Count=1
[Servers/1]
Server=localhost
Description=PostgreSQL $VERSION
Port=$PORT
Database=postgres
Username=postgres
EOT
fi

echo "$0 ran to completion"
exit 0
