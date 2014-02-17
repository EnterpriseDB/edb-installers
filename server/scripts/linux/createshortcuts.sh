#!/bin/sh
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server shortcut creation script for Linux

# Check the command line
if [ $# -ne 10 ];
then
    echo "Usage: $0 <Major.Minor version> <OSUsername> <SuperUsername> <Port> <Branding> <Install dir> <Data dir> <DisableStackBuilder> <ServiceName> <Temp dir>"
    exit 127
fi

VERSION=$1
OSUSERNAME=$2
SUPERUSERNAME=$3
PORT=$4
BRANDING=$5
INSTALLDIR=$6
DATADIR=$7
DISABLE_STACKBUILDER=$8
SERVICENAME=$9
TEMPDIR=${10}

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

# Make sure correct value is passed for DISABLE_STACKBUILDER
DISABLE_STACKBUILDER=`echo $DISABLE_STACKBUILDER | tr '[A-Z]' '[a-z]'`
if [ "x$DISABLE_STACKBUILDER" = "x1" -o "x$DISABLE_STACKBUILDER" = "xtrue" -o "x$DISABLE_STACKBUILDER" = "xon" ];
then
    DISABLE_STACKBUILDER=1
else
    DISABLE_STACKBUILDER=0
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
    _replace PG_OSUSERNAME $OSUSERNAME $1
    _replace PG_USERNAME $SUPERUSERNAME $1
    _replace PG_PORT $PORT $1
    _replace PG_INSTALLDIR "$INSTALLDIR" $1
    _replace PG_DATADIR "$DATADIR" $1
    _replace PG_BRANDING "$BRANDING" $1
    _replace PG_SERVICENAME "$SERVICENAME" $1
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
   # Remove the menu shortcuts
   "$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system --noupdate \
          "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory" \
          "$INSTALLDIR/scripts/xdg/pg-documentation-$VERSION.directory" \
          "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION.desktop" 

   "$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
          "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION.directory" \
          "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-pgadmin-$VERSION.desktop"

    rm "$INSTALLDIR/scripts/xdg/"pg-*-$VERSION.directory
    rm "$INSTALLDIR/scripts/xdg/"pg-*-$VERSION.desktop
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
_fixup_file "$INSTALLDIR/scripts/launchbrowser.sh"
_fixup_file "$INSTALLDIR/scripts/launchpgadmin.sh"
_fixup_file "$INSTALLDIR/scripts/launchpsql.sh"
_fixup_file "$INSTALLDIR/scripts/launchstackbuilder.sh"
_fixup_file "$INSTALLDIR/scripts/runpsql.sh"
_fixup_file "$INSTALLDIR/scripts/runstackbuilder.sh"
_fixup_file "$INSTALLDIR/scripts/serverctl.sh"
_fixup_file "$INSTALLDIR/scripts/launchsvrctl.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION_STR.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-documentation-$VERSION_STR.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-pgadmin-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-stackbuilder-$VERSION_STR.desktop"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/scripts/xdg/pg-postgresql-$VERSION_STR.directory" "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
    cp "$INSTALLDIR/scripts/xdg/pg-documentation-$VERSION_STR.directory" "$INSTALLDIR/scripts/xdg/pg-$DOC_BRANDING_STR.directory"
fi

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
      "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
	  "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-pgadmin-$VERSION_STR.desktop" || _warn "Failed to create the top level menu"

# Do not create stack-builder menu, if DISABLE_STACKBUILDER is equal to 1
if [ $DISABLE_STACKBUILDER -eq 0 ];
then
    "$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
      "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
        "$INSTALLDIR/scripts/xdg/pg-stackbuilder-$VERSION_STR.desktop" || _warn "Failed to create the top level menu for stack-builder"
fi

"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system \
      "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
      "$INSTALLDIR/scripts/xdg/pg-$DOC_BRANDING_STR.directory" \
          "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION_STR.desktop" || _warn "Failed to create the documentation menu"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0
