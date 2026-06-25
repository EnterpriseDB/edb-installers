#!/bin/sh
# Copyright (c) 2012-2026, EnterpriseDB Corporation.  All rights reserved
#
# Point the bundled plperl / pltcl interpreters at their support files by adding
# PERL5LIB / TCL_LIBRARY to the postgres launchd service's environment.
#
# The bundled perl/tcl have their @INC / TCL_LIBRARY baked to the build prefix
# (a shared libperl can't be built relocatable), so at runtime the embedded
# interpreters can't find strict.pm / init.tcl. The modules + scripts are
# shipped under <installdir>/lib; this exports the right paths so the service's
# postgres (and therefore plperl/pltcl) finds them.
#
# Run AFTER the service plist is created and BEFORE it is loaded.
# Usage: set-service-pl-env.sh <installdir> <servicename>

INSTALLDIR="$1"
SERVICENAME="$2"
PLIST="/Library/LaunchDaemons/${SERVICENAME}.plist"
PB=/usr/libexec/PlistBuddy

[ -f "$PLIST" ] || exit 0

# Perl: archlib is the dir that holds Config_heavy.pl; privlib is its parent.
CFGH=$(ls "$INSTALLDIR"/lib/[0-9]*.[0-9]*/*/Config_heavy.pl 2>/dev/null | head -1)
# Tcl: the script library dir (contains init.tcl).
TCLLIB=$(ls -d "$INSTALLDIR"/lib/tcl[0-9]* 2>/dev/null | head -1)

# Start from a clean EnvironmentVariables dict.
"$PB" -c "Delete :EnvironmentVariables" "$PLIST" 2>/dev/null
"$PB" -c "Add :EnvironmentVariables dict" "$PLIST" 2>/dev/null

if [ -n "$CFGH" ]; then
    ARCHLIB=$(dirname "$CFGH")
    PRIVLIB=$(dirname "$ARCHLIB")
    "$PB" -c "Add :EnvironmentVariables:PERL5LIB string ${ARCHLIB}:${PRIVLIB}" "$PLIST" 2>/dev/null
    echo "set PERL5LIB=${ARCHLIB}:${PRIVLIB} in ${PLIST}"
fi

if [ -n "$TCLLIB" ] && [ -d "$TCLLIB" ]; then
    "$PB" -c "Add :EnvironmentVariables:TCL_LIBRARY string ${TCLLIB}" "$PLIST" 2>/dev/null
    echo "set TCL_LIBRARY=${TCLLIB} in ${PLIST}"
fi

exit 0
