#!/bin/sh
# Add TCL_LIBRARY to the postgres launchd plist so pltcl finds the bundled
# init.tcl (the prebuilt Tcl's baked library path does not exist on the target).
# createOSXService already started the service, and launchd only reads
# EnvironmentVariables at load time, so we reload it after setting the var.
# Usage: set-service-tcl-env.sh <installdir> <servicename>

INSTALLDIR="$1"
SERVICENAME="$2"
PLIST="/Library/LaunchDaemons/${SERVICENAME}.plist"
PB=/usr/libexec/PlistBuddy

[ -f "$PLIST" ] || exit 0
# The script library is the dir holding init.tcl (lib/tcl8.6), not lib/tcl8.
INIT=$(ls "$INSTALLDIR"/lib/tcl[0-9]*/init.tcl 2>/dev/null | head -1)
[ -n "$INIT" ] || exit 0
TCLLIB=$(dirname "$INIT")

"$PB" -c "Add :EnvironmentVariables dict" "$PLIST" 2>/dev/null
"$PB" -c "Add :EnvironmentVariables:TCL_LIBRARY string ${TCLLIB}" "$PLIST" 2>/dev/null \
  || "$PB" -c "Set :EnvironmentVariables:TCL_LIBRARY ${TCLLIB}" "$PLIST"
echo "set TCL_LIBRARY=${TCLLIB} in ${PLIST}"

# Reload so the running postgres picks up TCL_LIBRARY (launchd reads env only at
# load time; createOSXService already started it without the var).
launchctl bootout system "$PLIST" 2>/dev/null || launchctl unload "$PLIST" 2>/dev/null
launchctl bootstrap system "$PLIST" 2>/dev/null || launchctl load "$PLIST" 2>/dev/null
exit 0
