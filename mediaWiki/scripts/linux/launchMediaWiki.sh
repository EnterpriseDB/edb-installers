#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
INSTALLDIR="INSTALL_DIR"

URL=http://localhost:$PORT/mediaWiki

"$INSTALLDIR/mediaWiki/scripts/launchbrowser.sh" $URL

