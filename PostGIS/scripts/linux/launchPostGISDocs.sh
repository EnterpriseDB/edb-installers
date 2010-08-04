#!/bin/bash

INSTALLDIR="INSTALL_DIR"
DOCDIR="DOC_DIR"
URL="file://$DOCDIR/postgis/postgis.html"
chmod 755 $DOCDIR/postgis/postgis.html

"$INSTALLDIR/PostGIS/scripts/launchbrowser.sh" $URL

