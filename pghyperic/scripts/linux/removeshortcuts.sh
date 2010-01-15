#!/bin/sh

# Hyperic server shortcut removal script for Linux
# Dave Page, EnterpriseDB

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

# Branding string, for the xdg filenames. If the branding is 'hyperic X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xhyperic $VERSION" ];
then
    BRANDING_STR="hyperic-$VERSION_STR"
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
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

"$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
	"$INSTALLDIR/scripts/xdg/pghyperic-$VERSION_STR.directory" \
	"$INSTALLDIR/scripts/xdg/pghyperic-launch-$VERSION_STR.desktop"\
	"$INSTALLDIR/scripts/xdg/pghyperic-start-$VERSION_STR.desktop"\
	"$INSTALLDIR/scripts/xdg/pghyperic-stop-$VERSION_STR.desktop" \
	"$INSTALLDIR/scripts/xdg/pghyperic-agent-start-$VERSION_STR.desktop"\
	"$INSTALLDIR/scripts/xdg/pghyperic-agent-stop-$VERSION_STR.desktop" || _warn "Failed to remove the top level menu"

# Remove the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
	"$INSTALLDIR/installer/xdg/xdg-icon-resource" uninstall --mode system --size 32 $i
done

# Only remove the directory file if it's branded
if [ $BRANDED -ne 0 ];
then
    rm "$INSTALLDIR/scripts/xdg/pghyperic-$BRANDING_STR.directory"
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
_replace "<Filename>pghyperic-launch-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pghyperic-$BRANDING_STR.menu"
_replace "<Filename>pghyperic-start-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pghyperic-$BRANDING_STR.menu"
_replace "<Filename>pghyperic-stop-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pghyperic-$BRANDING_STR.menu"
_replace "<Filename>pghyperic-agent-start-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pghyperic-$BRANDING_STR.menu"
_replace "<Filename>pghyperic-agent-stop-$VERSION_STR.desktop</Filename>" "" "$xdg_global_dir/pghyperic-$BRANDING_STR.menu"

echo "$0 ran to completion"
exit 0
