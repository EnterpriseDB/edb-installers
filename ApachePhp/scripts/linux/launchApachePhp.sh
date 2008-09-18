#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`

URL=http://localhost:$PORT

INSTALLDIR="INSTALL_DIR"

"$INSTALLDIR/scripts/launchbrowser.sh" $URL

