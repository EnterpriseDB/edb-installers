#!/bin/bash
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

PORT=`grep APACHE_HPORT /etc/postgres-reg.ini | cut -f 2 -d "="`

# Trim the Port value
PORT="${PORT#"${PORT%%[![:space:]]*}"}"
PORT="${PORT%"${PORT##[![:space:]]*}"}"

URL=http://localhost:$PORT
echo $URL
