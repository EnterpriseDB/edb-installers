#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
INSTALLDIR="INSTALL_DIR"

URL=http://localhost:$PORT/Drupal7

"$INSTALLDIR/Drupal7/scripts/launchbrowser.sh" $URL

