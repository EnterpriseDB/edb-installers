#!/bin/sh

# hqagent shortcut creation script for Linux
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

# Branding string, for the xdg filenames. If the branding is 'hqagent X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xhqagent $VERSION" ];
then
    BRANDING_STR="hqagent-$VERSION_STR"
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

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || return 1 
	mv /tmp/$$.tmp $3 || return 1
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace HQAGENT_VERSION_STR $VERSION_STR $1
    _replace HQAGENT_INSTALLDIR "$INSTALLDIR" $1
    _replace HQAGENT_BRANDING "$BRANDING" $1
}


# Create the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
	"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 $i
done

# In case of agentctl.sh: We do not want to change HQAGENT_VERSION_STR to X_Y_Z from X.Y.Z because path is agent-4.2.0 not agent-4_2_0. But we want to replace HQAGENT_INSTALLDIR. So revert back one  change done by fix_up function.
_replace $VERSION_STR $VERSION "$INSTALLDIR/scripts/agentctl.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/hqagent.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/hqagent-start.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/hqagent-stop.desktop"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/scripts/xdg/hqagent.directory" "$INSTALLDIR/scripts/xdg/hq-$BRANDING_STR.directory"
fi

# Create the menu shortcuts - first the top level menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
      "$INSTALLDIR/scripts/xdg/hq-$BRANDING_STR.directory" \
	  "$INSTALLDIR/scripts/xdg/hqagent-start.desktop" \
	  "$INSTALLDIR/scripts/xdg/hqagent-stop.desktop" || _warn "Failed to create the top level menu for Postgres Plus HQ agent"

echo "$0 ran to completion"
exit 0
