#!/bin/sh

# PostgreSQL server startup script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Major.Minor version>"
    exit 127
fi

VERSION=$1

# Start the server
/etc/init.d/postgresql-$VERSION start
if [ $? -ne 0 ];
then
    echo "Failed to start the database server."
    exit 1
fi

echo "$0 ran to completion"
exit 0
