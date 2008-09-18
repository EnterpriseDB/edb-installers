#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
INSTALLDIR="INSTALL_DIR"

URL=http://localhost:$PORT/phpBB

"$INSTALLDIR/phpBB/scripts/launchbrowser.sh" $URL

