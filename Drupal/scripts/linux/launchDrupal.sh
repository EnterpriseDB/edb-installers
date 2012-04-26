#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
INSTALLDIR="INSTALL_DIR"

URL=http://localhost:$PORT/Drupal

"$INSTALLDIR/Drupal/scripts/launchbrowser.sh" $URL

