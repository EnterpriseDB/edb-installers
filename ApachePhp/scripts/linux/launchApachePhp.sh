#!/bin/bash
# Copyright (c) 2012-2013, EnterpriseDB Corporation.  All rights reserved

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`

# Trim the Port value
PORT="${PORT#"${PORT%%[![:space:]]*}"}"
PORT="${PORT%"${PORT##[![:space:]]*}"}"

URL=http://localhost:$PORT

INSTALLDIR="INSTALL_DIR"

"$INSTALLDIR/scripts/launchbrowser.sh" $URL

