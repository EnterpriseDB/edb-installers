#!/bin/bash
# Copyright (c) 2012-2018, EnterpriseDB Corporation.  All rights reserved

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
URL=http://localhost:$PORT/phpPgAdmin
echo $URL
