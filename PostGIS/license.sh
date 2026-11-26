#!/bin/bash
#
# Generate postgis_3rd_party_licenses.txt in the staging directory ($STAGE).
# Reuses generate_3rd_party_license() from ../server/license.sh. Run from
# packaging-config/PostGIS; deliberately not run with -e/pipefail, as the
# function's pipelines fail under them.

WD="$(dirname "$PWD")"
_die() { echo "$@"; exit 1; }

eval "$(sed -n '/^generate_3rd_party_license()/,/^}/p' "$WD/server/license.sh")"
chmod +x "$WD"/list-*.sh "$WD"/list_*.sh 2>/dev/null

cd "$STAGE" || _die "Staging directory $STAGE not found"
generate_3rd_party_license "postgis"

[ -s "$STAGE/postgis_3rd_party_licenses.txt" ] || _die "ERROR: license file not generated"
