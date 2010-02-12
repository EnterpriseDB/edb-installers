#!/bin/sh

# Postgres Plus HQ server shortcut creation script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 4 ];
then
    echo "Usage: $0 <Product Version> <Branding> <Install dir> <Port>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3
PORT=$4

# Exit code
WARN=0

# Working directory
WD=`pwd`

# Version string, for the xdg filenames
VERSION_STR=`echo $VERSION | sed 's/\./_/g'`

# Branding string, for the xdg filenames. If the branding is 'Postgres Plus HQ X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgres Plus HQ $VERSION" ];
then
    BRANDING_STR="Postgres Plus HQ-$VERSION_STR"
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
    _replace PPHQ_VERSION_STR $VERSION_STR $1
    _replace PPHQ_INSTALLDIR "$INSTALLDIR" $1
    _replace PPHQ_BRANDING "$BRANDING" $1
    _replace PPHQ_PORT "$PORT" $1
}


# Create the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
  "$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 $i
done

# Fixup the scripts
# Fixup the scripts
_fixup_file "$INSTALLDIR/scripts/launchbrowser.sh"
_fixup_file "$INSTALLDIR/scripts/launchsvrctl.sh"
_fixup_file "$INSTALLDIR/scripts/serverctl.sh"
_fixup_file "$INSTALLDIR/scripts/launchagentctl.sh"
_fixup_file "$INSTALLDIR/scripts/agentctl.sh"
# In case of serverctl.sh and agentctl.sh: We do not want to change PPHQ_VERSION_STR to X_Y_Z from X.Y.Z because path is server-4.2.0 not server-4_2_0. But we want to replace PPHQ_INSTALLDIR. So revert back one  change done by fix_up function.
_replace $VERSION_STR $VERSION "$INSTALLDIR/scripts/serverctl.sh"
_replace $VERSION_STR $VERSION "$INSTALLDIR/scripts/agentctl.sh"
chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-$VERSION_STR.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-launch-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-start-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-stop-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-agent-start-$VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-agent-stop-$VERSION_STR.desktop"

# Create the menu shortcuts - first the top level menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
      "$INSTALLDIR/scripts/xdg/pphq-launch-$VERSION_STR.desktop" \
      "$INSTALLDIR/scripts/xdg/pphq-start-$VERSION_STR.desktop" \
      "$INSTALLDIR/scripts/xdg/pphq-stop-$VERSION_STR.desktop" \
      "$INSTALLDIR/scripts/xdg/pphq-agent-start-$VERSION_STR.desktop" \
      "$INSTALLDIR/scripts/xdg/pphq-agent-stop-$VERSION_STR.desktop" || _warn "Failed to create the top level menu PPHQ"

echo "$0 ran to completion"
exit 0
