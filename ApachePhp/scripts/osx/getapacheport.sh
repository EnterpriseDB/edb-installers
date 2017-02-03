#!/bin/bash
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`

# Trim the Port value
PORT="${PORT#"${PORT%%[![:space:]]*}"}"
PORT="${PORT%"${PORT##[![:space:]]*}"}"

URL=http://localhost:$PORT
echo $URL
