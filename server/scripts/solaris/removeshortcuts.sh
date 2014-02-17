#!/bin/bash
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server shortcut removal script for Linux

# Check the command line
if [ $# -ne 3 ]; 
then
    echo "Usage: $0 <Install dir> <Version> <Branding>"
    exit 127
fi

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
        mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

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
    DOC_BRANDING_STR="documentation-$VERSION_STR"
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
    DOC_BRANDING_STR=$BRANDING_STR"_documentation"
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
          "$INSTALLDIR/scripts/xdg/pg-doc-installationnotes-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-postgresql-releasenotes-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pgadmin-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-$VERSION_STR.desktop" \
          "$INSTALLDIR/scripts/xdg/pg-doc-pljava-readme-$VERSION_STR.desktop" || _warn "Failed to remove the documentation menu"

"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
	  "$INSTALLDIR/scripts/xdg/pg-psql-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pg-reload-$VERSION_STR.desktop" \
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
    rm "$INSTALLDIR/scripts/xdg/pg-$DOC_BRANDING_STR.directory"
fi

xdg_dir_name=menus

xdg_system_dirs="$XDG_CONFIG_DIRS"
[ -n "$xdg_system_dirs" ] || xdg_system_dirs=/etc/xdg
xdg_global_dir=
for x in `echo $xdg_system_dirs | sed 's/:/ /g'` ; do
   if [ -w $x/$xdg_dir_name ] ; then
       xdg_global_dir="$x/$xdg_dir_name"
       break
   fi
done
xdg_global_dir="$xdg_global_dir/applications-merged"

# Hack up the XDG menu files to make sure everything really does go.
_replace "<Filename>pg-psql-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR.menu"
_replace "<Filename>pg-reload-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR.menu"
_replace "<Filename>pg-pgadmin-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR.menu"
_replace "<Filename>pg-stackbuilder-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR.menu"

_replace "<Filename>pg-doc-installationnotes-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-$DOC_BRANDING_STR.menu"
_replace "<Filename>pg-doc-postgresql-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-$DOC_BRANDING_STR.menu"
_replace "<Filename>pg-doc-postgresql-releasenotes-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-$DOC_BRANDING_STR.menu"
_replace "<Filename>pg-doc-pgadmin-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-$DOC_BRANDING_STR.menu"
_replace "<Filename>pg-doc-pljava-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-$DOC_BRANDING_STR.menu"
_replace "<Filename>pg-doc-pljava-readme-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-$DOC_BRANDING_STR.menu"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0
