#!/bin/sh

# Hyperic server shortcut creation script for OSX
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 3 ];
then
    echo "Usage: $0 <Product Version> <Branding> <Install dir>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3

# Exit code
WARN=0

# Working directory
WD=`pwd`

# Version string, for the xdg filenames
VERSION_STR=`echo $VERSION | sed 's/\./_/g'`

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
	mv /tmp/$$.tmp $3 || return 1
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace PGHYPERIC_VERSION_STR $VERSION_STR $1
    _replace PGHYPERIC_INSTALLDIR "$INSTALLDIR" $1
    _replace PGHYPERIC_BRANDING "$BRANDING" $1
}

# We need to remove any old shortcuts created by the Beta/RC installers, as they 
# used a version numbering scheme that could confuse XDG

if [ "x$VERSION_STR" = "x$VERSION" ];
then
    VERSION=""
    pghyperic=1
fi

if [ -f "$INSTALLDIR/scripts/xdg/pg-hyperic-$VERSION.directory" ];
then
   # Remove the menu shortcuts
   "$INSTALLDIR/installer/xdg/xdg-desktop-menu" uninstall --mode system \
          "$INSTALLDIR/scripts/xdg/pghyperic-$VERSION.directory" \
          "$INSTALLDIR/scripts/xdg/pghyperic-launch-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pghyperic-start-$VERSION.desktop" \
          "$INSTALLDIR/scripts/xdg/pghyperic-stop-$VERSION.desktop" 

    rm "$INSTALLDIR/scripts/xdg/"pghyperic*-$VERSION.directory
    rm "$INSTALLDIR/scripts/xdg/"pghyperic*-$VERSION.desktop
fi

if [ "x$pghyperic" = "x1" ];
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
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pghyperic-$VERSION.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pghyperic-launch-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pghyperic-start-$VERSION.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pghyperic-stop-$VERSION.desktop"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/scripts/xdg/pghyperic-$VERSION_STR.directory" "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
fi

# Create the menu shortcuts - first the top level menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
      "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
	  "$INSTALLDIR/scripts/xdg/pghyperic-launch-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pghyperic-start-$VERSION_STR.desktop" \
	  "$INSTALLDIR/scripts/xdg/pghyperic-stop-$VERSION_STR.desktop" || _warn "Failed to create the top level menu Hyperic"

echo "$0 ran to completion"
exit 0
