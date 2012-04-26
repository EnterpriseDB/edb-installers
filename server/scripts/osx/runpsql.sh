#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL psql runner script for OS X

# Check the command line
if [ $# -ne 0 -a $# -ne 1 ]; 
then
    echo "Usage: $0 [wait]"
    exit 127
fi

echo -n "Server [localhost]: "
read SERVER

if [ "$SERVER" = "" ];
then
    SERVER="localhost"
fi

echo -n "Database [postgres]: "
read DATABASE

if [ "$DATABASE" = "" ];
then
    DATABASE="postgres"
fi

echo -n "Port [PG_PORT]: "
read PORT

if [ "$PORT" = "" ];
then
    PORT="PG_PORT"
fi

echo -n "Username [PG_USERNAME]: "
read USERNAME

if [ "$USERNAME" = "" ];
then
    USERNAME="PG_USERNAME"
fi

"PG_INSTALLDIR/bin/psql" -h $SERVER -p $PORT -U $USERNAME $DATABASE
RET=$?

if [ "$RET" != "0" ];
then
    echo
    echo -n "Press <return> to continue..."
    read dummy
fi

exit $RET