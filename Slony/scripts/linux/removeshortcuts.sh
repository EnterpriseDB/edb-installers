#!/bin/sh
# Copyright (c) 2012-2021, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 4 ];
then
    echo "Usage: $0 <Install dir> <Slony_Version> <PG Version> <Branding>"
    exit 127
fi

INSTALLDIR="$1"
SLONY_VERSION=$2
PG_VERSION=$3
BRANDING=$4
TEMPFILE=`mktemp -q /tmp/$$.tmp-XXXXXXXXXX`

# Version string, for the xdg filenames
SLONY_VERSION_STR=`echo $SLONY_VERSION | cut -f1,2 -d "." | sed 's/\./_/g'`
PG_VERSION_STR=`echo $PG_VERSION | sed 's/\./_/g'`

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgreSQL $PG_VERSION" ];
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

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "$TEMPFILE" || _die "Failed for search and replace '$1' with '$2' in $3"
        mv $TEMPFILE $3 || _die "Failed to move $TEMPFILE to $3"
	chmod 644 $3
}

# Remove the menu shortcuts
"$INSTALLDIR/Slony/installer/xdg/xdg-desktop-menu" uninstall --mode system   \
    "$INSTALLDIR/Slony/scripts/xdg/pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop" || _warn "Failed to remove the Slony docs menu item"
      
# Remove the icon resources
"$INSTALLDIR/Slony/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/Slony/scripts/images/launch-SlonyDocs.png"

# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/Slony/scripts/xdg/pg-$BRANDING_STR.directory"
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
_replace "<Filename>pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR.menu"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0

