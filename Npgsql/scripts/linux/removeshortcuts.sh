#!/bin/sh
# Copyright (c) 2012-2018, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 2 ];
then
    echo "Usage: $0 <Install dir> <Branding>"
    exit 127
fi

INSTALLDIR=$1
BRANDING=$2
TEMPFILE=`mktemp -q /tmp/$$.tmp-XXXXXXXXXX`

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgreSQL" ];
then
    BRANDING_STR="postgresql"
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
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
    "$INSTALLDIR/scripts/xdg/pg-npgsql.directory" \
    "$INSTALLDIR/scripts/xdg/pg-launchDocsAPI.desktop" \
    "$INSTALLDIR/scripts/xdg/pg-launchUserManual.desktop" || _warn "Failed to remove the Npgsql menu"

      
# Remove the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/pg-npgsql.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/pg-launchDocsAPI.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 "$INSTALLDIR/scripts/images/pg-launchUserManual.png"

# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
    rm "$INSTALLDIR/scripts/xdg/pg-npgsql.directory" 
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
_replace "<Filename>pg-launchDocsAPI.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-npgsql.menu"
_replace "<Filename>pg-launchUserManual.desktop</Filename>" "" "$xdg_global_dir/pg-$BRANDING_STR-pg-npgsql.menu"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0

