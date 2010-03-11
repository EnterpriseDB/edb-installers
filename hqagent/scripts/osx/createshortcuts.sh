#!/bin/sh

# Postgres Plus HQ Agent shortcut creation script for OSX
# Ashesh Vashi, EnterpriseDB

# Check the command line
if [ $# -ne 5 ];
then
    echo "Usage: $0 <Product Version> <Branding> <Install dir> <java_home> <serviceuser>"
    exit 127
fi

VERSION=$1
BRANDING=$2
INSTALLDIR=$3
JAVAHOME=$4
SERVICEUSER=$5

# Exit code
WARN=0

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

# Fixup the scripts
_fixup_file() {
  _replace @@PPHQVERSION@@      "$VERSION"       $1
  _replace @@INSTALLDIR@@       "$INSTALLDIR"    $1
  _replace @@BRANDING@@         "$BRANDING"      $1
  _replace @@JAVAHOME@@         "$JAVAHOME"      $1
  _replace @@AGENTSERVICEUSER@@ "${SERVICEUSER}" $1
}

_fixup_file "$INSTALLDIR/scripts/agentctl.sh"

# Compile a script - _compile_script($in.applescript, $out.app, $image)
_compile_script() {
    _fixup_file "$1"
    osacompile -x -o "$2" "$1" || _die "Failed to compile the script ($1)"
    cp "$3" "$2/Contents/Resources/applet.icns"
}

chmod ugo+x "$INSTALLDIR/scripts/"*.sh

# Create the menu 
FOLDER="/Applications/$BRANDING"
mkdir -p "$FOLDER" || _die "Failed to create the menu directory ($FOLDER)"

# Create the scripts
_compile_script "$INSTALLDIR/scripts/agent-start.applescript" "$FOLDER/Start Postgres Plus HQ Agent.app" "$INSTALLDIR/scripts/images/pphq-agent-start.icns"
_compile_script "$INSTALLDIR/scripts/agent-stop.applescript" "$FOLDER/Stop Postgres Plus HQ Agent.app" "$INSTALLDIR/scripts/images/pphq-agent-stop.icns"

echo "$0 ran to completion"
exit 0
