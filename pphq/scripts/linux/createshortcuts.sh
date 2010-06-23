#!/bin/sh

# Postgres Plus HQ server shortcut creation script for Linux
# Ashesh Vashi, EnterpriseDB

# Check the command line
if [ $# -ne 7 ];
then
    echo "Usage: $0 <Product Version> <Branding> <Install dir> <Port> <java_home> <serviceuser> <agentserviceuser>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3
PORT=$4
JAVAHOME=$5
SERVERSERVICEUSER=$6
AGENTSERVICEUSER=$7

# Exit code
WARN=0

BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`

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
  _replace @@PPHQVERSION@@ "$VERSION"               $1
  _replace @@INSTALLDIR@@  "$INSTALLDIR"            $1
  _replace @@BRANDING@@    "$BRANDING"              $1
  _replace @@JAVAHOME@@    "$JAVAHOME"              $1
  _replace @@PPHQPORT@@    "$PORT"                  $1
  _replace @@PORT@@        "$PORT"                  $1
  _replace @@SERVICEUSER@@ "$SERVERSERVICEUSER"     $1
  _replace @@AGENTSERVICEUSER@@ "$AGENTSERVICEUSER" $1
}

_fixup_file "$INSTALLDIR/scripts/agentctl.sh"
_fixup_file "$INSTALLDIR/scripts/serverctl.sh"
_fixup_file "$INSTALLDIR/scripts/launchagentctl.sh"
_fixup_file "$INSTALLDIR/scripts/launchsvrctl.sh"
_fixup_file "$INSTALLDIR/scripts/runAgent.sh"
_fixup_file "$INSTALLDIR/scripts/runServer.sh"
_fixup_file "$INSTALLDIR/scripts/launchbrowser.sh"

# Create the icon resources
cd "$INSTALLDIR/scripts/images"
for i in `ls *.png`
do
    "$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 $i
done

chmod ugo+x "$INSTALLDIR/scripts/"*.sh

_fixup_file "$INSTALLDIR/scripts/xdg/pphq-pphq.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-agent-start.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-agent-stop.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-launch.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-start.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pphq-stop.desktop"

mv "$INSTALLDIR/scripts/xdg/pphq-pphq.directory" "$INSTALLDIR/scripts/xdg/pphq-$BRANDING_STR.directory"

# Create the menu shortcuts - first the top level menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system --noupdate \
    "$INSTALLDIR/scripts/xdg/pphq-$BRANDING_STR.directory" \
        "$INSTALLDIR/scripts/xdg/pphq-launch.desktop" \
        "$INSTALLDIR/scripts/xdg/pphq-start.desktop" \
        "$INSTALLDIR/scripts/xdg/pphq-stop.desktop" \
        "$INSTALLDIR/scripts/xdg/pphq-agent-start.desktop" \
        "$INSTALLDIR/scripts/xdg/pphq-agent-stop.desktop" || _warn "Failed to create the top level menu PPHQ"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0
