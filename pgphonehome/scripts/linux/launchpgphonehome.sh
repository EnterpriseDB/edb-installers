#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
INSTALLDIR="INSTALL_DIR"

URL=http://localhost:$PORT/pgph

"$INSTALLDIR/pgph/scripts/launchbrowser.sh" $URL

